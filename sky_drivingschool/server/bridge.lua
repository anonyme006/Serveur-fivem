SkyDS = SkyDS or {}
SkyDS.Bridge = SkyDS.Bridge or {}

local Framework = nil
local FrameworkName = 'unknown'

local function detectFramework()
    local pref = Config.Framework or 'auto'
    if pref == 'qbox' or (pref == 'auto' and GetResourceState('qbx_core') == 'started') then
        FrameworkName = 'qbox'
        return 'qbox'
    end
    if pref == 'qbcore' or (pref == 'auto' and GetResourceState('qb-core') == 'started') then
        FrameworkName = 'qbcore'
        QBCore = exports['qb-core']:GetCoreObject()
        return 'qbcore'
    end
    if pref == 'esx' or (pref == 'auto' and (GetResourceState('es_extended') == 'started')) then
        FrameworkName = 'esx'
        ESX = exports['es_extended']:getSharedObject()
        return 'esx'
    end
    FrameworkName = 'standalone'
    return 'standalone'
end

CreateThread(function()
    Wait(100)
    Framework = detectFramework()
    SkyDS.Debug(('Framework bridge: %s'):format(FrameworkName))
end)

function SkyDS.Bridge.GetName()
    if not Framework then Framework = detectFramework() end
    return FrameworkName
end

---@param src number
---@return table|nil
function SkyDS.Bridge.GetPlayer(src)
    local fw = SkyDS.Bridge.GetName()
    if fw == 'qbox' then
        return exports.qbx_core:GetPlayer(src)
    elseif fw == 'qbcore' then
        return QBCore and QBCore.Functions.GetPlayer(src) or nil
    elseif fw == 'esx' then
        return ESX and ESX.GetPlayerFromId(src) or nil
    end
    return nil
end

---@param citizenid string
---@return table|nil
function SkyDS.Bridge.GetPlayerByCitizenId(citizenid)
    local fw = SkyDS.Bridge.GetName()
    if fw == 'qbox' then
        return exports.qbx_core:GetPlayerByCitizenId(citizenid)
    elseif fw == 'qbcore' then
        return QBCore and QBCore.Functions.GetPlayerByCitizenId(citizenid) or nil
    end
    return nil
end

---@param src number
---@return string|nil
function SkyDS.Bridge.GetCitizenId(src)
    local player = SkyDS.Bridge.GetPlayer(src)
    if not player then return nil end
    local fw = SkyDS.Bridge.GetName()
    if fw == 'qbox' or fw == 'qbcore' then
        return player.PlayerData and player.PlayerData.citizenid
    elseif fw == 'esx' then
        return player.identifier
    end
    return nil
end

