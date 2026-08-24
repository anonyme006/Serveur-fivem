local function getVehicleByModel(model)
    for i = 1, #Config.Vehicles do
        local v = Config.Vehicles[i]
        if v.model == model then
            return v
        end
    end
    return nil
end

local function getPlayer(src)
    return exports.qbx_core:GetPlayer(src)
end

local function normalizeAccount(account)
    if account == 'money' then return 'cash' end
    return account or 'cash'
end

local function playerNearAnyZone(src, maxDist)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false, nil end
    local pcoords = GetEntityCoords(ped)

    for i = 1, #Config.Zones do
        local zone = Config.Zones[i]
        local menu = zone.menu
        local dx = pcoords.x - menu.x
        local dy = pcoords.y - menu.y
        local dz = pcoords.z - menu.z
        local dist = maxDist or ((zone.interactDistance or 1.8) + 3.0)
        if (dx * dx + dy * dy + dz * dz) <= (dist * dist) then
            return true, zone
        end
    end

    return false, nil
end

local function generatePlate()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    for _ = 1, 20 do
        local digits = ''
        for i = 1, Config.PlateDigits do
            local idx = math.random(1, #chars)
            digits = digits .. chars:sub(idx, idx)
        end
        local plate = string.sub((Config.PlatePrefix or 'VIBE') .. digits, 1, 8):upper()
        local exists = MySQL.scalar.await('SELECT 1 FROM `player_vehicles` WHERE `plate` = ? LIMIT 1', { plate })
        if not exists then
            return plate
        end
    end
    return nil
end

local function tryPay(Player, price)
    local account = Config.PaymentAccount or 'both'
    price = math.floor(tonumber(price) or 0)
    if price <= 0 then return true, 'cash' end

    if account == 'money' or account == 'cash' then
        if Player.Functions.GetMoney('cash') >= price then
            Player.Functions.RemoveMoney('cash', price, 'concessionnaire')
            return true, 'cash'
        end
        return false, nil
    end

    if account == 'bank' then
        if Player.Functions.GetMoney('bank') >= price then
            Player.Functions.RemoveMoney('bank', price, 'concessionnaire')
            return true, 'bank'
        end
        return false, nil
    end

    if Player.Functions.GetMoney('cash') >= price then
        Player.Functions.RemoveMoney('cash', price, 'concessionnaire')
        return true, 'cash'
    end

    if Player.Functions.GetMoney('bank') >= price then
        Player.Functions.RemoveMoney('bank', price, 'concessionnaire')
        return true, 'bank'
    end

    return false, nil
end

local function refund(Player, account, price)
    Player.Functions.AddMoney(normalizeAccount(account) or 'bank', price, 'concessionnaire-refund')
end

local function giveKeys(src, plate, model, netId)
    pcall(function()
        exports.qbx_vehiclekeys:GiveKeys(src, plate)
    end)
    TriggerClientEvent('qb-vehiclekeys:client:AddKeys', src, plate)
    TriggerClientEvent('vehiclekeys:client:SetOwner', src, plate)
    pcall(function()
        exports['wasabi_carlock']:GiveKey(src, plate)
    end)
    pcall(function()
        exports['qs-vehiclekeys']:GiveKeys(src, plate, model)
    end)
    if netId then
        TriggerClientEvent('qbx_concessionnaire:client:giveKeys', src, netId, plate)
    end
end

local function resolveSpawn(zone, spawn)
    if type(spawn) == 'table' and spawn.x and spawn.y and spawn.z then
        return {
            coords = { x = spawn.x + 0.0, y = spawn.y + 0.0, z = spawn.z + 0.0 },
            heading = (spawn.w or spawn.heading or 0.0) + 0.0,
        }
    end

    if zone and zone.parks and zone.parks[1] then
        local park = zone.parks[1]
        return {
            coords = { x = park.x, y = park.y, z = park.z },
            heading = park.w or 0.0,
        }
    end

    local fallback = Config.PurchaseSpawn
    return {
        coords = {
            x = fallback.coords.x,
            y = fallback.coords.y,
            z = fallback.coords.z,
        },
        heading = fallback.heading or 0.0,
    }
end

local function processPurchase(source, model, spawn)
    local Player = getPlayer(source)
    if not Player then
        return { ok = false, reason = 'purchase_failed' }
    end

    local near, zone = playerNearAnyZone(source)
    if not near then
        return { ok = false, reason = 'too_far' }
    end

    local vehicle = getVehicleByModel(model)
    if not vehicle then
        return { ok = false, reason = 'purchase_failed' }
    end

    local paid, paidFrom = tryPay(Player, vehicle.price)
    if not paid then
        return { ok = false, reason = 'money' }
    end

    local plate = generatePlate()
    if not plate then
        refund(Player, paidFrom or 'bank', vehicle.price)
        return { ok = false, reason = 'already_owned_plate' }
    end

    local citizenid = Player.PlayerData.citizenid
    local license = Player.PlayerData.license
    local hash = joaat(vehicle.model)
    local mods = {
        model = hash,
        plate = plate,
    }

    MySQL.insert.await([[
        INSERT INTO `player_vehicles`
            (`license`, `citizenid`, `vehicle`, `hash`, `mods`, `plate`, `garage`, `fuel`, `engine`, `body`, `state`)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        license,
        citizenid,
        vehicle.model,
        hash,
        json.encode(mods),
        plate,
        Config.DefaultGarage or 'pillbox',
        100,
        1000.0,
        1000.0,
        Config.PurchaseState or 0,
    })

    local resolved = resolveSpawn(zone, spawn)

    if (Config.PurchaseState or 0) == 0 then
        TriggerClientEvent('qbx_concessionnaire:client:spawnPurchased', source, {
            model = vehicle.model,
            plate = plate,
            coords = resolved.coords,
            heading = resolved.heading,
        })
        giveKeys(source, plate, vehicle.model)
    end

    return {
        ok = true,
        name = vehicle.name,
        price = vehicle.price,
        plate = plate,
    }
end

lib.callback.register('qbx_concessionnaire:buyVehicle', function(source, model, spawn)
    if type(model) ~= 'string' or #model < 1 or #model > 40 then
        return { ok = false, reason = 'purchase_failed' }
    end
    return processPurchase(source, model, spawn)
end)

RegisterNetEvent('qbx_concessionnaire:server:vehicleSpawned', function(plate, netId)
    local src = source
    if type(plate) ~= 'string' then return end
    giveKeys(src, plate, nil, netId)
end)
