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

    -- both: cash first, then bank
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
    -- qbx_vehiclekeys
    pcall(function()
        exports.qbx_vehiclekeys:GiveKeys(src, plate)
    end)
    -- qb-vehiclekeys / legacy
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

local function processPurchase(source, model)
    local Player = getPlayer(source)
    if not Player then
        return { ok = false, reason = 'purchase_failed' }
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
        Config.DefaultGarage or 'pillboxgarage',
        100,
        1000.0,
        1000.0,
        Config.PurchaseState or 0,
    })

    local spawn = Config.PurchaseSpawn
    TriggerClientEvent('qbx_concessionnaire:client:spawnPurchased', source, {
        model = vehicle.model,
        plate = plate,
        coords = { x = spawn.coords.x, y = spawn.coords.y, z = spawn.coords.z },
        heading = spawn.heading,
    })

    giveKeys(source, plate, vehicle.model)

    return {
        ok = true,
        name = vehicle.name,
        price = vehicle.price,
        plate = plate,
    }
end

lib.callback.register('qbx_concessionnaire:buyVehicle', function(source, model)
    if type(model) ~= 'string' or #model < 1 or #model > 40 then
        return { ok = false, reason = 'purchase_failed' }
    end
    return processPurchase(source, model)
end)

RegisterNetEvent('qbx_concessionnaire:server:vehicleSpawned', function(plate, netId)
    local src = source
    if type(plate) ~= 'string' then return end
    giveKeys(src, plate, nil, netId)
end)
