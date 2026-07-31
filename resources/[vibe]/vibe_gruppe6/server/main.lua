local Points = Gruppe6Points

local runs = {}
local cooldowns = {}

local function canWork(src)
    if not Config.Job then return true end
    local job = exports.vibe_api:GetJob(src)
    if not job or job.name ~= Config.Job then
        exports.vibe_api:Notify(src, 'Gruppe 6', 'Métier Gruppe 6 requis.', 'error')
        return false
    end
    if Config.RequireDuty and not job.onduty then
        exports.vibe_api:Notify(src, 'Gruppe 6', 'Tu dois être en service.', 'error')
        return false
    end
    return true
end

local function rollPay(pointType)
    local range = Config.PayByType[pointType]
    if not range then return 500 end
    return math.random(range.min, range.max)
end

local function shuffle(list)
    for i = #list, 2, -1 do
        local j = math.random(1, i)
        list[i], list[j] = list[j], list[i]
    end
    return list
end

local function buildRoute()
    local enabled = Points.GetEnabled()
    if #enabled < Config.Route.minStops then return nil end

    local byType = {}
    for i = 1, #enabled do
        local p = enabled[i]
        byType[p.type] = byType[p.type] or {}
        byType[p.type][#byType[p.type] + 1] = p
    end

    local route = {}
    local usedIds = {}

    for pointType in pairs(byType) do
        local pool = shuffle({ table.unpack(byType[pointType]) })
        if pool[1] and not usedIds[pool[1].id] then
            route[#route + 1] = pool[1]
            usedIds[pool[1].id] = true
        end
    end

    local remaining = {}
    for i = 1, #enabled do
        local p = enabled[i]
        if not usedIds[p.id] then
            remaining[#remaining + 1] = p
        end
    end
    remaining = shuffle(remaining)

    local target = math.random(Config.Route.minStops, math.min(Config.Route.maxStops, #enabled))
    for i = 1, #remaining do
        if #route >= target then break end
        route[#route + 1] = remaining[i]
    end

    if #route < Config.Route.minStops then return nil end
    return shuffle(route)
end

local function clearRun(src)
    runs[src] = nil
    TriggerClientEvent('vibe_gruppe6:client:stop', src)
end

local function depositSociety(amount, reason)
    exports['Renewed-Banking']:addAccountMoney(Config.Society, amount)
    exports['Renewed-Banking']:handleTransaction(
        Config.Society,
        'Gruppe 6',
        amount,
        reason or 'Convoi de fonds',
        'Gruppe 6',
        Config.Society,
        'deposit'
    )
end

lib.callback.register('vibe_gruppe6:server:getPoints', function()
    return Points.Load()
end)

RegisterNetEvent('vibe_gruppe6:server:start', function()
    local src = source
    if runs[src] then
        exports.vibe_api:Notify(src, 'Gruppe 6', 'Tournée déjà en cours.', 'error')
        return
    end
    if not canWork(src) then return end

    local now = os.time()
    if cooldowns[src] and cooldowns[src] > now then
        local wait = cooldowns[src] - now
        exports.vibe_api:Notify(src, 'Gruppe 6', ('Attends %ss avant une nouvelle tournée.'):format(wait), 'error')
        return
    end

    local route = buildRoute()
    if not route then
        exports.vibe_api:Notify(src, 'Gruppe 6', 'Pas assez de points actifs pour une tournée.', 'error')
        return
    end

    for i = 1, #route do
        route[i].pay = rollPay(route[i].type)
    end

    runs[src] = {
        route = route,
        index = 1,
        bags = 0,
    }

    TriggerClientEvent('vibe_gruppe6:client:begin', src, route)
end)

RegisterNetEvent('vibe_gruppe6:server:pickup', function(pointId)
    local src = source
    local run = runs[src]
    if not run then return end

    local current = run.route[run.index]
    if not current or current.id ~= pointId then
        exports.vibe_api:Notify(src, 'Gruppe 6', 'Ce n\'est pas l\'arrêt prévu.', 'error')
        return
    end

    if not exports.vibe_api:DistCheck(src, current.coords, Config.Pickup.radius + 2.0) then return end

    local added = exports.ox_inventory:AddItem(src, Config.BagItem, 1, {
        type = current.type,
        value = current.pay,
        label = current.label,
        description = ('Sac de billets — %s'):format(current.label),
    })

    if not added then
        exports.vibe_api:Notify(src, 'Gruppe 6', 'Inventaire plein.', 'error')
        return
    end

    run.bags = run.bags + 1
    run.index = run.index + 1

    if run.index > #run.route then
        TriggerClientEvent('vibe_gruppe6:client:returnDepot', src)
        exports.vibe_api:Notify(src, 'Gruppe 6', 'Tous les arrêts effectués. Retourne au dépôt.', 'success')
    else
        TriggerClientEvent('vibe_gruppe6:client:nextStop', src, run.index)
    end
end)

RegisterNetEvent('vibe_gruppe6:server:deposit', function()
    local src = source
    local run = runs[src]
    if not run then return end
    if run.index <= #run.route then
        exports.vibe_api:Notify(src, 'Gruppe 6', 'Termine d\'abord tous les arrêts.', 'error')
        return
    end
    if not exports.vibe_api:DistCheck(src, Config.Depot.coords, Config.Depot.radius + 3.0) then return end

    local search = exports.ox_inventory:Search(src, 'slots', Config.BagItem) or {}
    local items = search[Config.BagItem] or {}
    if #items == 0 then
        exports.vibe_api:Notify(src, 'Gruppe 6', 'Aucun sac de billets à déposer.', 'error')
        return
    end

    local total = 0
    local count = 0
    for i = 1, #items do
        local slot = items[i]
        local value = (slot.metadata and slot.metadata.value) or 500
        if exports.ox_inventory:RemoveItem(src, Config.BagItem, 1, slot.metadata, slot.slot) then
            total = total + value
            count = count + 1
        end
    end

    if count == 0 then
        exports.vibe_api:Notify(src, 'Gruppe 6', 'Impossible de déposer les sacs.', 'error')
        return
    end

    depositSociety(total, ('Convoi — %s sac(s)'):format(count))
    cooldowns[src] = os.time() + Config.Cooldown
    clearRun(src)

    exports.vibe_api:Notify(
        src,
        'Gruppe 6',
        ('Convoi terminé — %s sac(s) déposés, $%s versés à la société.'):format(count, total),
        'success'
    )
end)

RegisterNetEvent('vibe_gruppe6:server:cancel', function()
    local src = source
    local search = exports.ox_inventory:Search(src, 'slots', Config.BagItem) or {}
    local items = search[Config.BagItem] or {}
    for i = 1, #items do
        local slot = items[i]
        exports.ox_inventory:RemoveItem(src, Config.BagItem, 1, slot.metadata, slot.slot)
    end
    clearRun(src)
    exports.vibe_api:Notify(src, 'Gruppe 6', 'Tournée annulée.', 'inform')
end)

AddEventHandler('playerDropped', function()
    runs[source] = nil
    cooldowns[source] = nil
end)

CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `vibe_gruppe6_points` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `point_type` VARCHAR(32) NOT NULL,
            `label` VARCHAR(128) NOT NULL,
            `x` DOUBLE NOT NULL,
            `y` DOUBLE NOT NULL,
            `z` DOUBLE NOT NULL,
            `enabled` TINYINT(1) NOT NULL DEFAULT 1,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_type` (`point_type`),
            KEY `idx_enabled` (`enabled`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    Points.SeedDefaults()
    Wait(500)
    TriggerClientEvent('vibe_gruppe6:client:refreshPoints', -1, Points.Load())
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    Wait(1000)
    TriggerClientEvent('vibe_gruppe6:client:refreshPoints', -1, Points.Load())
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    local src = player and player.PlayerData and player.PlayerData.source
    if not src then return end
    TriggerClientEvent('vibe_gruppe6:client:refreshPoints', src, Points.Load())
end)
