--[[
    qbx-duty — bootstrap serveur
]]

MySQL.ready(function()
    if not Config.TrackDutyTime then return end
    local sql = LoadResourceFile(GetCurrentResourceName(), 'sql/duty.sql')
    if not sql then return end
    for statement in sql:gmatch('([^;]+);') do
        local trimmed = statement:gsub('^%s+', ''):gsub('%s+$', '')
        if trimmed ~= '' and not trimmed:match('^%-%-') then
            MySQL.query.await(trimmed)
        end
    end
    print('^2[qbx-duty]^0 table duty_logs prête')
end)

local function onPlayerReady(src)
    src = tonumber(src)
    if not src or not GetPlayerName(src) then return end

    local player = Duty.GetQbxPlayer(src)
    if not player then return end

    Duty.RegisterPlayer(src, player)

    local jobName = select(1, Duty.GetJobInfo(player))
    if jobName and player.PlayerData.job and player.PlayerData.job.onduty then
        Duty.SetDutyState(src, true, { skipPointCheck = true })
    end

    SetTimeout(1000, function()
        Duty.SyncViewer(src)
        Duty.BroadcastBlipRefresh(Duty.JobsAffectedByEntry(DutyPlayers[src]))
    end)
end

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    local src = player and player.PlayerData and player.PlayerData.source
    onPlayerReady(src)
end)

AddEventHandler('qbx_core:server:playerLoggedIn', function(src)
    onPlayerReady(src)
end)

AddEventHandler('playerDropped', function()
    local src = source
    local entry = DutyPlayers[src]
    local affected = Duty.JobsAffectedByEntry(entry)
    Duty.UnregisterPlayer(src)
    TriggerClientEvent('qbx-duty:client:removeBlip', -1, src)
    Duty.BroadcastBlipRefresh(affected)
end)

local function mergeAffected(base, extra)
    for job in pairs(extra or {}) do
        base[job] = true
    end
end

--- Changement de job
local function onJobUpdate(src)
    src = tonumber(src)
    if not src then return end

    local previous = DutyPlayers[src]
    local affected = Duty.JobsAffectedByEntry(previous)

    if previous and previous.duty then
        Duty.CloseDutySession(previous)
    end

    Duty.RegisterPlayer(src)
    local entry = DutyPlayers[src]

    if entry then
        mergeAffected(affected, Duty.JobsAffectedByEntry(entry))
    end

    Duty.SyncViewer(src)
    Duty.BroadcastBlipRefresh(affected)
    TriggerClientEvent('qbx-duty:client:jobChanged', src, entry and entry.job or nil)
end

AddEventHandler('QBCore:Server:OnJobUpdate', function(src)
    onJobUpdate(src)
end)

AddEventHandler('qbx_core:server:onJobUpdate', function(src)
    onJobUpdate(src)
end)

--- Mise à jour coords (intervalle configurable)
CreateThread(function()
    local interval = (Config.Blips and Config.Blips.updateInterval) or 2000
    interval = math.max(500, interval)

    while true do
        Wait(interval)
        for src in pairs(DutyPlayers) do
            if GetPlayerName(src) then
                Duty.UpdatePlayerCoords(src)
            else
                Duty.UnregisterPlayer(src)
            end
        end
        Duty.BroadcastCoordRefresh()
    end
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    Wait(1500)
    for _, playerId in ipairs(GetPlayers()) do
        onPlayerReady(tonumber(playerId))
    end
end)

print('^2[qbx-duty]^0 système de service global chargé')
