local MODULE = 'garages'
local outVehicles = {} -- plate -> { src, netId, garageId }

CoreCreator.RegisterModule(MODULE, {})

local function normalizePlate(plate)
    return string.upper((tostring(plate or ''):gsub('%s+', '')))
end

local function getOwnedVehicles(identifier)
    if Bridge.Framework == 'esx' then
        return MySQL.query.await('SELECT * FROM owned_vehicles WHERE owner = ?', { identifier }) or {}
    elseif Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
        return MySQL.query.await('SELECT * FROM player_vehicles WHERE citizenid = ?', { identifier }) or {}
    end
    return MySQL.query.await('SELECT * FROM core_creator_owned_vehicles WHERE owner = ?', { identifier }) or {}
end

local function setStored(identifier, plate, stored, garageName)
    plate = normalizePlate(plate)
    if Bridge.Framework == 'esx' then
        MySQL.update.await('UPDATE owned_vehicles SET stored = ? WHERE owner = ? AND plate = ?', { stored and 1 or 0, identifier, plate })
    elseif Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
        MySQL.update.await(
            'UPDATE player_vehicles SET state = ?, garage = COALESCE(?, garage) WHERE citizenid = ? AND plate = ?',
            { stored and 1 or 0, garageName, identifier, plate }
        )
    else
        MySQL.update.await(
            'UPDATE core_creator_owned_vehicles SET stored = ?, garage = COALESCE(?, garage) WHERE owner = ? AND plate = ?',
            { stored and 1 or 0, garageName, identifier, plate }
        )
    end
end

RegisterNetEvent('core_creator:garages:listVehicles', function(garageId)
    local src = source
    garageId = tonumber(garageId)
    local garage = Database.GetById(MODULE, garageId)
    if not garage or not garage.active then return end

    local near = ServerValidator.PlayerNearCoords(src, garage.coords, (garage.data and garage.data.interactDistance) or Config.Distances.interaction)
    if not near then
        Bridge.Notify(src, _('error.distance'), 'error')
        return
    end

    local data = garage.data or {}
    if data.job and data.job ~= '' then
        local job, grade = Bridge.GetJob(src)
        if job ~= data.job or grade < (tonumber(data.minGrade) or 0) then
            Bridge.Notify(src, _('error.permission'), 'error')
            return
        end
    end

    local identifier = Bridge.GetIdentifier(src)
    local vehicles = getOwnedVehicles(identifier)
    local filtered = {}
    for i = 1, #vehicles do
        local v = vehicles[i]
        local plate = normalizePlate(v.plate)
        local stored = v.stored == 1 or v.state == 1 or v.stored == true
        if data.type == 'impound' or stored then
            filtered[#filtered + 1] = {
                plate = plate,
                vehicle = CoreUtils.SafeJsonDecode(v.vehicle or v.mods) or {},
                stored = stored,
            }
        end
    end
    TriggerClientEvent('core_creator:garages:vehicles', src, garageId, filtered)
end)

RegisterNetEvent('core_creator:garages:spawn', function(garageId, plate, spawnIndex)
    local src = source
    garageId = tonumber(garageId)
    plate = normalizePlate(plate)
    spawnIndex = tonumber(spawnIndex) or 1

    if outVehicles[plate] then
        Bridge.Notify(src, 'Véhicule déjà sorti', 'error')
        return
    end

    local garage = Database.GetById(MODULE, garageId)
    if not garage or not garage.active then return end
    local near = ServerValidator.PlayerNearCoords(src, garage.coords, Config.Distances.interaction + 5.0)
    if not near then return end

    local data = garage.data or {}
    local price = math.floor(tonumber(data.spawnPrice) or 0)
    if data.type == 'impound' then
        price = math.floor(tonumber(data.impoundPrice) or price)
    end
    if price > 0 and not Bridge.RemoveMoney(src, 'bank', price, 'garage_spawn') then
        Bridge.Notify(src, _('error.money'), 'error')
        return
    end

    local identifier = Bridge.GetIdentifier(src)
    local vehicles = getOwnedVehicles(identifier)
    local found = nil
    for i = 1, #vehicles do
        if normalizePlate(vehicles[i].plate) == plate then
            found = vehicles[i]
            break
        end
    end
    if not found then return end

    local spawns = data.spawns or {}
    local spawn = spawns[spawnIndex] or data.spawn or garage.coords
    if not spawn then return end

    setStored(identifier, plate, false, garage.name)
    outVehicles[plate] = { src = src, garageId = garageId }

    TriggerClientEvent('core_creator:garages:doSpawn', src, {
        garageId = garageId,
        plate = plate,
        props = CoreUtils.SafeJsonDecode(found.vehicle or found.mods) or {},
        coords = spawn,
        heading = spawn.w or spawn.heading or 0.0,
    })
    Logger.Log(src, 'garage_spawn', MODULE, garageId, { plate = plate })
end)

RegisterNetEvent('core_creator:garages:store', function(garageId, plate, props)
    local src = source
    garageId = tonumber(garageId)
    plate = normalizePlate(plate)
    local garage = Database.GetById(MODULE, garageId)
    if not garage or not garage.active then return end

    local storeCoords = (garage.data and garage.data.store) or garage.coords
    local near = ServerValidator.PlayerNearCoords(src, storeCoords, Config.Distances.interaction + 8.0)
    if not near then
        Bridge.Notify(src, _('error.distance'), 'error')
        return
    end

    local identifier = Bridge.GetIdentifier(src)
    if type(props) == 'table' then
        local encoded = json.encode(props)
        if Bridge.Framework == 'esx' then
            MySQL.update.await('UPDATE owned_vehicles SET vehicle = ?, stored = 1 WHERE owner = ? AND plate = ?', { encoded, identifier, plate })
        elseif Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
            MySQL.update.await('UPDATE player_vehicles SET mods = ?, state = 1, garage = ? WHERE citizenid = ? AND plate = ?', { encoded, garage.name, identifier, plate })
        else
            MySQL.update.await('UPDATE core_creator_owned_vehicles SET vehicle = ?, stored = 1, garage = ? WHERE owner = ? AND plate = ?', { encoded, garage.name, identifier, plate })
        end
    else
        setStored(identifier, plate, true, garage.name)
    end

    outVehicles[plate] = nil
    Bridge.Notify(src, 'Véhicule rangé', 'success')
    Logger.Log(src, 'garage_store', MODULE, garageId, { plate = plate })
end)

RegisterNetEvent('core_creator:garages:markOut', function(plate, netId)
    local src = source
    plate = normalizePlate(plate)
    if outVehicles[plate] and outVehicles[plate].src == src then
        outVehicles[plate].netId = netId
    end
end)

RegisterNetEvent('core_creator:garages:requestSync', function()
    TriggerClientEvent('core_creator:garages:sync', source, Database.GetAll(MODULE, true))
end)

AddEventHandler('core_creator:databaseReady', function()
    Wait(100)
    TriggerClientEvent('core_creator:garages:sync', -1, Database.GetAll(MODULE, true))
end)

AddEventHandler('core_creator:entityChanged', function(moduleName)
    if moduleName ~= MODULE then return end
    TriggerClientEvent('core_creator:garages:sync', -1, Database.GetAll(MODULE, true))
end)

AddEventHandler('playerDropped', function()
    local src = source
    for plate, info in pairs(outVehicles) do
        if info.src == src then
            outVehicles[plate] = nil
        end
    end
end)
