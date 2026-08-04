--[[
    esx_interim — Server
    Sélection métier, paiements, anti-cheat basique.
]]

local ESX
local QBCore
local Framework = { type = nil }

local activeRun = {} -- [source] = { jobId, index, lastPay, startedAt }
local missionCount = {} -- [identifier] = number

-- =============================================================================
-- FRAMEWORK
-- =============================================================================
CreateThread(function()
    if Config.Framework == 'auto' then
        if GetResourceState('es_extended') == 'started' then
            Config.Framework = 'esx'
        elseif GetResourceState('qb-core') == 'started' then
            Config.Framework = 'qbcore'
        end
    end

    if Config.Framework == 'esx' then
        ESX = exports['es_extended']:getSharedObject()
        Framework.type = 'esx'
    elseif Config.Framework == 'qbcore' then
        QBCore = exports['qb-core']:GetCoreObject()
        Framework.type = 'qbcore'
    else
        print('^1[esx_interim]^7 Framework non détecté.')
    end
end)

local function GetPlayer(source)
    if Framework.type == 'esx' then
        return ESX.GetPlayerFromId(source)
    elseif Framework.type == 'qbcore' then
        return QBCore.Functions.GetPlayer(source)
    end
end

local function GetIdentifier(player)
    if Framework.type == 'esx' then
        return player.identifier
    elseif Framework.type == 'qbcore' then
        return player.PlayerData.citizenid
    end
end

local function GetJobName(player)
    if Framework.type == 'esx' then
        return player.getJob().name
    elseif Framework.type == 'qbcore' then
        return player.PlayerData.job.name
    end
end

local function SetJob(player, name, grade)
    grade = grade or 0
    if Framework.type == 'esx' then
        player.setJob(name, grade)
    elseif Framework.type == 'qbcore' then
        player.Functions.SetJob(name, grade)
    end
end

local function AddMoney(player, amount)
    if amount <= 0 then return end
    if Framework.type == 'esx' then
        if Config.PayAccount == 'bank' then
            player.addAccountMoney('bank', amount)
        else
            player.addMoney(amount)
        end
    elseif Framework.type == 'qbcore' then
        player.Functions.AddMoney(Config.PayAccount == 'bank' and 'bank' or 'cash', amount)
    end
end

local function GetJobConfig(id)
    for _, job in ipairs(Config.Jobs) do
        if job.id == id then return job end
    end
end

local function IsJobUnlocked(identifier, job)
    if not job.locked then return true end
    local required = Config.Unlock[job.id]
    if not required then return false end
    return (missionCount[identifier] or 0) >= required
end

local function IncrementMissions(identifier)
    missionCount[identifier] = (missionCount[identifier] or 0) + 1
end

-- =============================================================================
-- CALLBACKS
-- =============================================================================
lib.callback.register('esx_interim:server:getJobs', function(source)
    local player = GetPlayer(source)
    if not player then return {} end
    local identifier = GetIdentifier(player)

    local list = {}
    for _, job in ipairs(Config.Jobs) do
        local locked = job.locked and not IsJobUnlocked(identifier, job)
        list[#list + 1] = {
            id = job.id,
            label = job.label,
            subtitle = job.subtitle,
            description = job.description,
            locked = locked,
            icon = job.icon,
        }
    end
    return list
end)

lib.callback.register('esx_interim:server:selectJob', function(source, jobId)
    local player = GetPlayer(source)
    if not player then return false, 'Joueur invalide' end

    local job = GetJobConfig(jobId)
    if not job then return false, 'Métier inconnu' end

    local identifier = GetIdentifier(player)
    if job.locked and not IsJobUnlocked(identifier, job) then
        return false, Locales['fr']['job_locked']
    end

    if activeRun[source] then
        return false, Locales['fr']['already_working']
    end

    SetJob(player, job.id, 0)
    return true
end)

lib.callback.register('esx_interim:server:quitJob', function(source)
    local player = GetPlayer(source)
    if not player then return false end
    activeRun[source] = nil
    SetJob(player, Config.DefaultJob.name, Config.DefaultJob.grade)
    return true
end)

