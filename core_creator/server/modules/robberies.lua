local MODULE = 'robberies'
local activeRobberies = {} -- [robberyId] = { players = {}, stage = 1, startedAt = os.time(), starter = src }
local playerCooldown = {}
local globalCooldown = {}

CoreCreator.RegisterModule(MODULE, {})

local function countPolice()
    local jobs = Config.Robbery.defaultPoliceJobs
    local count = 0
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        local job = Bridge.GetJob(src)
        if job and CoreUtils.Includes(jobs, job) then
            count = count + 1
        end
    end
    return count
end

RegisterNetEvent('core_creator:robberies:start', function(robberyId)
    local src = source
    robberyId = tonumber(robberyId)
    local robbery = Database.GetById(MODULE, robberyId)
    if not robbery or not robbery.active then return end

    local data = robbery.data or {}
    local near = ServerValidator.PlayerNearCoords(src, robbery.coords, data.startDistance or Config.Distances.interaction)
    if not near then
        Bridge.Notify(src, _('error.distance'), 'error')
        return
    end

    if activeRobberies[robberyId] then
        Bridge.Notify(src, 'Braquage déjà en cours', 'error')
        return
    end

    local now = os.time()
    local gcd = tonumber(data.globalCooldown) or 1800
    if globalCooldown[robberyId] and now - globalCooldown[robberyId] < gcd then
        Bridge.Notify(src, _('error.cooldown'), 'error')
        return
    end

    local pcd = tonumber(data.playerCooldown) or 3600
    playerCooldown[src] = playerCooldown[src] or {}
    if playerCooldown[src][robberyId] and now - playerCooldown[src][robberyId] < pcd then
        Bridge.Notify(src, _('error.cooldown'), 'error')
        return
    end

    local minPolice = tonumber(data.minPolice) or Config.Robbery.defaultMinPolice
    if countPolice() < minPolice then
        Bridge.Notify(src, 'Pas assez de policiers', 'error')
        return
    end

    local requiredItems = data.requiredItems or {}
    for i = 1, #requiredItems do
        local it = requiredItems[i]
        if not Bridge.HasItem(src, it.name, it.count or 1) then
            Bridge.Notify(src, _('error.item'), 'error')
            return
        end
    end

    for i = 1, #requiredItems do
        local it = requiredItems[i]
        if it.consume then
            Bridge.RemoveItem(src, it.name, it.count or 1)
        end
    end

    activeRobberies[robberyId] = {
        players = { [src] = true },
        stage = 1,
        startedAt = now,
        starter = src,
    }

    TriggerClientEvent('core_creator:robberies:started', -1, robberyId, activeRobberies[robberyId])
    if data.alarm then
        TriggerEvent('core_creator:robberies:dispatch', robberyId, robbery.coords, data)
    end
    Logger.Log(src, 'robbery_start', MODULE, robberyId, {})
end)

RegisterNetEvent('core_creator:robberies:progress', function(robberyId, stageIndex)
    local src = source
    robberyId = tonumber(robberyId)
    stageIndex = tonumber(stageIndex)
    local state = activeRobberies[robberyId]
    if not state or not state.players[src] then return end

    local robbery = Database.GetById(MODULE, robberyId)
    if not robbery then return end
    local stages = (robbery.data and robbery.data.stages) or {}
    local stage = stages[stageIndex]
    if type(stage) ~= 'table' then return end

    local near = ServerValidator.PlayerNearCoords(src, stage.coords or robbery.coords, Config.Distances.robberyCancel)
    if not near then
        Bridge.Notify(src, 'Braquage annulé (distance)', 'error')
        activeRobberies[robberyId] = nil
        TriggerClientEvent('core_creator:robberies:cancelled', -1, robberyId)
        Logger.Log(src, 'robbery_cancel_distance', MODULE, robberyId, {})
        return
    end

    state.stage = stageIndex
    TriggerClientEvent('core_creator:robberies:stage', -1, robberyId, stageIndex)

    if stageIndex >= #stages then
        local rewards = (robbery.data and robbery.data.rewards) or {}
        for i = 1, #rewards do
            local reward = rewards[i]
            local chance = tonumber(reward.chance) or 100
            if math.random(1, 100) <= chance then
                if reward.type == 'item' then
                    local amount = math.random(tonumber(reward.min) or 1, tonumber(reward.max) or 1)
                    Bridge.AddItem(src, reward.name, amount)
                else
                    local amount = math.random(tonumber(reward.min) or 0, tonumber(reward.max) or 0)
                    Bridge.AddMoney(src, reward.account or 'black_money', amount, 'robbery')
                end
            end
        end

        globalCooldown[robberyId] = os.time()
        playerCooldown[src] = playerCooldown[src] or {}
        playerCooldown[src][robberyId] = os.time()
        activeRobberies[robberyId] = nil
        TriggerClientEvent('core_creator:robberies:finished', -1, robberyId)
        Logger.Log(src, 'robbery_finish', MODULE, robberyId, {})
        Bridge.Notify(src, 'Braquage terminé', 'success')
    end
end)

RegisterNetEvent('core_creator:robberies:join', function(robberyId)
    local src = source
    robberyId = tonumber(robberyId)
    local state = activeRobberies[robberyId]
    if not state then return end
    state.players[src] = true
end)

AddEventHandler('core_creator:robberies:dispatch', function(robberyId, coords, data)
    local system = Bridge.Dispatch
    local message = (data and data.dispatchMessage) or 'Braquage en cours'
    if system == 'ps-dispatch' then
        -- External: clients typically trigger; we broadcast a generic event
        TriggerClientEvent('core_creator:robberies:policeAlert', -1, { id = robberyId, coords = coords, message = message })
    else
        TriggerClientEvent('core_creator:robberies:policeAlert', -1, { id = robberyId, coords = coords, message = message })
    end
end)

RegisterNetEvent('core_creator:robberies:requestSync', function()
    TriggerClientEvent('core_creator:robberies:sync', source, Database.GetAll(MODULE, true), activeRobberies)
end)

AddEventHandler('core_creator:databaseReady', function()
    Wait(100)
    TriggerClientEvent('core_creator:robberies:sync', -1, Database.GetAll(MODULE, true), activeRobberies)
end)

AddEventHandler('core_creator:entityChanged', function(moduleName)
    if moduleName ~= MODULE then return end
    TriggerClientEvent('core_creator:robberies:sync', -1, Database.GetAll(MODULE, true), activeRobberies)
end)

AddEventHandler('playerDropped', function()
    local src = source
    for id, state in pairs(activeRobberies) do
        state.players[src] = nil
        if state.starter == src then
            local remaining = false
            for _ in pairs(state.players) do remaining = true break end
            if not remaining then
                activeRobberies[id] = nil
                TriggerClientEvent('core_creator:robberies:cancelled', -1, id)
            end
        end
    end
    playerCooldown[src] = nil
end)
