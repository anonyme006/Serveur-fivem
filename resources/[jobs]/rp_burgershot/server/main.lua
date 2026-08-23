local function isBurgerEmployee(source)
    local player = exports.rp_core:GetPlayer(source)
    if not player then return false end
    local job = player.PlayerData.job
    if not job or job.name ~= Config.Job then return false end
    if Config.RequireDuty and not job.onduty then return false end
    return true, player
end

local function hasItems(source, input)
    if not input then return true end
    if input.item then
        return exports.ox_inventory:GetItemCount(source, input.item) >= (input.count or 1)
    end
    for i = 1, #input do
        local req = input[i]
        if exports.ox_inventory:GetItemCount(source, req.item) < (req.count or 1) then
            return false
        end
    end
    return true
end

local function takeItems(source, input)
    if not input then return true end
    if input.item then
        return exports.ox_inventory:RemoveItem(source, input.item, input.count or 1)
    end
    for i = 1, #input do
        local req = input[i]
        if not exports.ox_inventory:RemoveItem(source, req.item, req.count or 1) then
            return false
        end
    end
    return true
end

lib.callback.register('rp_burgershot:canCraft', function(source, stationId)
    if not isBurgerEmployee(source) then return false end
    local station = Config.Stations[stationId]
    if not station then return false end
    return hasItems(source, station.input)
end)

RegisterNetEvent('rp_burgershot:server:craft', function(stationId)
    local src = source
    if not exports.rp_core:RateLimit(src, 'bs_craft', 1500) then return end
    if not isBurgerEmployee(src) then return end
    local station = Config.Stations[stationId]
    if not station then return end
    if not hasItems(src, station.input) then
        exports.rp_core:Notify(src, 'Ingrédients manquants.', 'error')
        return
    end
    if not takeItems(src, station.input) then return end
    exports.ox_inventory:AddItem(src, station.output.item, station.output.count or 1)
    exports.rp_core:Notify(src, station.label .. ' terminé.', 'success')
end)

local function getMeal(id)
    for _, meal in ipairs(Config.Menu) do
        if meal.id == id then return meal end
    end
end

RegisterNetEvent('rp_burgershot:server:sell', function(mealId, targetId)
    local src = source
    if not exports.rp_core:RateLimit(src, 'bs_sell', 2000) then return end
    local okEmployee = isBurgerEmployee(src)
    if not okEmployee then return end

    targetId = tonumber(targetId)
    local meal = getMeal(mealId)
    if not meal or not targetId then return end

    local target = exports.rp_core:GetPlayer(targetId)
    if not target then
        exports.rp_core:Notify(src, 'Client introuvable.', 'error')
        return
    end

    local pedA, pedB = GetPlayerPed(src), GetPlayerPed(targetId)
    if pedA == 0 or pedB == 0 then return end
    if #(GetEntityCoords(pedA) - GetEntityCoords(pedB)) > Config.MaxOrderDistance then
        exports.rp_core:Notify(src, 'Client trop loin de la caisse.', 'error')
        return
    end

    for item, count in pairs(meal.items) do
        if exports.ox_inventory:GetItemCount(src, item) < count then
            exports.rp_core:Notify(src, 'Vous n\'avez pas préparé cette commande.', 'error')
            return
        end
    end

    if not exports.rp_core:RemoveMoney(targetId, 'cash', meal.price, 'burgershot:' .. meal.id) then
        if not exports.rp_core:RemoveMoney(targetId, 'bank', meal.price, 'burgershot:' .. meal.id) then
            exports.rp_core:Notify(src, 'Client insolvable.', 'error')
            exports.rp_core:Notify(targetId, 'Fonds insuffisants.', 'error')
            return
        end
    end

    for item, count in pairs(meal.items) do
        exports.ox_inventory:RemoveItem(src, item, count)
        exports.ox_inventory:AddItem(targetId, item, count)
    end

    if GetResourceState('rp_business') == 'started' then
        exports.rp_business:AddBusinessMoney('burgershot', meal.price)
        exports.rp_business:LogBusinessTransaction('burgershot', meal.price, exports.rp_core:GetPlayer(src).PlayerData.citizenid, 'sale', meal.label)
    else
        exports.rp_core:AddSocietyMoney('burgershot', meal.price, meal.label)
    end

    if Config.SalaryBonus > 0 then
        exports.rp_core:AddMoney(src, 'cash', Config.SalaryBonus, 'burgershot_tip')
    end

    exports.rp_core:Notify(src, ('Vente %s — %s$'):format(meal.label, meal.price), 'success')
    exports.rp_core:Notify(targetId, ('Vous avez acheté : %s'):format(meal.label), 'success')

    if GetResourceState('rp_logs') == 'started' then
        exports.rp_logs:Log('business', src, 'Vente Burger Shot', { meal = meal.id, price = meal.price, target = target.PlayerData.citizenid })
    end
end)

-- Items ox_inventory (à fusionner dans ox_inventory/data/items.lua si absents)
--[[
['bs_raw_patty'] = { label = 'Steak cru', weight = 120, stack = true },
['bs_patty'] = { label = 'Steak cuit', weight = 120, stack = true },
['bs_potato'] = { label = 'Pomme de terre', weight = 100, stack = true },
['bs_fries'] = { label = 'Frites', weight = 110, stack = true, client = { status = { hunger = 12 } } },
['bs_bun'] = { label = 'Pain burger', weight = 80, stack = true },
['bs_burger'] = { label = 'Burger Shot', weight = 220, stack = true, client = { status = { hunger = 35 } } },
['bs_drink'] = { label = 'Boisson BS', weight = 150, stack = true, client = { status = { thirst = 25 } } },
]]

print('[rp_burgershot] ready — boucle craft/caisse active')