lib.callback.register('esx_interim:server:startRun', function(source, jobId)
    local player = GetPlayer(source)
    if not player then return false, 'Joueur invalide' end

    local job = GetJobConfig(jobId)
    if not job then return false, 'Métier inconnu' end

    if GetJobName(player) ~= jobId then
        return false, Locales['fr']['no_job']
    end

    if activeRun[source] then
        return false, Locales['fr']['already_working']
    end

    activeRun[source] = {
        jobId = jobId,
        index = 0,
        lastPay = 0,
        startedAt = os.time(),
    }
    return true
end)

lib.callback.register('esx_interim:server:completeStop', function(source, jobId, index)
    local player = GetPlayer(source)
    if not player then return false, 'Joueur invalide' end

    local run = activeRun[source]
    if not run or run.jobId ~= jobId then
        return false, Locales['fr']['no_job']
    end

    local job = GetJobConfig(jobId)
    if not job then return false, 'Métier inconnu' end

    -- Anti spam
    local now = os.time()
    if run.lastPay and (now - run.lastPay) < Config.MissionCooldown then
        return false, 'Patientez un instant...'
    end

    -- Progression séquentielle
    if index ~= run.index + 1 then
        return false, 'Point invalide'
    end

    local ped = GetPlayerPed(source)
    if ped and ped ~= 0 then
        local coords = GetEntityCoords(ped)
        local near = false
        for _, loc in ipairs(job.locations) do
            if #(coords - loc) <= Config.InteractDistance + 5.0 then
                near = true
                break
            end
        end
        if not near then
            return false, Locales['fr']['too_far']
        end
    end

    local pay = math.random(job.pay.min, job.pay.max)
    AddMoney(player, pay)
    run.index = index
    run.lastPay = now
    IncrementMissions(GetIdentifier(player))

    return true, pay
end)

lib.callback.register('esx_interim:server:sellOres', function(source, amount)
    local player = GetPlayer(source)
    if not player then return false, 'Joueur invalide' end

    local run = activeRun[source]
    if not run or run.jobId ~= 'mineur' then
        return false, Locales['fr']['no_job']
    end

    amount = tonumber(amount) or 0
    local job = GetJobConfig('mineur')
    if not job or amount < 1 or amount > (job.maxCarry or 8) then
        return false, Locales['fr']['need_ores']
    end

    local ped = GetPlayerPed(source)
    if ped and ped ~= 0 and job.sellPoint then
        local coords = GetEntityCoords(ped)
        if #(coords - job.sellPoint) > Config.InteractDistance + 5.0 then
            return false, Locales['fr']['too_far']
        end
    end

    local total = 0
    for _ = 1, amount do
        total = total + math.random(job.orePay.min, job.orePay.max)
    end
    AddMoney(player, total)
    IncrementMissions(GetIdentifier(player))
    activeRun[source] = nil
    return true, total
end)

lib.callback.register('esx_interim:server:dumpTrash', function(source, bags)
    local player = GetPlayer(source)
    if not player then return 0 end

    local run = activeRun[source]
    if not run or run.jobId ~= 'eboueur' then return 0 end

    local job = GetJobConfig('eboueur')
    if not job then return 0 end

    bags = math.min(tonumber(bags) or 0, 12)
    local bonus = bags * math.random(20, 40)

    local ped = GetPlayerPed(source)
    if ped and ped ~= 0 and job.landfill then
        local coords = GetEntityCoords(ped)
        if #(coords - job.landfill) > 12.0 then
            return 0
        end
    end

    AddMoney(player, bonus)
    IncrementMissions(GetIdentifier(player))
    activeRun[source] = nil
    return bonus
end)

RegisterNetEvent('esx_interim:server:cancelRun', function()
    activeRun[source] = nil
end)

AddEventHandler('playerDropped', function()
    activeRun[source] = nil
end)

-- Fin de tournée côté client (jobs non-spéciaux)
RegisterNetEvent('esx_interim:server:endRun', function()
    activeRun[source] = nil
end)
