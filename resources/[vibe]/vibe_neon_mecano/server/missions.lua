local activeMissions = {}
local assignedMissions = {}
local missionSeq = 0

local function mechanicsOnDuty()
    local list = {}
    for _, src in ipairs(GetPlayers()) do
        src = tonumber(src)
        local job = exports.vibe_api:GetJob(src)
        if job and Config.Jobs[job.name] and job.onduty then
            list[#list + 1] = src
        end
    end
    return list
end

local function randomLocation()
    local locs = Config.Missions.locations
    return locs[math.random(#locs)]
end

local function randomVehicle()
    local vehs = Config.Missions.vehicles
    return vehs[math.random(#vehs)]
end

local function randomMissionType()
    local types = Config.Missions.types
    return types[math.random(#types)]
end

local function countActive()
    local n = 0
    for _, m in pairs(activeMissions) do
        if not m.completed then n = n + 1 end
    end
    return n
end

local function broadcastBipeur(mission, targets)
    for _, src in ipairs(targets or mechanicsOnDuty()) do
        if not assignedMissions[src] then
            TriggerClientEvent('vibe_neon_mecano:client:bipeur', src, mission)
        end
    end
end

local function createMission()
    if not Config.Missions.enabled then return end
    if countActive() >= Config.Missions.maxActive then return end
    if #mechanicsOnDuty() == 0 then return end

    missionSeq = missionSeq + 1
    local mType = randomMissionType()
    local loc = randomLocation()
    local payout = math.random(Config.Missions.payout.min, Config.Missions.payout.max)

    local mission = {
        id = missionSeq,
        code = 'DEP-' .. missionSeq,
        label = mType.label,
        message = mType.message,
        missionType = mType.id,
        coords = { x = loc.x, y = loc.y, z = loc.z, w = loc.w },
        vehicleModel = randomVehicle(),
        damage = mType.damage,
        burstTires = mType.burstTires,
        payout = payout,
        accepted = false,
        completed = false,
        assignedTo = nil,
        createdAt = os.time(),
    }

    activeMissions[mission.id] = mission
    broadcastBipeur(mission)
    print(('[vibe_neon_mecano] Mission %s créée — %s'):format(mission.code, mType.label))
end

CreateThread(function()
    while true do
        local wait = math.random(Config.Missions.interval.min, Config.Missions.interval.max) * 1000
        Wait(wait)
        createMission()
    end
end)

RegisterNetEvent('vibe_neon_mecano:server:acceptMission', function(missionId)
    local src = source
    local job = exports.vibe_api:GetJob(src)
    if not job or not Config.Jobs[job.name] or not job.onduty then return end
    if assignedMissions[src] then
        exports.vibe_api:Notify(src, 'Bipeur', 'Tu as déjà une mission en cours.', 'error')
        return
    end

    missionId = tonumber(missionId)
    local mission = activeMissions[missionId]
    if not mission or mission.completed or mission.assignedTo then
        exports.vibe_api:Notify(src, 'Bipeur', 'Cette mission n\'est plus disponible.', 'error')
        return
    end

    mission.accepted = true
    mission.assignedTo = src
    assignedMissions[src] = missionId

    TriggerClientEvent('vibe_neon_mecano:client:missionAccepted', src, mission)

    for _, id in ipairs(GetPlayers()) do
        id = tonumber(id)
        if id ~= src then
            TriggerClientEvent('vibe_neon_mecano:client:missionEnded', id)
        end
    end
end)

RegisterNetEvent('vibe_neon_mecano:server:declineMission', function(missionId)
    missionId = tonumber(missionId)
    local mission = activeMissions[missionId]
    if not mission or mission.assignedTo then return end
    -- La mission reste disponible pour les autres mécanos
end)

RegisterNetEvent('vibe_neon_mecano:server:cancelMission', function(missionId)
    local src = source
    missionId = tonumber(missionId)
    local mission = activeMissions[missionId]
    if not mission or mission.assignedTo ~= src then return end

    mission.assignedTo = nil
    mission.accepted = false
    assignedMissions[src] = nil
    TriggerClientEvent('vibe_neon_mecano:client:missionEnded', src)
    broadcastBipeur(mission)
    exports.vibe_api:Notify(src, 'Bipeur', 'Mission abandonnée.', 'inform')
end)

RegisterNetEvent('vibe_neon_mecano:server:completeMission', function(missionId)
    local src = source
    if not assignedMissions[src] then return end
    missionId = tonumber(missionId)
    if assignedMissions[src] ~= missionId then return end

    local mission = activeMissions[missionId]
    if not mission or mission.completed then return end

    if not exports.vibe_api:DistCheck(src, mission.coords, Config.Missions.completeRadius) then
        exports.vibe_api:Notify(src, 'Bipeur', 'Tu es trop loin du véhicule.', 'error')
        return
    end

    mission.completed = true
    assignedMissions[src] = nil

    local payout = mission.payout
    local societyAmount = math.floor(payout * Config.Missions.societyShare)
    local bonus = math.random(Config.Missions.employeeBonus.min, Config.Missions.employeeBonus.max)

    exports['Renewed-Banking']:addAccountMoney(Config.SocietyAccount, societyAmount)
    exports.vibe_api:AddMoney(src, 'bank', bonus, 'neon-depannage')

    TriggerClientEvent('vibe_neon_mecano:client:missionComplete', src)
    TriggerClientEvent('vibe_neon_mecano:client:missionEnded', src)

    exports.vibe_api:Notify(src, Config.CompanyName,
        ('Dépannage terminé — %d$ pour l\'entreprise, %d$ bonus perso.'):format(societyAmount, bonus),
        'success')

    SetTimeout(60000, function()
        activeMissions[missionId] = nil
    end)
end)

AddEventHandler('playerDropped', function()
    local src = source
    local mid = assignedMissions[src]
    if not mid then return end
    local mission = activeMissions[mid]
    if mission then
        mission.assignedTo = nil
        mission.accepted = false
        broadcastBipeur(mission)
    end
    assignedMissions[src] = nil
end)

-- Export pour déclencher manuellement une mission (admin / tests)
exports('CreateMission', createMission)
