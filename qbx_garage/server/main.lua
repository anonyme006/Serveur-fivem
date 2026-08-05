local outVehicles = {} -- [plate] = { src = number, netId = number|nil, garage = string }

local function normalizePlate(plate)
    return string.upper((tostring(plate or ''):gsub('%s+', '')))
end

local function getGarage(name)
    for i = 1, #Config.Garages do
        if Config.Garages[i].name == name then
            return Config.Garages[i]
        end
    end
    return nil
end

local function getPlayer(src)
    return exports.qbx_core:GetPlayer(src)
end

local function playerNear(src, coords, maxDist)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local pcoords = GetEntityCoords(ped)
    local dx = pcoords.x - coords.x
    local dy = pcoords.y - coords.y
    local dz = pcoords.z - coords.z
    return (dx * dx + dy * dy + dz * dz) <= ((maxDist or 3.0) * (maxDist or 3.0))
end

local function canAccessGarage(Player, garage)
    if not garage then return false end
    if garage.type == 'job' and garage.job then
        local job = Player.PlayerData.job
        if not job or job.name ~= garage.job then return false end
        local grade = job.grade and (job.grade.level or job.grade) or 0
        if grade < (tonumber(garage.minGrade) or 0) then return false end
    end
    if garage.type == 'gang' and garage.gang then
        local gang = Player.PlayerData.gang
        if not gang or gang.name ~= garage.gang then return false end
        local grade = gang.grade and (gang.grade.level or gang.grade) or 0
        if grade < (tonumber(garage.minGrade) or 0) then return false end
    end
    return true
end

local function giveKeys(src, plate, netId)
    pcall(function()
        exports.qbx_vehiclekeys:GiveKeys(src, plate)
    end)
    TriggerClientEvent('qb-vehiclekeys:client:AddKeys', src, plate)
    TriggerClientEvent('vehiclekeys:client:SetOwner', src, plate)
    if netId then
        TriggerClientEvent('qbx_garage:client:giveKeys', src, netId, plate)
    end
end

local function decodeMods(raw)
    if type(raw) == 'table' then return raw end
    if type(raw) ~= 'string' or raw == '' then return {} end
    local ok, decoded = pcall(json.decode, raw)
    return ok and decoded or {}
end

