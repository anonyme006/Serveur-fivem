--[[--------------------------------------------------------------------------
    core_garage — fourrière
---------------------------------------------------------------------------]]

local function sendToImpound(plate, reason, fee, minutes, impoundGarage)
    plate = GarageUtils.NormalizePlate(plate)
    local row = MySQL.single.await('SELECT * FROM garage_vehicles WHERE plate = ?', { plate })
    if not row then return false end

    fee = tonumber(fee) or Config.Impound.defaultPrice
    minutes = tonumber(minutes) or Config.Impound.defaultTimeMinutes
    impoundGarage = impoundGarage or 'impound_public'

    local availableAt
    if minutes > 0 then
        availableAt = MySQL.scalar.await('SELECT DATE_ADD(NOW(), INTERVAL ? MINUTE)', { minutes })
    else
        availableAt = MySQL.scalar.await('SELECT NOW()')
    end

    MySQL.update.await([[
        UPDATE garage_vehicles
        SET stored = 0, impound = 1, impound_id = ?, impound_fee = ?,
            impound_until = ?, net_id = NULL, garage = ?
        WHERE plate = ?
    ]], { impoundGarage, fee, availableAt, impoundGarage, plate })

    MySQL.insert.await([[
        INSERT INTO impound (plate, owner, vehicle, impound_garage, reason, fee, available_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        plate, row.owner, row.vehicle, impoundGarage, reason or 'destroyed', fee, availableAt
    })

    GarageDB.SyncOwnedVehicle(plate, {
        stored = false,
        garage = impoundGarage,
        impound = true,
        impoundId = impoundGarage,
        vehicle = row.vehicle,
    })

    GarageSecurity.UnlockPlate(plate)

    if Config.Impound.notifyOwner then
        local xPlayers = ESX.GetExtendedPlayers and ESX.GetExtendedPlayers() or nil
        if xPlayers then
            for _, xPlayer in pairs(xPlayers) do
                if xPlayer.getIdentifier() == row.owner then
                    GarageNotify(xPlayer.source, _('impound_destroyed', plate), 'error')
                    break
                end
            end
        else
            for _, src in ipairs(ESX.GetPlayers()) do
                local xp = ESX.GetPlayerFromId(src)
                if xp and xp.getIdentifier() == row.owner then
                    GarageNotify(src, _('impound_destroyed', plate), 'error')
                    break
                end
            end
        end
    end

    GarageLog('impound', {
        plate = plate,
        owner = row.owner,
        identifier = row.owner,
        garage = impoundGarage,
        details = { reason = reason, fee = fee },
    })

    return true
end

lib.callback.register('core_garage:retrieveImpound', function(source, data)
    if type(data) ~= 'table' then return { ok = false, error = 'error' } end
    if not GarageSecurity.RateOk(source) then return { ok = false, error = 'anti_dupe' } end

    local plate = GarageUtils.NormalizePlate(data.plate)
    local garageName = data.garage
    local garage = GarageDB.GetGarage(garageName)
    if not garage or garage.type ~= 'impound' then
        return { ok = false, error = 'error' }
    end

    local access, err = GarageSecurity.CanAccessGarage(source, garage)
    if not access then return { ok = false, error = err } end

    if not GarageSecurity.IsNear(source, garage.coords, Config.General.maxDistance + 5.0) then
        return { ok = false, error = 'too_far' }
    end

    local row = MySQL.single.await('SELECT * FROM garage_vehicles WHERE plate = ? AND impound = 1', { plate })
    if not row then return { ok = false, error = 'vehicle_not_found' } end

    local identifier = GarageGetIdentifier(source)
    if row.owner ~= identifier then
        return { ok = false, error = 'vehicle_not_yours' }
    end

    -- Délai
    if row.impound_until then
        local ready = MySQL.scalar.await('SELECT CASE WHEN NOW() >= ? THEN 1 ELSE 0 END', { row.impound_until })
        if ready ~= 1 then
            local remaining = MySQL.scalar.await(
                'SELECT TIMEDIFF(?, NOW())',
                { row.impound_until }
            )
            return { ok = false, error = 'impound_wait', errorArg = tostring(remaining or '?') }
        end
    end

    local fee = tonumber(row.impound_fee) or garage.impound_price or Config.Impound.defaultPrice
    if row.insured == 1 or row.insured == true then
        fee = math.floor(fee * (1.0 - (Config.Impound.insuranceDiscount or 0) / 100.0))
    end

    if not GaragePay(source, fee) then
        return { ok = false, error = 'not_enough_money' }
    end

    -- Vérifie spawn
    local spawn = garage.spawn
    local vehicles = GetAllVehicles()
    local spawnVec = GarageUtils.ToVec3(spawn)
    for i = 1, #vehicles do
        local veh = vehicles[i]
        if DoesEntityExist(veh) and spawnVec and #(GetEntityCoords(veh) - spawnVec) < 2.8 then
            return { ok = false, error = 'spawn_blocked' }
        end
    end

    if GarageSecurity.IsLocked(plate) then
        return { ok = false, error = 'vehicle_already_out' }
    end

    GarageSecurity.LockPlate(plate, source, nil)

    local props = GarageUtils.Decode(row.vehicle)
    props.plate = plate
    props.engineHealth = math.max(200.0, tonumber(row.engine) or 400.0)
    props.bodyHealth = math.max(200.0, tonumber(row.body) or 400.0)
    props.fuelLevel = tonumber(row.fuel) or 50.0

    MySQL.update.await([[
        UPDATE garage_vehicles
        SET impound = 0, impound_id = NULL, impound_fee = 0, impound_until = NULL,
            stored = 0, last_out = NOW(), garage = ?
        WHERE plate = ?
    ]], { garageName, plate })

    MySQL.update.await('UPDATE impound SET released = 1 WHERE plate = ? AND released = 0', { plate })

    GarageDB.SyncOwnedVehicle(plate, {
        stored = false,
        garage = garageName,
        impound = false,
        vehicle = props,
    })

    GarageLog('retrieve', {
        plate = plate,
        owner = row.owner,
        identifier = identifier,
        garage = garageName,
        details = { fee = fee },
    })

    return {
        ok = true,
        props = props,
        spawn = spawn,
        heading = spawn.w or garage.heading or 0.0,
        plate = plate,
        fee = fee,
        mileage = tonumber(row.mileage) or 0.0,
        giveKeys = Config.General.giveKeys,
    }
end)

--- Client signale véhicule détruit
RegisterNetEvent('core_garage:server:vehicleDestroyed', function(plate, netId)
    local src = source
    if not Config.General.autoImpoundOnDestroy then return end
    plate = GarageUtils.NormalizePlate(plate)
    if plate == '' then return end

    local row = MySQL.single.await('SELECT owner, company, impound, stored FROM garage_vehicles WHERE plate = ?', { plate })
    if not row or row.impound == 1 then return end
    if not GarageSecurity.IsOwnerOrCompany(src, row.owner, row.company) then return end

    -- Valide netId si fourni
    if netId then
        local entity = NetworkGetEntityFromNetworkId(tonumber(netId) or -1)
        if entity and entity ~= 0 and DoesEntityExist(entity) then
            local health = GetVehicleEngineHealth(entity)
            if health > (Config.General.destroyHealthThreshold or 50.0) then
                return
            end
            DeleteEntity(entity)
        end
    end

    local fee = Config.Impound.defaultPrice
    local minutes = Config.Impound.defaultTimeMinutes
    sendToImpound(plate, 'destroyed', fee, minutes, 'impound_public')
end)

exports('ImpoundVehicle', function(plate, reason, fee, minutes, impoundGarage)
    return sendToImpound(plate, reason, fee, minutes, impoundGarage)
end)

-- Au reboot : véhicules sortis (sans entity) → fourrière optionnelle via config externe
-- Ici on laisse stored=0 ; la fourrière manuelle / destroy gère le reste.
