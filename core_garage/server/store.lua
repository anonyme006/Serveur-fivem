--[[--------------------------------------------------------------------------
    core_garage — rangement véhicule
---------------------------------------------------------------------------]]

---@param entity number
---@return table
local function captureVehicleProps(entity)
    -- Capture minimale serveur ; le client envoie les props complets
    local plate = GarageUtils.NormalizePlate(GetVehicleNumberPlateText(entity))
    return {
        plate = plate,
        model = GetEntityModel(entity),
        engineHealth = GetVehicleEngineHealth(entity),
        bodyHealth = GetVehicleBodyHealth(entity),
        -- fuel / dirt / mods : fournis par le client
    }
end

lib.callback.register('core_garage:storeVehicle', function(source, data)
    if type(data) ~= 'table' then return { ok = false, error = 'error' } end
    if not GarageSecurity.RateOk(source) then return { ok = false, error = 'anti_dupe' } end

    local plate = GarageUtils.NormalizePlate(data.plate)
    local netId = tonumber(data.netId)
    local garageName = data.garage
    local props = data.props
    local engineOff = data.engineOff

    if plate == '' or not netId or not garageName or type(props) ~= 'table' then
        return { ok = false, error = 'error' }
    end

    local garage = GarageDB.GetGarage(garageName)
    if not garage then return { ok = false, error = 'error' } end

    local access, err = GarageSecurity.CanAccessGarage(source, garage)
    if not access then return { ok = false, error = err } end

    if garage.type == 'impound' then
        return { ok = false, error = 'cannot_store_here' }
    end

    -- Distance point de retour OU coords garage
    local storeCoords = garage.store or garage.coords
    if not GarageSecurity.IsNear(source, storeCoords, Config.General.maxDistance + 8.0) then
        return { ok = false, error = 'too_far' }
    end

    local valid, entity = GarageSecurity.ValidateNetVehicle(source, netId, plate)
    if not valid or not entity then
        -- Fallback : vérifier ownership DB + proximité véhicule
        entity = NetworkGetEntityFromNetworkId(netId)
        if not entity or entity == 0 or not DoesEntityExist(entity) then
            return { ok = false, error = 'vehicle_not_found' }
        end
        local entPlate = GarageUtils.NormalizePlate(GetVehicleNumberPlateText(entity))
        if entPlate ~= plate then
            return { ok = false, error = 'vehicle_not_yours' }
        end
    end

    local ped = GetPlayerPed(source)
    local pcoords = GetEntityCoords(ped)
    local vcoords = GetEntityCoords(entity)
    if #(pcoords - vcoords) > (Config.General.storeTargetDistance + 5.0) then
        return { ok = false, error = 'not_close_enough' }
    end

    if Config.General.requireEngineOff and engineOff == false then
        return { ok = false, error = 'engine_must_be_off' }
    end

    local row = MySQL.single.await('SELECT * FROM garage_vehicles WHERE plate = ?', { plate })
    if not row then return { ok = false, error = 'vehicle_not_found' } end

    local identifier = GarageGetIdentifier(source)
    if not GarageSecurity.IsOwnerOrCompany(source, row.owner, row.company) then
        return { ok = false, error = 'vehicle_not_yours' }
    end

    if row.stored == 1 or row.stored == true then
        return { ok = false, error = 'anti_dupe' }
    end

    -- Grade entreprise store
    if row.company and row.company ~= '' then
        local company = GarageDB.companies[row.company] and GarageDB.companies[row.company][garageName]
        if company then
            local xPlayer = ESX.GetPlayerFromId(source)
            local grade = xPlayer and xPlayer.getJob().grade or 0
            if grade < (company.min_grade_store or 0) then
                return { ok = false, error = 'company_store_denied' }
            end
        end
    end

    -- Type véhicule compatible
    local vType = garage.vehicle_type or 'car'
    if row.type and row.type ~= vType and garage.type ~= 'public' and garage.type ~= 'personal' and garage.type ~= 'company' and garage.type ~= 'job' then
        return { ok = false, error = 'cannot_store_here' }
    end

    props.plate = plate
    local engine = tonumber(props.engineHealth) or GetVehicleEngineHealth(entity)
    local body = tonumber(props.bodyHealth) or GetVehicleBodyHealth(entity)
    local fuel = tonumber(props.fuelLevel) or 100.0
    local dirt = tonumber(props.dirtLevel) or 0.0

    local updated = MySQL.update.await([[
        UPDATE garage_vehicles
        SET stored = 1, impound = 0, impound_id = NULL, garage = ?, vehicle = ?,
            engine = ?, body = ?, fuel = ?, dirt = ?, net_id = NULL, last_in = NOW()
        WHERE plate = ? AND stored = 0
    ]], {
        garageName,
        GarageUtils.Encode(props),
        engine, body, fuel, dirt,
        plate,
    })

    if not updated or updated < 1 then
        return { ok = false, error = 'anti_dupe' }
    end

    GarageDB.SyncOwnedVehicle(plate, {
        stored = true,
        garage = garageName,
        impound = false,
        vehicle = props,
    })

    GarageLog('store', {
        plate = plate,
        owner = row.owner,
        identifier = identifier,
        garage = garageName,
        company = row.company,
        details = { engine = engine, body = body, fuel = fuel },
    })

    -- Supprime l'entité
    if DoesEntityExist(entity) then
        DeleteEntity(entity)
    end

    GarageSecurity.UnlockPlate(plate)

    return { ok = true }
end)

-- Capture props côté client avant store (callback helper)
lib.callback.register('core_garage:canStore', function(source, netId, garageName)
    netId = tonumber(netId)
    local garage = GarageDB.GetGarage(garageName)
    if not garage or not netId then return { ok = false, error = 'error' } end

    local access, err = GarageSecurity.CanAccessGarage(source, garage)
    if not access then return { ok = false, error = err } end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 or not DoesEntityExist(entity) then
        return { ok = false, error = 'vehicle_not_found' }
    end

    local plate = GarageUtils.NormalizePlate(GetVehicleNumberPlateText(entity))
    local row = MySQL.single.await('SELECT owner, company, stored, type FROM garage_vehicles WHERE plate = ?', { plate })
    if not row then return { ok = false, error = 'vehicle_not_yours' } end
    if not GarageSecurity.IsOwnerOrCompany(source, row.owner, row.company) then
        return { ok = false, error = 'vehicle_not_yours' }
    end
    if row.stored == 1 then return { ok = false, error = 'anti_dupe' } end

    return { ok = true, plate = plate }
end)