lib.callback.register('qbx_garage:server:getVehicles', function(source, garageName)
    local Player = getPlayer(source)
    local garage = getGarage(garageName)
    if not Player or not garage or not canAccessGarage(Player, garage) then
        return { ok = false, message = 'error' }
    end

    if not playerNear(source, garage.menu, (garage.interactDistance or 2.5) + 2.0) then
        return { ok = false, message = 'too_far' }
    end

    local citizenid = Player.PlayerData.citizenid
    local rows

    if garage.type == 'impound' then
        rows = MySQL.query.await(
            'SELECT * FROM `player_vehicles` WHERE `citizenid` = ? AND (`state` = ? OR `state` = ?) ORDER BY `vehicle` ASC',
            { citizenid, Config.VehicleState.IMPOUND, Config.VehicleState.OUT }
        ) or {}
        -- Pour la fourrière on montre surtout les véhicules "perdus" (out non trackés + impound)
        local filtered = {}
        for i = 1, #rows do
            local plate = normalizePlate(rows[i].plate)
            local state = tonumber(rows[i].state) or 0
            if state == Config.VehicleState.IMPOUND or (state == Config.VehicleState.OUT and not outVehicles[plate]) then
                filtered[#filtered + 1] = rows[i]
            end
        end
        rows = filtered
    else
        rows = MySQL.query.await(
            'SELECT * FROM `player_vehicles` WHERE `citizenid` = ? AND `state` = ? AND (`garage` = ? OR `garage` IS NULL OR `garage` = ?) ORDER BY `vehicle` ASC',
            { citizenid, Config.VehicleState.GARAGED, garage.name, '' }
        ) or {}
    end

    local list = {}
    for i = 1, #rows do
        local row = rows[i]
        local mods = decodeMods(row.mods)
        list[#list + 1] = {
            id = row.id,
            plate = normalizePlate(row.plate),
            model = row.vehicle,
            hash = tonumber(row.hash) or joaat(row.vehicle or 'adder'),
            fuel = tonumber(row.fuel) or 100,
            engine = tonumber(row.engine) or 1000.0,
            body = tonumber(row.body) or 1000.0,
            state = tonumber(row.state) or 1,
            garage = row.garage,
            mods = mods,
            depotprice = tonumber(row.depotprice) or (garage.impoundPrice or 0),
        }
    end

    return { ok = true, vehicles = list, garage = { name = garage.name, label = garage.label, type = garage.type, impoundPrice = garage.impoundPrice } }
end)

lib.callback.register('qbx_garage:server:takeOut', function(source, garageName, vehicleId, spawnIndex)
    local Player = getPlayer(source)
    local garage = getGarage(garageName)
    vehicleId = tonumber(vehicleId)
    spawnIndex = tonumber(spawnIndex) or 1

    if not Player or not garage or not vehicleId or not canAccessGarage(Player, garage) then
        return { ok = false, message = 'error' }
    end

    if not playerNear(source, garage.menu, (garage.interactDistance or 2.5) + 3.0) then
        return { ok = false, message = 'too_far' }
    end

    local row = MySQL.single.await(
        'SELECT * FROM `player_vehicles` WHERE `id` = ? AND `citizenid` = ? LIMIT 1',
        { vehicleId, Player.PlayerData.citizenid }
    )
    if not row then
        return { ok = false, message = 'not_owned' }
    end

    local plate = normalizePlate(row.plate)
    if outVehicles[plate] then
        return { ok = false, message = 'vehicle_out' }
    end

    local state = tonumber(row.state) or 0
    local price = 0

    if garage.type == 'impound' then
        price = math.floor(tonumber(row.depotprice) or garage.impoundPrice or 0)
        if price > 0 then
            local account = Config.ImpoundAccount or 'bank'
            if account == 'money' then account = 'cash' end
            if Player.Functions.GetMoney(account) < price then
                return { ok = false, message = 'not_enough_money' }
            end
            Player.Functions.RemoveMoney(account, price, 'garage-impound')
        end
    else
        if state ~= Config.VehicleState.GARAGED then
            return { ok = false, message = 'vehicle_out' }
        end
    end

    local spawns = garage.spawns or {}
    local spawn = spawns[spawnIndex] or spawns[1]
    if not spawn then
        return { ok = false, message = 'error' }
    end

    MySQL.update.await(
        'UPDATE `player_vehicles` SET `state` = ?, `garage` = ?, `depotprice` = 0 WHERE `id` = ?',
        { Config.VehicleState.OUT, garage.name, vehicleId }
    )

    outVehicles[plate] = { src = source, garage = garage.name }

    return {
        ok = true,
        message = 'taken_out',
        vehicle = {
            id = row.id,
            plate = plate,
            model = row.vehicle,
            hash = tonumber(row.hash) or joaat(row.vehicle or 'adder'),
            fuel = tonumber(row.fuel) or 100,
            engine = tonumber(row.engine) or 1000.0,
            body = tonumber(row.body) or 1000.0,
            mods = decodeMods(row.mods),
            spawn = {
                x = spawn.x,
                y = spawn.y,
                z = spawn.z,
                w = spawn.w or spawn.heading or 0.0,
            },
        },
    }
end)

lib.callback.register('qbx_garage:server:storeVehicle', function(source, garageName, plate, props, netId)
    local Player = getPlayer(source)
    local garage = getGarage(garageName)
    plate = normalizePlate(plate)

    if not Player or not garage or plate == '' or garage.type == 'impound' then
        return { ok = false, message = 'error' }
    end

    if not canAccessGarage(Player, garage) then
        return { ok = false, message = 'error' }
    end

    local storeCoords = garage.store or garage.menu
    if not playerNear(source, storeCoords, Config.StoreDistance or 8.0) then
        return { ok = false, message = 'too_far' }
    end

    local row = MySQL.single.await(
        'SELECT `id` FROM `player_vehicles` WHERE `plate` = ? AND `citizenid` = ? LIMIT 1',
        { plate, Player.PlayerData.citizenid }
    )
    if not row then
        return { ok = false, message = 'not_owned' }
    end

    local fuel = 100
    local engine = 1000.0
    local body = 1000.0
    local modsJson = '{}'

    if type(props) == 'table' then
        fuel = math.floor(tonumber(props.fuelLevel) or tonumber(props.fuel) or 100)
        engine = tonumber(props.engineHealth) or 1000.0
        body = tonumber(props.bodyHealth) or 1000.0
        modsJson = json.encode(props)
    end

    MySQL.update.await(
        'UPDATE `player_vehicles` SET `state` = ?, `garage` = ?, `fuel` = ?, `engine` = ?, `body` = ?, `mods` = ? WHERE `id` = ?',
        { Config.VehicleState.GARAGED, garage.name, fuel, engine, body, modsJson, row.id }
    )

    outVehicles[plate] = nil

    if netId then
        TriggerClientEvent('qbx_garage:client:deleteVehicle', -1, netId)
    end

    return { ok = true, message = 'stored' }
end)

RegisterNetEvent('qbx_garage:server:setOutNetId', function(plate, netId)
    local src = source
    plate = normalizePlate(plate)
    if outVehicles[plate] and outVehicles[plate].src == src then
        outVehicles[plate].netId = netId
        giveKeys(src, plate, netId)
    end
end)

-- Au démarrage : tous les véhicules "out" non gérés reviennent au garage (anti-dupe reboot)
AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    MySQL.update.await(
        'UPDATE `player_vehicles` SET `state` = ? WHERE `state` = ?',
        { Config.VehicleState.GARAGED, Config.VehicleState.OUT }
    )
end)

AddEventHandler('playerDropped', function()
    local src = source
    for plate, info in pairs(outVehicles) do
        if info.src == src then
            outVehicles[plate] = nil
        end
    end
end)

exports('IsVehicleOut', function(plate)
    return outVehicles[normalizePlate(plate)] ~= nil
end)
