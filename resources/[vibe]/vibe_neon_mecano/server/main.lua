local function isMechanic(src)
    local job = exports.vibe_api:GetJob(src)
    return job and Config.Jobs[job.name] and job.onduty
end

local function addSocietyMoney(amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    local ok = exports['Renewed-Banking']:addAccountMoney(Config.SocietyAccount, amount)
    if ok then
        print(('[vibe_neon_mecano] +%d$ société (%s)'):format(amount, reason or ''))
    end
    return ok
end

local priceMap = {
    engine = Config.Prices.engine,
    body = Config.Prices.body,
    tank = Config.Prices.tank,
    tires = Config.Prices.tires,
    clean = Config.Prices.clean,
    full = Config.Prices.full,
}

RegisterNetEvent('vibe_neon_mecano:server:repair', function(netId, fixType)
    local src = source
    if not isMechanic(src) then return end
    fixType = tostring(fixType or 'full')
    local price = priceMap[fixType] or 0

    TriggerClientEvent('vibe_neon_mecano:client:applyFix', -1, netId, fixType)

    if price > 0 then
        local societyCut = math.floor(price * (1.0 - Config.EmployeeCut))
        local employeeCut = price - societyCut
        addSocietyMoney(societyCut, 'repair-' .. fixType)
        if employeeCut > 0 then
            exports.vibe_api:AddMoney(src, 'bank', employeeCut, 'neon-repair-bonus')
        end
    end

    exports.vibe_api:Notify(src, Config.CompanyName, 'Intervention terminée.', 'success')
end)

local customPrices = {
    neon = Config.Prices.customNeon,
    color = Config.Prices.customColor,
    tint = Config.Prices.customTint,
    wheels = Config.Prices.customWheels,
}

RegisterNetEvent('vibe_neon_mecano:server:custom', function(netId, modType)
    local src = source
    if not isMechanic(src) then return end
    modType = tostring(modType or 'neon')
    local price = customPrices[modType] or Config.Prices.customNeon

    local societyCut = math.floor(price * (1.0 - Config.EmployeeCut))
    local employeeCut = price - societyCut
    addSocietyMoney(societyCut, 'custom-' .. modType)
    if employeeCut > 0 then
        exports.vibe_api:AddMoney(src, 'bank', employeeCut, 'neon-custom-bonus')
    end

    TriggerClientEvent('vibe_neon_mecano:client:syncCustom', -1, netId, {})
    exports.vibe_api:Notify(src, Config.CompanyName, 'Custom enregistré — facturation société.', 'success')
end)

RegisterNetEvent('vibe_neon_mecano:server:spawnVehicle', function(model)
    local src = source
    if not isMechanic(src) then return end
    model = tostring(model or 'flatbed'):sub(1, 32)
    TriggerClientEvent('vibe_neon_mecano:client:spawnVehicle', src, model)
end)

exports('IsMechanicOnDuty', function(src)
    return isMechanic(src)
end)

exports('AddSocietyMoney', addSocietyMoney)
