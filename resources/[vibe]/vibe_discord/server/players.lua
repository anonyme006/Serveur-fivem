local Players = {}

local function detectFramework()
    if Config.Framework ~= 'auto' then
        return Config.Framework
    end
    if GetResourceState('qbx_core') == 'started' or GetResourceState('qb-core') == 'started' then
        return 'qbx'
    end
    if GetResourceState('es_extended') == 'started' then
        return 'esx'
    end
    return 'standalone'
end

Framework = detectFramework()

local function getIdentifier(src, idType)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:sub(1, #idType + 1) == (idType .. ':') then
            return id
        end
    end
    return nil
end

function GetPlayerLicense(src)
    return getIdentifier(src, 'license2') or getIdentifier(src, 'license')
end

function GetPlayerDiscord(src)
    local d = getIdentifier(src, 'discord')
    if d then
        return d:gsub('discord:', '')
    end
    return nil
end

function GetPlayerJobLabel(src)
    if Framework == 'qbx' then
        local ok, player = pcall(function()
            return exports.qbx_core:GetPlayer(src)
        end)
        if ok and player and player.PlayerData and player.PlayerData.job then
            local j = player.PlayerData.job
            return ('%s (%s)'):format(j.label or j.name or '?', j.grade and j.grade.name or j.grade and j.grade.level or 0)
        end
        -- fallback qb-core
        local qb = GetResourceState('qb-core') == 'started' and exports['qb-core']:GetCoreObject()
        if qb then
            local p = qb.Functions.GetPlayer(src)
            if p and p.PlayerData and p.PlayerData.job then
                local j = p.PlayerData.job
                return ('%s'):format(j.label or j.name or '?')
            end
        end
    elseif Framework == 'esx' then
        local ESX = exports['es_extended']:getSharedObject()
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer and xPlayer.job then
            return ('%s - %s'):format(xPlayer.job.label or xPlayer.job.name, xPlayer.job.grade_label or xPlayer.job.grade)
        end
    end
    return 'civil'
end

function GetPlayerCharName(src)
    if Framework == 'qbx' then
        local ok, player = pcall(function()
            return exports.qbx_core:GetPlayer(src)
        end)
        if ok and player and player.PlayerData and player.PlayerData.charinfo then
            local c = player.PlayerData.charinfo
            return ('%s %s'):format(c.firstname or '', c.lastname or ''):gsub('%s+$', '')
        end
    elseif Framework == 'esx' then
        local ESX = exports['es_extended']:getSharedObject()
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            return xPlayer.getName and xPlayer.getName() or GetPlayerName(src)
        end
    end
    return GetPlayerName(src) or ('ID ' .. tostring(src))
end

function BuildPlayerPayload(src)
    src = tonumber(src)
    if not src or not GetPlayerName(src) then return nil end
    return {
        id = src,
        name = GetPlayerName(src),
        character = GetPlayerCharName(src),
        license = GetPlayerLicense(src),
        discord = GetPlayerDiscord(src),
        job = GetPlayerJobLabel(src),
        ping = GetPlayerPing(src),
    }
end

function GetOnlinePlayers()
    local list = {}
    for _, sid in ipairs(GetPlayers()) do
        local p = BuildPlayerPayload(tonumber(sid))
        if p then list[#list + 1] = p end
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

function FindPlayerById(id)
    id = tonumber(id)
    if not id then return nil end
    if not GetPlayerName(id) then return nil end
    return BuildPlayerPayload(id)
end

function FormatUptime()
    local s = math.floor(os.clock())
    -- os.clock n'est pas l'uptime serveur ; on utilise GetGameTimer
    s = math.floor(GetGameTimer() / 1000)
    local h = math.floor(s / 3600)
    local m = math.floor((s % 3600) / 60)
    return ('%dh %dm'):format(h, m)
end

exports('GetOnlinePlayers', GetOnlinePlayers)
exports('BuildPlayerPayload', BuildPlayerPayload)
