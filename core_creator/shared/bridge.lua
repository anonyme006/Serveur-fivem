Bridge = Bridge or {}

Bridge.Framework = 'standalone'
Bridge.Inventory = 'none'
Bridge.Target = 'none'
Bridge.Notify = 'native'
Bridge.Progress = 'native'
Bridge.Dispatch = 'none'
Bridge.Fuel = 'none'
Bridge.Keys = 'none'

local FrameworkObj = nil

local function detectFramework()
    local configured = Config.Framework
    if configured and configured ~= 'auto' then
        return configured
    end
    if CoreUtils.ResourceStarted('qbx_core') then return 'qbox' end
    if CoreUtils.ResourceStarted('qb-core') then return 'qbcore' end
    if CoreUtils.ResourceStarted('es_extended') then return 'esx' end
    return 'standalone'
end

local function detectInventory()
    local configured = Config.Inventory
    if configured and configured ~= 'auto' then return configured end
    if CoreUtils.ResourceStarted('ox_inventory') then return 'ox_inventory' end
    if CoreUtils.ResourceStarted('qs-inventory') then return 'qs-inventory' end
    if CoreUtils.ResourceStarted('qb-inventory') then return 'qb-inventory' end
    if Bridge.Framework == 'esx' then return 'esx' end
    return 'none'
end

local function detectTarget()
    local configured = Config.Target
    if configured and configured ~= 'auto' then return configured end
    if CoreUtils.ResourceStarted('ox_target') then return 'ox_target' end
    if CoreUtils.ResourceStarted('qb-target') then return 'qb-target' end
    return 'marker'
end

local function detectNotify()
    local configured = Config.Notify
    if configured and configured ~= 'auto' then return configured end
    if CoreUtils.ResourceStarted('ox_lib') then return 'ox_lib' end
    if Bridge.Framework == 'esx' then return 'esx' end
    if Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then return 'qb' end
    return 'native'
end

local function detectProgress()
    local configured = Config.Progressbar
    if configured and configured ~= 'auto' then return configured end
    if CoreUtils.ResourceStarted('ox_lib') then return 'ox_lib' end
    if Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then return 'qb' end
    return 'native'
end

local function detectDispatch()
    local configured = Config.Dispatch
    if configured and configured ~= 'auto' then return configured end
    return CoreUtils.FirstStarted({ 'ps-dispatch', 'cd_dispatch', 'qs-dispatch' }) or 'none'
end

local function detectFuel()
    local configured = Config.Fuel
    if configured and configured ~= 'auto' then return configured end
    return CoreUtils.FirstStarted({ 'ox_fuel', 'LegacyFuel', 'cdn-fuel' }) or 'none'
end

local function detectKeys()
    local configured = Config.VehicleKeys
    if configured and configured ~= 'auto' then return configured end
    return CoreUtils.FirstStarted({ 'wasabi_carlock', 'qs-vehiclekeys', 'qb-vehiclekeys', 'qbx_vehiclekeys' }) or 'core_creator'
end

------------------------------------------------------------
-- Framework init
------------------------------------------------------------
function Bridge.Init()
    Bridge.Framework = detectFramework()
    Bridge.Inventory = detectInventory()
    Bridge.Target = detectTarget()
    Bridge.Notify = detectNotify()
    Bridge.Progress = detectProgress()
    Bridge.Dispatch = detectDispatch()
    Bridge.Fuel = detectFuel()
    Bridge.Keys = detectKeys()

    if Bridge.Framework == 'esx' then
        if CoreUtils.IsServer() then
            FrameworkObj = exports['es_extended']:getSharedObject()
        else
            FrameworkObj = exports['es_extended']:getSharedObject()
        end
    elseif Bridge.Framework == 'qbcore' then
        FrameworkObj = exports['qb-core']:GetCoreObject()
    elseif Bridge.Framework == 'qbox' then
        FrameworkObj = exports['qb-core'] and exports['qb-core']:GetCoreObject() or nil
        if not FrameworkObj and exports.qbx_core then
            FrameworkObj = { Functions = {}, Shared = {} }
        end
    end

    CoreUtils.Print(('Framework=%s Inventory=%s Target=%s Notify=%s Keys=%s'):format(
        Bridge.Framework, Bridge.Inventory, Bridge.Target, Bridge.Notify, Bridge.Keys
    ))
