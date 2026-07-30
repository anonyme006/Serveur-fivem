local MODULE = 'farms'
local cooldowns = {} -- [src][farmId_stageIndex] = gameTimer

CoreCreator.RegisterModule(MODULE, {})

local function stageKey(farmId, stageIndex)
    return tostring(farmId) .. ':' .. tostring(stageIndex)
end

RegisterNetEvent('core_creator:farms:action', function(farmId, stageIndex)
    local src = source
    farmId = tonumber(farmId)
    stageIndex = tonumber(stageIndex)
    if not farmId or not stageIndex then return end

    local farm = Database.GetById(MODULE, farmId)
    if not farm or not farm.active then return end
    local data = farm.data or {}
    local stages = data.stages or {}
    local stage = stages[stageIndex]
    if type(stage) ~= 'table' then return end

    local coords = stage.coords or farm.coords
    local near = ServerValidator.PlayerNearCoords(src, coords, stage.interactDistance or Config.Distances.interaction)
    if not near then
        Bridge.Notify(src, _('error.distance'), 'error')
        return
    end

    if data.job and data.job ~= '' then
        local job, grade = Bridge.GetJob(src)
        if job ~= data.job or grade < (tonumber(data.minGrade) or 0) then
            Bridge.Notify(src, _('error.permission'), 'error')
            return
        end
    end

    cooldowns[src] = cooldowns[src] or {}
    local key = stageKey(farmId, stageIndex)
    local now = GetGameTimer()
    local cd = tonumber(stage.cooldown or data.cooldown or Config.Cooldowns.farmAction) or Config.Cooldowns.farmAction
    if cooldowns[src][key] and now - cooldowns[src][key] < cd then
        Bridge.Notify(src, _('error.cooldown'), 'error')
        return
    end

    local required = stage.requiredItem
    local requiredCount = math.floor(tonumber(stage.requiredCount) or 1)
    if required and required ~= '' then
        if not Bridge.HasItem(src, required, requiredCount) then
            Bridge.Notify(src, _('error.item'), 'error')
            return
        end
    end

    local chance = tonumber(stage.chance) or 100
    if math.random(1, 100) > chance then
        cooldowns[src][key] = now
        if required and stage.consumeOnFail then
            Bridge.RemoveItem(src, required, requiredCount)
        end
        Bridge.Notify(src, 'Échec de l\'action', 'error')
        return
    end

    if required and required ~= '' and stage.consumeRequired ~= false then
        if not Bridge.RemoveItem(src, required, requiredCount) then return end
    end

    local rewardItem = stage.rewardItem
    local minQ = math.floor(tonumber(stage.minAmount) or 1)
    local maxQ = math.floor(tonumber(stage.maxAmount) or minQ)
    if maxQ < minQ then maxQ = minQ end
    local amount = math.random(minQ, maxQ)

    if stage.type == 'sell' then
        local priceMin = math.floor(tonumber(stage.priceMin or stage.price) or 0)
        local priceMax = math.floor(tonumber(stage.priceMax or stage.price) or priceMin)
        local unit = math.random(priceMin, math.max(priceMin, priceMax))
        local currency = stage.currency or 'money'
        Bridge.AddMoney(src, currency, unit * amount, 'farm_sell')
        Bridge.Notify(src, ('Vente farming: $%s'):format(unit * amount), 'success')
    elseif rewardItem and rewardItem ~= '' then
        if not Bridge.CanCarryItem(src, rewardItem, amount) then
            if required and required ~= '' then
                Bridge.AddItem(src, required, requiredCount)
            end
            Bridge.Notify(src, 'Inventaire plein', 'error')
            return
        end
        Bridge.AddItem(src, rewardItem, amount)
        Bridge.Notify(src, ('+%s %s'):format(amount, rewardItem), 'success')
    end

    cooldowns[src][key] = now
    Logger.Log(src, 'farm_action', MODULE, farmId, { stage = stageIndex, reward = rewardItem, amount = amount })
end)

RegisterNetEvent('core_creator:farms:requestSync', function()
    TriggerClientEvent('core_creator:farms:sync', source, Database.GetAll(MODULE, true))
end)

AddEventHandler('core_creator:databaseReady', function()
    Wait(100)
    TriggerClientEvent('core_creator:farms:sync', -1, Database.GetAll(MODULE, true))
end)

AddEventHandler('core_creator:entityChanged', function(moduleName)
    if moduleName ~= MODULE then return end
    TriggerClientEvent('core_creator:farms:sync', -1, Database.GetAll(MODULE, true))
end)

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
end)
