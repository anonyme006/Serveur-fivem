--[[--------------------------------------------------------------------------
    core_garage — sortie véhicule (spawn sécurisé)
---------------------------------------------------------------------------]]

local spawning = {} -- source → true

local function isSpawnClear(coords, radius)
    coords = GarageUtils.ToVec3(coords)
    if not coords then return false end
    radius = radius or 3.0
    local vehicles = GetAllVehicles()
    for i = 1, #vehicles do
        local veh = vehicles[i]
        if DoesEntityExist(veh) then
            local vc = GetEntityCoords(veh)
            if #(vc - coords) < radius then
                return false
            end
        end
    end
    return true
end

local function applyPropsServer(vehicle, props)
    -- Props appliqués côté client après spawn OneSync
    Entity(vehicle).state:set('garageProps', props, true)
end

lib.callback.register('core_garage:takeOut', function(source, data)
    if type(data) ~= 'table' then return { ok = false, error = 'error' } end
    if not GarageSecurity.RateOk(source) then return { ok = false, error = 'anti_dupe' } end
    if spawning[source] then return { ok = false, error = 'anti_dupe' } end

    local plate = GarageUtils.NormalizePlate(data.plate)
    local garageName = data.garage
    if plate == '' or not garageName then return { ok = false, error = 'error' } end

    local garage = GarageDB.GetGarage(garageName)
    if not garage then return { ok = false, error = 'error' } end

    local access, err = GarageSecurity.CanAccessGarage(source, garage)
    if not access then return { ok = false, error = err } end

    if not GarageSecurity.IsNear(source, garage.coords, Config.General.maxDistance + 5.0) then
        return { ok = false, error = 'too_far' }
    end

    if GarageSecurity.IsLocked(plate) then
        return { ok = false, error = 'vehicle_already_out' }
    end

    local row = MySQL.single.await('SELECT * FROM garage_vehicles WHERE plate = ?', { plate })
    if not row then return { ok = false, error = 'vehicle_not_found' } end

    local identifier = GarageGetIdentifier(source)
    if not GarageSecurity.IsOwnerOrCompany(source, row.owner, row.company) then
        return { ok = false, error = 'vehicle_not_yours' }
    end

    -- Fourrière : géré par callback dédié
    if garage.type == 'impound' or row.impound == 1 then
        return { ok = false, error = 'vehicle_not_found' }
    end

    if row.stored ~= 1 and row.stored ~= true then
        return { ok = false, error = 'vehicle_already_out' }
    end

    -- Limite entreprise
    if row.company and row.company ~= '' then
        local company = GarageDB.companies[row.company] and GarageDB.companies[row.company][garageName]
        if company then
            local xPlayer = ESX.GetPlayerFromId(source)
            local grade = xPlayer and xPlayer.getJob().grade or 0
            if grade < (company.min_grade_out or 0) then
                return { ok = false, error = 'garage_grade_required' }
            end
            local outCount = MySQL.scalar.await(
                'SELECT COUNT(*) FROM garage_vehicles WHERE company = ? AND stored = 0 AND impound = 0',
                { row.company }
            ) or 0
            if outCount >= (company.max_out or 5) then
                return { ok = false, error = 'company_max_out', errorArg = company.max_out }
            end
        end
    end

    local spawn = garage.spawn
    if not isSpawnClear(spawn, 2.8) then
        return { ok = false, error = 'spawn_blocked' }
    end

    spawning[source] = true
    GarageSecurity.LockPlate(plate, source, nil)

    local props = GarageUtils.Decode(row.vehicle)
    props.plate = plate
    props.engineHealth = tonumber(row.engine) or props.engineHealth or 1000.0
    props.bodyHealth = tonumber(row.body) or props.bodyHealth or 1000.0
    props.fuelLevel = tonumber(row.fuel) or props.fuelLevel or 100.0
    props.dirtLevel = tonumber(row.dirt) or props.dirtLevel or 0.0

    -- Marque comme sorti AVANT spawn (anti-dupe race)
    local updated = MySQL.update.await([[
        UPDATE garage_vehicles SET stored = 0, last_out = NOW(), net_id = NULL
        WHERE plate = ? AND stored = 1 AND impound = 0
    ]], { plate })

    if not updated or updated < 1 then
        GarageSecurity.UnlockPlate(plate)
        spawning[source] = nil
        return { ok = false, error = 'vehicle_already_out' }
    end

    GarageDB.SyncOwnedVehicle(plate, {
        stored = false,
        garage = garageName,
        impound = false,
        vehicle = props,
    })

    GarageLog('takeout', {
        plate = plate,
        owner = row.owner,
        identifier = identifier,
        garage = garageName,
        company = row.company,
        details = { model = props.model },
    })

    spawning[source] = nil

    return {
        ok = true,
        props = props,
        spawn = spawn,
        heading = spawn.w or garage.heading or 0.0,
        plate = plate,
        mileage = tonumber(row.mileage) or 0.0,
        company = row.company,
        giveKeys = Config.General.giveKeys,
    }
end)

--- Confirmation spawn client → enregistre netId
RegisterNetEvent('core_garage:server:spawned', function(plate, netId)
    local src = source
    plate = GarageUtils.NormalizePlate(plate)
    netId = tonumber(netId)
    if not plate or not netId then return end

    local row = MySQL.single.await('SELECT owner, company FROM garage_vehicles WHERE plate = ? AND stored = 0', { plate })
    if not row then return end
    if not GarageSecurity.IsOwnerOrCompany(src, row.owner, row.company) then return end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        local identifier = GarageGetIdentifier(src)
        Entity(entity).state:set(Config.General.ownerStatebag, identifier, true)
        Entity(entity).state:set(Config.General.plateStatebag, plate, true)
        if row.company then
            Entity(entity).state:set('garageCompany', row.company, true)
        end
        Entity(entity).state:set('garageManaged', true, true)
        MySQL.update.await('UPDATE garage_vehicles SET net_id = ? WHERE plate = ?', { netId, plate })
        GarageSecurity.LockPlate(plate, src, netId)
    end
end)

--- Spawn échoué → rollback
RegisterNetEvent('core_garage:server:spawnFailed', function(plate)
    local src = source
    plate = GarageUtils.NormalizePlate(plate)
    if plate == '' then return end
    local row = MySQL.single.await('SELECT owner, company, garage FROM garage_vehicles WHERE plate = ? AND stored = 0', { plate })
    if not row then return end
    if not GarageSecurity.IsOwnerOrCompany(src, row.owner, row.company) then return end

    MySQL.update.await('UPDATE garage_vehicles SET stored = 1, net_id = NULL WHERE plate = ?', { plate })
    GarageSecurity.UnlockPlate(plate)
    GarageDB.SyncOwnedVehicle(plate, { stored = true, garage = row.garage, impound = false, vehicle = '{}' })
end)
