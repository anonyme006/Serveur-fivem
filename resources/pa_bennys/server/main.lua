local ESX = exports['es_extended']:getSharedObject()

local activeMissions = {}
local assignedMissions = {}
local onDutyPlayers = {}
local missionSeq = 0

local function notifyPlayer(src, msg, nType)
    TriggerClientEvent('ox_lib:notify', src, {
        title = Config.CompanyName,
        description = msg,
        type = nType or 'inform',
    })
end

local function getJobName(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return nil end
    return xPlayer.getJob().name
end

local function isMechanic(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end
    local job = xPlayer.getJob()
    if not job or not Config.Jobs[job.name] then return false end
    if Config.RequireDuty and not onDutyPlayers[src] then return false end
    return true
end

local function addSocietyMoney(amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return end

    if GetResourceState('Renewed-Banking') == 'started' then
        exports['Renewed-Banking']:addAccountMoney(Config.SocietyAccount, amount)
        return
    end

    TriggerEvent('esx_addonaccount:getSharedAccount', Config.SocietyAccount, function(account)
        if account then account.addMoney(amount) end
    end)
end

local function addPlayerMoney(src, amount)
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then xPlayer.addAccountMoney('bank', amount) end
end

local function distCheck(src, coords, maxDist)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    local p = GetEntityCoords(ped)
    return #(p - vector3(coords.x, coords.y, coords.z)) <= (maxDist or 5.0)
end

local function mechanicsOnDuty()
    local list = {}
    for _, src in ipairs(GetPlayers()) do
        src = tonumber(src)
        if isMechanic(src) then list[#list + 1] = src end
    end
    return list
end

local function broadcastBipeur(mission, targets)
    for _, src in ipairs(targets or mechanicsOnDuty()) do
        if not assignedMissions[src] then
            TriggerClientEvent('pa_bennys:client:bipeur', src, mission)
        end
    end
end

local function createMission()
    if not Config.Missions.enabled then return end

    local active = 0
    for _, m in pairs(activeMissions) do
        if not m.completed then active = active + 1 end
    end
    if active >= Config.Missions.maxActive or #mechanicsOnDuty() == 0 then return end

    missionSeq = missionSeq + 1
    local mType = Config.Missions.types[math.random(#Config.Missions.types)]
    local loc = Config.Missions.locations[math.random(#Config.Missions.locations)]

    local mission = {
        id = missionSeq,
        code = ('DEP-%03d'):format(missionSeq),
        label = mType.label,
        message = mType.message,
        missionType = mType.id,
        coords = { x = loc.x, y = loc.y, z = loc.z, w = loc.w },
        vehicleModel = Config.Missions.vehicles[math.random(#Config.Missions.vehicles)],
        damage = mType.damage,
        burstTires = mType.burstTires,
        payout = math.random(Config.Missions.payout.min, Config.Missions.payout.max),
        accepted = false,
        completed = false,
        assignedTo = nil,
    }

    activeMissions[mission.id] = mission
    broadcastBipeur(mission)
end

RegisterNetEvent('pa_bennys:server:setDuty', function(state)
    local src = source
    if not Config.Jobs[getJobName(src) or ''] then return end
    onDutyPlayers[src] = state and true or nil
end)

CreateThread(function()
    while true do
        Wait(math.random(Config.Missions.interval.min, Config.Missions.interval.max) * 1000)
        createMission()
    end
end)

RegisterNetEvent('pa_bennys:server:repair', function(netId, fixType)
    local src = source
    if not isMechanic(src) then return end

    fixType = tostring(fixType or 'full')
    local price = Config.Prices[fixType] or 0
    TriggerClientEvent('pa_bennys:client:applyFix', -1, netId, fixType)

    if price > 0 then
        addSocietyMoney(math.floor(price * (1.0 - Config.EmployeeCut)))
        addPlayerMoney(src, math.floor(price * Config.EmployeeCut))
    end

    notifyPlayer(src, 'Intervention terminée.', 'success')
end)

RegisterNetEvent('pa_bennys:server:custom', function(netId, modType, modData)
    local src = source
    if not isMechanic(src) then return end

    modType = tostring(modType or 'neon')
    local prices = {
        neon = Config.Prices.customNeon,
        color = Config.Prices.customColor,
        tint = Config.Prices.customTint,
        wheels = Config.Prices.customWheels,
    }
    local price = prices[modType] or Config.Prices.customNeon

    addSocietyMoney(math.floor(price * (1.0 - Config.EmployeeCut)))
    addPlayerMoney(src, math.floor(price * Config.EmployeeCut))
    TriggerClientEvent('pa_bennys:client:syncCustom', -1, netId, modType, modData or {})
    notifyPlayer(src, 'Custom enregistré.', 'success')
end)

RegisterNetEvent('pa_bennys:server:spawnVehicle', function(model)
    local src = source
    if not isMechanic(src) then return end
    TriggerClientEvent('pa_bennys:client:spawnVehicle', src, tostring(model or 'flatbed'):sub(1, 32))
end)

RegisterNetEvent('pa_bennys:server:acceptMission', function(missionId)
    local src = source
    if not isMechanic(src) or assignedMissions[src] then
        notifyPlayer(src, assignedMissions[src] and 'Mission déjà en cours.' or 'Accès refusé.', 'error')
        return
    end

    missionId = tonumber(missionId)
    local mission = activeMissions[missionId]
    if not mission or mission.completed or mission.assignedTo then
        notifyPlayer(src, 'Mission indisponible.', 'error')
        return
    end

    mission.accepted = true
    mission.assignedTo = src
    assignedMissions[src] = missionId
    TriggerClientEvent('pa_bennys:client:missionAccepted', src, mission)

    for _, id in ipairs(GetPlayers()) do
        id = tonumber(id)
        if id ~= src then TriggerClientEvent('pa_bennys:client:missionEnded', id) end
    end
end)

RegisterNetEvent('pa_bennys:server:cancelMission', function(missionId)
    local src = source
    missionId = tonumber(missionId)
    local mission = activeMissions[missionId]
    if not mission or mission.assignedTo ~= src then return end

    mission.assignedTo = nil
    mission.accepted = false
    assignedMissions[src] = nil
    TriggerClientEvent('pa_bennys:client:missionEnded', src)
    broadcastBipeur(mission)
end)

RegisterNetEvent('pa_bennys:server:completeMission', function(missionId)
    local src = source
    if assignedMissions[src] ~= tonumber(missionId) then return end

    local mission = activeMissions[tonumber(missionId)]
    if not mission or mission.completed then return end
    if not distCheck(src, mission.coords, Config.Missions.completeRadius) then
        notifyPlayer(src, 'Trop loin du véhicule.', 'error')
        return
    end

    mission.completed = true
    assignedMissions[src] = nil

    local society = math.floor(mission.payout * Config.Missions.societyShare)
    local bonus = math.random(Config.Missions.employeeBonus.min, Config.Missions.employeeBonus.max)
    addSocietyMoney(society)
    addPlayerMoney(src, bonus)

    TriggerClientEvent('pa_bennys:client:missionComplete', src)
    TriggerClientEvent('pa_bennys:client:missionEnded', src)
    notifyPlayer(src, ('Dépannage OK — %d$ société, %d$ bonus.'):format(society, bonus), 'success')
    SetTimeout(60000, function() activeMissions[mission.id] = nil end)
end)

AddEventHandler('playerDropped', function()
    local src = source
    local mid = assignedMissions[src]
    onDutyPlayers[src] = nil
    if not mid then return end

    local mission = activeMissions[mid]
    if mission then
        mission.assignedTo = nil
        mission.accepted = false
        broadcastBipeur(mission)
    end
    assignedMissions[src] = nil
end)

exports('CreateMission', createMission)