---@param src number
---@return string, string, string|nil firstname, lastname, phone
function SkyDS.Bridge.GetCharInfo(src)
    local player = SkyDS.Bridge.GetPlayer(src)
    if not player then return 'Unknown', 'Citizen', nil end
    local fw = SkyDS.Bridge.GetName()
    if fw == 'qbox' or fw == 'qbcore' then
        local info = player.PlayerData.charinfo or {}
        return info.firstname or 'Unknown', info.lastname or 'Citizen', info.phone
    elseif fw == 'esx' then
        local name = player.getName and player.getName() or GetPlayerName(src)
        local parts = {}
        for part in string.gmatch(name or 'Unknown Citizen', '%S+') do
            parts[#parts + 1] = part
        end
        return parts[1] or 'Unknown', parts[2] or 'Citizen', nil
    end
    return GetPlayerName(src) or 'Unknown', 'Citizen', nil
end

---@param src number
---@param moneyType 'cash'|'bank'
---@return number
function SkyDS.Bridge.GetMoney(src, moneyType)
    local player = SkyDS.Bridge.GetPlayer(src)
    if not player then return 0 end
    local fw = SkyDS.Bridge.GetName()
    if fw == 'qbox' or fw == 'qbcore' then
        return player.Functions.GetMoney(moneyType) or 0
    elseif fw == 'esx' then
        if moneyType == 'bank' then
            return player.getAccount and player.getAccount('bank').money or 0
        end
        return player.getMoney and player.getMoney() or 0
    end
    return 0
end

---@param src number
---@param moneyType 'cash'|'bank'
---@param amount number
---@param reason string
---@return boolean
function SkyDS.Bridge.RemoveMoney(src, moneyType, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount < 1 then return false end
    local player = SkyDS.Bridge.GetPlayer(src)
    if not player then return false end
    local fw = SkyDS.Bridge.GetName()
    if fw == 'qbox' or fw == 'qbcore' then
        local before = player.Functions.GetMoney(moneyType) or 0
        if before < amount then return false end
        local removed = player.Functions.RemoveMoney(moneyType, amount, reason or 'sky_drivingschool')
        if removed == false then return false end
        if removed == true then return true end
        local after = player.Functions.GetMoney(moneyType) or 0
        return after <= (before - amount)
    elseif fw == 'esx' then
        if moneyType == 'bank' then
            local account = player.getAccount and player.getAccount('bank')
            if not account or account.money < amount then return false end
            player.removeAccountMoney('bank', amount)
            return true
        end
        if (player.getMoney and player.getMoney() or 0) < amount then return false end
        player.removeMoney(amount)
        return true
    end
    return false
end

---@param src number
---@param moneyType 'cash'|'bank'
---@param amount number
---@param reason string
---@return boolean
function SkyDS.Bridge.AddMoney(src, moneyType, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount < 1 then return false end
    local player = SkyDS.Bridge.GetPlayer(src)
    if not player then return false end
    local fw = SkyDS.Bridge.GetName()
    if fw == 'qbox' or fw == 'qbcore' then
        player.Functions.AddMoney(moneyType, amount, reason or 'sky_drivingschool')
        return true
    elseif fw == 'esx' then
        if moneyType == 'bank' then
            player.addAccountMoney('bank', amount)
        else
            player.addMoney(amount)
        end
        return true
    end
    return false
end

---@param src number
---@return string|nil jobName, number grade, boolean onduty
function SkyDS.Bridge.GetJob(src)
    local player = SkyDS.Bridge.GetPlayer(src)
    if not player then return nil, 0, false end
    local fw = SkyDS.Bridge.GetName()
    if fw == 'qbox' or fw == 'qbcore' then
        local job = player.PlayerData.job or {}
        local grade = job.grade and (job.grade.level or job.grade) or 0
        if type(grade) == 'table' then grade = grade.level or 0 end
        return job.name, tonumber(grade) or 0, job.onduty ~= false
    elseif fw == 'esx' then
        local job = player.getJob and player.getJob() or {}
        return job.name, tonumber(job.grade) or 0, true
    end
    return nil, 0, false
end

---@param src number
---@param item string
---@param count number
---@param metadata table|nil
---@return boolean
function SkyDS.Bridge.AddItem(src, item, count, metadata)
    if not item or Config.Inventory ~= 'ox_inventory' then return false end
    if GetResourceState('ox_inventory') ~= 'started' then return false end
    count = tonumber(count) or 1
    local ok = exports.ox_inventory:AddItem(src, item, count, metadata)
    return ok and true or false
end

---@param src number
---@param title string
---@param description string
---@param nType string|nil
function SkyDS.Bridge.Notify(src, title, description, nType)
    TriggerClientEvent('ox_lib:notify', src, {
        title = title or 'DMV',
        description = description,
        type = nType or 'inform',
        position = Config.Notify and Config.Notify.position or 'top-right',
        duration = Config.Notify and Config.Notify.duration or 5000,
    })
end

---@param src number
---@return boolean
function SkyDS.Bridge.IsAdmin(src)
    if IsPlayerAceAllowed(src, Config.AdminAce or 'sky_drivingschool.admin') then return true end
    if IsPlayerAceAllowed(src, 'admin') or IsPlayerAceAllowed(src, 'command') then return true end
    local fw = SkyDS.Bridge.GetName()
    if fw == 'qbox' then
        local ok, isGod = pcall(function()
            return exports.qbx_core:HasPermission(src, 'admin') or exports.qbx_core:HasPermission(src, 'god')
        end)
        if ok and isGod then return true end
    end
    return false
end
