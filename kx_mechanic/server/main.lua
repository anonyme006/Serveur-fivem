local cooldowns = {}
local busyPlayers = {}
local pendingInvoices = {}
local liftStates = {}

local function getPlayer(source)
    return exports.qbx_core:GetPlayer(source)
end

local function getPlayerName(player)
    local info = player.PlayerData.charinfo or {}
    local first = info.firstname or 'Inconnu'
    local last = info.lastname or ''
    return (first .. ' ' .. last):gsub('%s+$', '')
end

local function getJobData(player)
    local job = player and player.PlayerData and player.PlayerData.job
    if not job then return nil end
    return {
        name = job.name,
        grade = job.grade and (job.grade.level or job.grade) or 0,
        onduty = job.onduty == true,
        label = job.label,
    }
end

function IsMechanic(source)
    local player = getPlayer(source)
    if not player then return false, nil end
    local job = getJobData(player)
    if not job or job.name ~= Config.Job then return false, player end
    if Config.RequireOnDuty and not job.onduty then return false, player end
    return true, player, job
end

function HasMechanicPermission(source, permission)
    local ok, player, job = IsMechanic(source)
    if not ok then return false, player, job end
    if not Utils.HasPermission(job.grade, permission) then return false, player, job end
    return true, player, job
end

local function checkCooldown(source, key)
    local now = GetGameTimer()
    local bucket = cooldowns[source]
    if not bucket then
        cooldowns[source] = {}
        bucket = cooldowns[source]
    end
    local last = bucket[key] or 0
    if now - last < Config.ActionCooldown then
        return false
    end
    bucket[key] = now
    return true
end

local function setBusy(source, state)
    busyPlayers[source] = state and true or nil
end

local function isBusy(source)
    return busyPlayers[source] == true
end

local function removeItems(source, items)
    for i = 1, #items do
        local entry = items[i]
        local count = exports.ox_inventory:GetItemCount(source, entry.item) or 0
        if count < entry.count then
            return false, entry.item
        end
    end

    for i = 1, #items do
        local entry = items[i]
        local removed = exports.ox_inventory:RemoveItem(source, entry.item, entry.count)
        if not removed then
            return false, entry.item
        end
    end

    return true
end

local function addSocietyMoney(amount)
    if not Config.UseSocietyFunds or amount <= 0 then return end
    local ok = pcall(function()
        exports['Renewed-Banking']:addAccountMoney(Config.SocietyAccount, amount)
    end)
    if ok then return end
    pcall(function()
        exports.qbx_management:AddMoney(Config.SocietyAccount, amount)
    end)
end

local function removeSocietyMoney(amount)
    if amount <= 0 then return true end
    local ok, result = pcall(function()
        return exports['Renewed-Banking']:removeAccountMoney(Config.SocietyAccount, amount)
    end)
    if ok and result ~= false then return true end

    ok, result = pcall(function()
        return exports.qbx_management:RemoveMoney(Config.SocietyAccount, amount)
    end)
    if ok and result ~= false then return true end

    return true
end

local function registerStash()
    local stash = Config.Locations.stash
    exports.ox_inventory:RegisterStash(stash.id, stash.label, stash.slots, stash.weight, false)
end

CreateThread(function()
    Database.Init()
    registerStash()

    for i = 1, #Config.Lifts do
        local lift = Config.Lifts[i]
        liftStates[lift.id] = {
            id = lift.id,
            raised = false,
            locked = false,
            netId = nil,
            plate = nil,
        }
    end

    GlobalState.kx_mechanic_lifts = liftStates
    print('^2[kx_mechanic]^7 Resource started successfully')
end)

AddEventHandler('playerDropped', function()
    local src = source
    cooldowns[src] = nil
    busyPlayers[src] = nil
end)

lib.callback.register('kx_mechanic:server:getPlayerJob', function(source)
    local player = getPlayer(source)
    if not player then return nil end
    return getJobData(player)
end)

lib.callback.register('kx_mechanic:server:canAccess', function(source, permission)
    local ok = HasMechanicPermission(source, permission or 'diagnose')
    return ok
end)

lib.callback.register('kx_mechanic:server:getNearbyPlayers', function(source)
    local ok = HasMechanicPermission(source, 'billing')
    if not ok then return {} end

    local myPed = GetPlayerPed(source)
    local myCoords = GetEntityCoords(myPed)
    local players = {}

    for _, playerId in ipairs(GetPlayers()) do
        local id = tonumber(playerId)
        if id and id ~= source then
            local ped = GetPlayerPed(id)
            if ped and ped ~= 0 then
                local coords = GetEntityCoords(ped)
                if #(myCoords - coords) <= 10.0 then
                    local target = getPlayer(id)
                    if target then
                        players[#players + 1] = {
                            id = id,
                            name = getPlayerName(target),
                            citizenid = target.PlayerData.citizenid,
                        }
                    end
                end
            end
        end
    end

    return players
end)

lib.callback.register('kx_mechanic:server:getMenuData', function(source)
    local ok, player, job = IsMechanic(source)
    if not ok then return nil end

    local categories = {}
    for i = 1, #Config.Categories do
        local cat = Config.Categories[i]
        local services = {}
        for j = 1, #Config.Services do
            local service = Config.Services[j]
            if service.category == cat.id then
                services[#services + 1] = Utils.BuildServicePayload(service.id)
            end
        end
        categories[#categories + 1] = {
            id = cat.id,
            label = cat.label,
            icon = cat.icon,
            services = services,
        }
    end

    return {
        job = job,
        playerName = getPlayerName(player),
        categories = categories,
        performance = Config.PerformanceMods,
        tireTypes = Config.TireTypes,
        paintColors = Config.PaintColors,
        wheelOptions = Config.WheelOptions,
        permissions = {
            diagnose = Utils.HasPermission(job.grade, 'diagnose'),
            repair = Utils.HasPermission(job.grade, 'repair'),
            clean = Utils.HasPermission(job.grade, 'clean'),
            tires = Utils.HasPermission(job.grade, 'tires'),
            maintenance = Utils.HasPermission(job.grade, 'maintenance'),
            body = Utils.HasPermission(job.grade, 'body'),
            performance = Utils.HasPermission(job.grade, 'performance'),
            billing = Utils.HasPermission(job.grade, 'billing'),
            stock = Utils.HasPermission(job.grade, 'stock'),
            orders = Utils.HasPermission(job.grade, 'orders'),
            employees = Utils.HasPermission(job.grade, 'employees'),
            dashboard = Utils.HasPermission(job.grade, 'dashboard'),
            management = Utils.HasPermission(job.grade, 'management'),
            lift = Utils.HasPermission(job.grade, 'lift'),
        },
        config = {
            enableBilling = Config.EnableBilling,
            enablePerformance = Config.EnablePerformance,
            enableMaintenance = Config.EnableMaintenance,
            enableOrders = Config.EnableOrders,
            enableDashboard = Config.EnableDashboard,
        },
    }
end)

exports('IsMechanic', IsMechanic)
exports('HasMechanicPermission', HasMechanicPermission)
exports('GetLiftStates', function()
    return liftStates
end)

_G.KXMechanicServer = {
    getPlayer = getPlayer,
    getPlayerName = getPlayerName,
    getJobData = getJobData,
    checkCooldown = checkCooldown,
    setBusy = setBusy,
    isBusy = isBusy,
    removeItems = removeItems,
    addSocietyMoney = addSocietyMoney,
    removeSocietyMoney = removeSocietyMoney,
    liftStates = liftStates,
    pendingInvoices = pendingInvoices,
}