local Points = Gruppe6Points

local runs = {}
local cooldowns = {}

local function notify(src, msg, nType)
    TriggerClientEvent('esx_gruppe6:notify', src, 'Gruppe 6', msg, nType or 'inform')
end

local function distCheck(src, coords, maxDist)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    local pcoords = GetEntityCoords(ped)
    return #(pcoords - vector3(coords.x, coords.y, coords.z)) <= (maxDist or 5.0)
end

local function canWork(xPlayer)
    if not Config.Job then return true end
    if not xPlayer or not xPlayer.job or xPlayer.job.name ~= Config.Job then
        notify(xPlayer.source, L('job_required'), 'error')
        return false
    end
    if Config.RequireDuty and xPlayer.job.onDuty == false then
        notify(xPlayer.source, 'Tu dois être en service.', 'error')
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

    for _, pool in pairs(byType) do
        local shuffled = shuffle({ table.unpack(pool) })
        if shuffled[1] and not usedIds[shuffled[1].id] then
            route[#route + 1] = shuffled[1]
            usedIds[shuffled[1].id] = true
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
    TriggerClientEvent('esx_gruppe6:client:stop', src)
end

ESX.RegisterServerCallback('esx_gruppe6:getPoints', function(_, cb)
    cb(Points.Load())
end)

RegisterNetEvent('esx_gruppe6:server:start', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if runs[src] then
        notify(src, L('run_active'), 'error')
        return
    end
    if not canWork(xPlayer) then return end

    local now = os.time()
    if cooldowns[src] and cooldowns[src] > now then
        notify(src, L('cooldown', cooldowns[src] - now), 'error')
        return
    end

    local route = buildRoute()
    if not route then
        notify(src, L('not_enough_points'), 'error')
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

    TriggerClientEvent('esx_gruppe6:client:begin', src, route)
end)

RegisterNetEvent('esx_gruppe6:server:pickup', function(pointId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local run = runs[src]
    if not run then return end

    local current = run.route[run.index]
    if not current or current.id ~= pointId then
        notify(src, L('wrong_stop'), 'error')
        return
    end

    if not distCheck(src, current.coords, Config.Pickup.radius + 2.0) then return end

    local added = exports.ox_inventory:AddItem(src, Config.BagItem, 1, {
        type = current.type,
        value = current.pay,
        label = current.label,
        description = ('Sac de billets — %s'):format(current.label),
    })

    if not added then
        notify(src, L('inventory_full'), 'error')
        return
    end

    run.bags = run.bags + 1
    run.index = run.index + 1

    if run.index > #run.route then
        TriggerClientEvent('esx_gruppe6:client:returnDepot', src)
        notify(src, L('all_stops_done'), 'success')
    else
        TriggerClientEvent('esx_gruppe6:client:nextStop', src, run.index)
    end
end)

RegisterNetEvent('esx_gruppe6:server:deposit', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local run = runs[src]
    if not run then return end
    if run.index <= #run.route then
        notify(src, L('finish_stops_first'), 'error')
        return
    end
    if not distCheck(src, Config.Depot.coords, Config.Depot.radius + 3.0) then return end

    local search = exports.ox_inventory:Search(src, 'slots', Config.BagItem) or {}
    local items = search[Config.BagItem] or {}
    if #items == 0 then
        notify(src, L('no_bags'), 'error')
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
        notify(src, L('deposit_failed'), 'error')
        return
    end

    Gruppe6Society.AddMoney(total)
    cooldowns[src] = os.time() + Config.Cooldown
    clearRun(src)
    notify(src, L('run_done', count, total), 'success')
end)

RegisterNetEvent('esx_gruppe6:server:cancel', function()
    local src = source
    local search = exports.ox_inventory:Search(src, 'slots', Config.BagItem) or {}
    local items = search[Config.BagItem] or {}
    for i = 1, #items do
        local slot = items[i]
        exports.ox_inventory:RemoveItem(src, Config.BagItem, 1, slot.metadata, slot.slot)
    end
    clearRun(src)
    notify(src, L('run_cancelled'), 'inform')
end)

AddEventHandler('playerDropped', function()
    runs[source] = nil
    cooldowns[source] = nil
end)

CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `esx_gruppe6_points` (
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
    TriggerClientEvent('esx_gruppe6:client:refreshPoints', -1, Points.Load())
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    Wait(1000)
    TriggerClientEvent('esx_gruppe6:client:refreshPoints', -1, Points.Load())
end)

RegisterNetEvent('esx:playerLoaded', function(playerId)
    TriggerClientEvent('esx_gruppe6:client:refreshPoints', playerId, Points.Load())
end)