end

function Bridge.GetObject()
    return FrameworkObj
end

------------------------------------------------------------
-- Player helpers (server)
------------------------------------------------------------
function Bridge.GetPlayer(src)
    if not CoreUtils.IsServer() then return nil end
    if Bridge.Framework == 'esx' then
        return FrameworkObj and FrameworkObj.GetPlayerFromId(src) or nil
    elseif Bridge.Framework == 'qbcore' then
        return FrameworkObj and FrameworkObj.Functions.GetPlayer(src) or nil
    elseif Bridge.Framework == 'qbox' then
        if FrameworkObj and FrameworkObj.Functions and FrameworkObj.Functions.GetPlayer then
            return FrameworkObj.Functions.GetPlayer(src)
        end
        return exports.qbx_core:GetPlayer(src)
    end
    return { source = src }
end

function Bridge.GetIdentifier(src)
    local player = Bridge.GetPlayer(src)
    if Bridge.Framework == 'esx' and player then
        return player.identifier
    elseif (Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox') and player then
        return player.PlayerData and player.PlayerData.citizenid or nil
    end
    for _, idType in ipairs({ 'license2', 'license', 'fivem', 'steam' }) do
        local id = GetPlayerIdentifierByType and GetPlayerIdentifierByType(src, idType)
        if id and id ~= '' then return id end
    end
    local ids = GetPlayerIdentifiers(src) or {}
    return ids[1]
end

function Bridge.GetName(src)
    local player = Bridge.GetPlayer(src)
    if Bridge.Framework == 'esx' and player then
        return player.getName and player.getName() or GetPlayerName(src)
    elseif (Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox') and player then
        local char = player.PlayerData and player.PlayerData.charinfo
        if char then
            return (char.firstname or '') .. ' ' .. (char.lastname or '')
        end
    end
    return GetPlayerName(src) or ('player_' .. tostring(src))
end

function Bridge.GetJob(src)
    local player = Bridge.GetPlayer(src)
    if not player then return nil, 0 end
    if Bridge.Framework == 'esx' then
        local job = player.getJob and player.getJob() or player.job
        if not job then return nil, 0 end
        return job.name, tonumber(job.grade) or 0
    elseif Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
        local job = player.PlayerData and player.PlayerData.job
        if not job then return nil, 0 end
        local grade = job.grade and (job.grade.level or job.grade) or 0
        return job.name, tonumber(grade) or 0
    end
    return nil, 0
end

function Bridge.GetGang(src)
    local player = Bridge.GetPlayer(src)
    if not player then return nil, 0 end
    if Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
        local gang = player.PlayerData and player.PlayerData.gang
        if not gang then return nil, 0 end
        local grade = gang.grade and (gang.grade.level or gang.grade) or 0
        return gang.name, tonumber(grade) or 0
    end
    -- ESX / standalone: gangs handled by core_creator tables
    return nil, 0
end

function Bridge.IsFrameworkAdmin(src)
    local groups = Config.Permissions.frameworkGroups[Bridge.Framework] or {}
    if Bridge.Framework == 'esx' then
        local player = Bridge.GetPlayer(src)
        if not player then return false end
        local group = player.getGroup and player.getGroup() or 'user'
        return CoreUtils.Includes(groups, group)
    elseif Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
        local player = Bridge.GetPlayer(src)
        if not player then return false end
        local perms = player.PlayerData and player.PlayerData.permission
            or (player.PlayerData and player.PlayerData.group)
        if type(perms) == 'string' then
            return CoreUtils.Includes(groups, perms)
        end
        -- QB permission check via IsPlayerAceAllowed often used instead
        for i = 1, #groups do
            if IsPlayerAceAllowed(src, groups[i]) or IsPlayerAceAllowed(src, 'group.' .. groups[i]) then
                return true
            end
        end
        if FrameworkObj and FrameworkObj.Functions and FrameworkObj.Functions.HasPermission then
            for i = 1, #groups do
                if FrameworkObj.Functions.HasPermission(src, groups[i]) then
                    return true
                end
            end
        end
    end
    return IsPlayerAceAllowed(src, 'command') or IsPlayerAceAllowed(src, 'group.admin')
end

------------------------------------------------------------
-- Money
------------------------------------------------------------
function Bridge.GetMoney(src, account)
    account = account or 'money'
    local player = Bridge.GetPlayer(src)
    if not player then return 0 end

    if Bridge.Framework == 'esx' then
        if account == 'money' or account == 'cash' then
            return player.getMoney and player.getMoney() or 0
        end
        local acc = player.getAccount and player.getAccount(account)
        return acc and acc.money or 0
    elseif Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
        local money = player.PlayerData and player.PlayerData.money or {}
        if account == 'money' then account = 'cash' end
        return money[account] or 0
    end
    return 0
end

function Bridge.RemoveMoney(src, account, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return true end
    local player = Bridge.GetPlayer(src)
    if not player then return false end
    reason = reason or 'core_creator'

    if Bridge.Framework == 'esx' then
        if account == 'money' or account == 'cash' then
            if player.getMoney() < amount then return false end
            player.removeMoney(amount, reason)
            return true
        end
        local acc = player.getAccount(account)
        if not acc or acc.money < amount then return false end
        player.removeAccountMoney(account, amount, reason)
        return true
    elseif Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
        if account == 'money' then account = 'cash' end
        return player.Functions.RemoveMoney(account, amount, reason) == true
            or player.Functions.RemoveMoney(account, amount, reason)
    end
    return false
end

function Bridge.AddMoney(src, account, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return true end
    local player = Bridge.GetPlayer(src)
    if not player then return false end
    reason = reason or 'core_creator'

    if Bridge.Framework == 'esx' then
        if account == 'money' or account == 'cash' then
            player.addMoney(amount, reason)
            return true
        end
        player.addAccountMoney(account, amount, reason)
        return true
    elseif Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
        if account == 'money' then account = 'cash' end
        player.Functions.AddMoney(account, amount, reason)
        return true
    end
    return false
end

------------------------------------------------------------
-- Inventory
------------------------------------------------------------
function Bridge.HasItem(src, item, count)
    count = tonumber(count) or 1
    item = tostring(item or '')
    if item == '' then return false end

    if Bridge.Inventory == 'ox_inventory' then
        local n = exports.ox_inventory:Search(src, 'count', item) or 0
        return n >= count
    end

    local player = Bridge.GetPlayer(src)
    if Bridge.Framework == 'esx' and player then
        local invItem = player.getInventoryItem and player.getInventoryItem(item)
        return invItem and (invItem.count or 0) >= count
    elseif (Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox') and player then
        local invItem = player.Functions.GetItemByName(item)
        return invItem and (invItem.amount or invItem.count or 0) >= count
    end
    return false
end

function Bridge.AddItem(src, item, count, metadata)
    count = math.floor(tonumber(count) or 1)
    if count <= 0 or not item then return false end

    if Bridge.Inventory == 'ox_inventory' then
        return exports.ox_inventory:AddItem(src, item, count, metadata) and true or false
    end

    local player = Bridge.GetPlayer(src)
    if Bridge.Framework == 'esx' and player then
        player.addInventoryItem(item, count)
        return true
    elseif (Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox') and player then
        return player.Functions.AddItem(item, count, false, metadata) and true or false
    end
    return false
end

function Bridge.RemoveItem(src, item, count, metadata)
    count = math.floor(tonumber(count) or 1)
    if count <= 0 or not item then return false end

    if Bridge.Inventory == 'ox_inventory' then
        return exports.ox_inventory:RemoveItem(src, item, count, metadata) and true or false
    end

    local player = Bridge.GetPlayer(src)
    if Bridge.Framework == 'esx' and player then
        player.removeInventoryItem(item, count)
        return true
    elseif (Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox') and player then
        return player.Functions.RemoveItem(item, count) and true or false
    end
    return false
end

function Bridge.CanCarryItem(src, item, count)
    count = math.floor(tonumber(count) or 1)
    if Bridge.Inventory == 'ox_inventory' then
        return exports.ox_inventory:CanCarryItem(src, item, count) ~= false
    end
    return true
end

------------------------------------------------------------
-- Jobs / Gangs framework persistence helpers
------------------------------------------------------------
function Bridge.EnsureJob(jobName, label, grades)
    if Bridge.Framework == 'esx' then
        -- ESX jobs typically live in `jobs` + `job_grades`
        MySQL.insert.await('INSERT IGNORE INTO jobs (name, label) VALUES (?, ?)', { jobName, label })
        for grade, data in pairs(grades or {}) do
            MySQL.insert.await(
                'INSERT IGNORE INTO job_grades (job_name, grade, name, label, salary, skin_male, skin_female) VALUES (?, ?, ?, ?, ?, ?, ?)',
                {
                    jobName,
                    tonumber(grade) or 0,
                    data.name or ('grade_' .. grade),
                    data.label or data.name or tostring(grade),
                    tonumber(data.salary) or 0,
                    json.encode(data.skin_male or {}),
                    json.encode(data.skin_female or {}),
                }
            )
        end
        if FrameworkObj and FrameworkObj.RefreshJobs then
            FrameworkObj.RefreshJobs()
        end
        return true
    elseif Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
        -- QB/Qbox jobs are usually Shared.Jobs; we store in core_creator and expose via export
        return true
    end
    return true
end

function Bridge.SetPlayerJob(src, jobName, grade)
    local player = Bridge.GetPlayer(src)
    if not player then return false end
    grade = tonumber(grade) or 0
    if Bridge.Framework == 'esx' then
        player.setJob(jobName, grade)
        return true
    elseif Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
        player.Functions.SetJob(jobName, grade)
        return true
    end
    return false
end

function Bridge.SetPlayerGang(src, gangName, grade)
    local player = Bridge.GetPlayer(src)
    if not player then return false end
    grade = tonumber(grade) or 0
    if Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
        if player.Functions.SetGang then
            player.Functions.SetGang(gangName, grade)
            return true
        end
    end
    return false
end

------------------------------------------------------------
-- Owned vehicles
------------------------------------------------------------
function Bridge.InsertOwnedVehicle(owner, plate, props, vehicleType, stored)
    vehicleType = vehicleType or 'car'
    stored = stored and 1 or 0
    local encoded = type(props) == 'string' and props or json.encode(props or {})

    if Bridge.Framework == 'esx' then
        MySQL.insert.await(
            'INSERT INTO owned_vehicles (owner, plate, vehicle, type, stored) VALUES (?, ?, ?, ?, ?)',
            { owner, plate, encoded, vehicleType, stored }
        )
        return true
    elseif Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
        MySQL.insert.await(
            'INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            {
                '',
                owner,
                props.modelName or props.vehicle or 'unknown',
                props.model or joaat(props.modelName or 'adder'),
                encoded,
                plate,
                'pillboxgarage',
                stored,
            }
        )
        return true
    end

    MySQL.insert.await(
        'INSERT INTO core_creator_owned_vehicles (owner, plate, vehicle, type, stored) VALUES (?, ?, ?, ?, ?)',
        { owner, plate, encoded, vehicleType, stored }
    )
    return true
end

------------------------------------------------------------
-- Notifications / progress (client-facing helpers triggered via event)
------------------------------------------------------------
function Bridge.Notify(srcOrMessage, messageOrType, typeOrDuration, maybeDuration)
    if CoreUtils.IsServer() then
        local src, message, nType, duration = srcOrMessage, messageOrType, typeOrDuration, maybeDuration
        TriggerClientEvent('core_creator:notify', src, message, nType or 'inform', duration or 5000)
        return
    end
    local message, nType, duration = srcOrMessage, messageOrType, typeOrDuration
    if Bridge.Notify == 'ox_lib' then
        exports.ox_lib:notify({ title = 'Core Creator', description = message, type = nType or 'inform', duration = duration or 5000 })
    elseif Bridge.Notify == 'esx' and FrameworkObj then
        FrameworkObj.ShowNotification(message)
    elseif Bridge.Notify == 'qb' and FrameworkObj then
        FrameworkObj.Functions.Notify(message, nType or 'primary', duration or 5000)
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, true)
    end
end

CreateThread(function()
    Wait(100)
    Bridge.Init()
end)
