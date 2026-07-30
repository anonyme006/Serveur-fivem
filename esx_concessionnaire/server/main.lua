local function getVehicleByModel(model)
    for _, v in ipairs(Config.Vehicles) do
        if v.model == model then
            return v
        end
    end
    return nil
end

local function generatePlate()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local plate

    for _ = 1, 20 do
        local digits = ''
        for i = 1, Config.PlateDigits do
            local idx = math.random(1, #chars)
            digits = digits .. chars:sub(idx, idx)
        end
        plate = (Config.PlatePrefix or 'VIBE') .. digits
        plate = string.sub(plate, 1, 8):upper()

        local exists = MySQL.scalar.await('SELECT 1 FROM owned_vehicles WHERE plate = ? LIMIT 1', { plate })
        if not exists then
            return plate
        end
    end

    return nil
end

local function tryPay(xPlayer, price)
    local account = Config.PaymentAccount or 'both'

    if account == 'money' then
        if xPlayer.getMoney() >= price then
            xPlayer.removeMoney(price, 'concessionnaire')
            return true, 'money'
        end
        return false, nil
    end

    if account == 'bank' then
        if xPlayer.getAccount('bank').money >= price then
            xPlayer.removeAccountMoney('bank', price, 'concessionnaire')
            return true, 'bank'
        end
        return false, nil
    end

    -- both: cash first, then bank
    if xPlayer.getMoney() >= price then
        xPlayer.removeMoney(price, 'concessionnaire')
        return true, 'money'
    end

    if xPlayer.getAccount('bank').money >= price then
        xPlayer.removeAccountMoney('bank', price, 'concessionnaire')
        return true, 'bank'
    end

    return false, nil
end

local function giveKeys(src, plate, model)
    -- Compatibilité optionnelle avec des scripts de clés courants
    TriggerClientEvent('vehiclekeys:client:SetOwner', src, plate)
    TriggerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', src, plate)
    pcall(function()
        exports['wasabi_carlock']:GiveKey(src, plate)
    end)
    pcall(function()
        exports['qs-vehiclekeys']:GiveKeys(src, plate, model)
    end)
end

ESX.RegisterServerCallback('esx_concessionnaire:buyVehicle', function(source, cb, model)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb({ ok = false, reason = 'purchase_failed' })
        return
    end

    local vehicle = getVehicleByModel(model)
    if not vehicle then
        cb({ ok = false, reason = 'purchase_failed' })
        return
    end

    local paid, paidFrom = tryPay(xPlayer, vehicle.price)
    if not paid then
        cb({ ok = false, reason = 'money' })
        return
    end

    local plate = generatePlate()
    if not plate then
        if paidFrom == 'bank' then
            xPlayer.addAccountMoney('bank', vehicle.price, 'concessionnaire-refund')
        else
            xPlayer.addMoney(vehicle.price, 'concessionnaire-refund')
        end
        cb({ ok = false, reason = 'already_owned_plate' })
        return
    end

    local props = {
        model = joaat(vehicle.model),
        plate = plate,
    }

    MySQL.insert.await(
        'INSERT INTO owned_vehicles (owner, plate, vehicle, type, stored) VALUES (?, ?, ?, ?, ?)',
        { xPlayer.identifier, plate, json.encode(props), 'car', 0 }
    )

    local spawn = Config.PurchaseSpawn
    TriggerClientEvent('esx_concessionnaire:spawnPurchased', source, {
        model = vehicle.model,
        plate = plate,
        coords = { x = spawn.coords.x, y = spawn.coords.y, z = spawn.coords.z },
        heading = spawn.heading,
    })

    giveKeys(source, plate, vehicle.model)

    cb({
        ok = true,
        name = vehicle.name,
        price = vehicle.price,
        plate = plate,
    })
end)

