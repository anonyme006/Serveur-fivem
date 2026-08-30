--[[
    Registre joueurs — source de vérité côté serveur
]]

DutyPlayers = DutyPlayers or {}
ActiveSessions = ActiveSessions or {}

local QBX = exports.qbx_core

---@param src number
---@return table|nil player
function Duty.GetQbxPlayer(src)
    if not src or src <= 0 then return nil end
    local ok, player = pcall(function()
        return QBX:GetPlayer(src)
    end)
    if ok and player then return player end
    return nil
end

---@param player table
---@return string|nil
function Duty.GetCitizenId(player)
    return player and player.PlayerData and player.PlayerData.citizenid or nil
end

---@param player table
---@return string
function Duty.GetCharacterName(player)
    if not player or not player.PlayerData or not player.PlayerData.charinfo then
        return GetPlayerName(player and player.PlayerData and player.PlayerData.source or 0) or '?'
    end
    local c = player.PlayerData.charinfo
    return (('%s %s'):format(c.firstname or '', c.lastname or '')):gsub('^%s+', ''):gsub('%s+$', '')
end

---@param player table
---@return string|nil, number
function Duty.GetJobInfo(player)
    if not player or not player.PlayerData or not player.PlayerData.job then
        return nil, 0
    end
    local job = player.PlayerData.job
    local grade = 0
    if type(job.grade) == 'table' then
        grade = tonumber(job.grade.level) or 0
    else
        grade = tonumber(job.grade) or 0
    end
    return job.name, grade
end

---@param src number
---@return vector3|nil
function Duty.GetPlayerCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

---@param src number
---@return table|nil
function Duty.GetEntry(src)
    return DutyPlayers[src]
end

---@param src number
---@param player table|nil
---@return table|nil
function Duty.BuildEntry(src, player)
    player = player or Duty.GetQbxPlayer(src)
    if not player then return nil end

    local jobName, grade = Duty.GetJobInfo(player)
    if not Duty.IsJobEnabled(jobName) then return nil end

    local coords = Duty.GetPlayerCoords(src)
    local existing = DutyPlayers[src]

    return {
        serverId = src,
        citizenid = Duty.GetCitizenId(player),
        name = Duty.GetCharacterName(player),
        job = jobName,
        grade = grade,
        duty = existing and existing.duty or false,
        coords = coords and { x = coords.x, y = coords.y, z = coords.z } or nil,
    }
end

---@param src number
---@param player table|nil
function Duty.RegisterPlayer(src, player)
    local entry = Duty.BuildEntry(src, player)
    if not entry then
        Duty.UnregisterPlayer(src)
        return
    end

    local previous = DutyPlayers[src]
    DutyPlayers[src] = entry

    if previous and previous.job ~= entry.job then
        Duty.ClearStateBag(src)
        entry.duty = false
        DutyPlayers[src].duty = false
    end

    Duty.ApplyStateBag(src, entry.duty, entry.job)
end

---@param src number
function Duty.UnregisterPlayer(src)
    local entry = DutyPlayers[src]
    if entry and entry.duty then
        Duty.CloseDutySession(entry)
    end
    DutyPlayers[src] = nil
    Duty.ClearStateBag(src)
end

---@param src number
---@param duty boolean
---@param jobName string|nil
function Duty.ApplyStateBag(src, duty, jobName)
    local player = Player(src)
    if not player or not player.state then return end
    player.state:set('duty', duty == true, true)
    player.state:set('dutyJob', jobName or '', true)
end

---@param src number
function Duty.ClearStateBag(src)
    Duty.ApplyStateBag(src, false, '')
end

---@param src number
function Duty.UpdatePlayerCoords(src)
    local entry = DutyPlayers[src]
    if not entry then return end

    local coords = Duty.GetPlayerCoords(src)
    if not coords then return end

    entry.coords = { x = coords.x, y = coords.y, z = coords.z }
end

---@param viewerSrc number
---@return table<number, table>
function Duty.GetVisibleForViewer(viewerSrc)
    local viewer = DutyPlayers[viewerSrc]
    local viewerJob = viewer and viewer.job or nil
    local visible = {}

    for targetSrc, entry in pairs(DutyPlayers) do
        if entry.job and Duty.CanViewerSeeJob(viewerJob, entry.job, entry.duty) then
            visible[targetSrc] = {
                serverId = entry.serverId,
                citizenid = entry.citizenid,
                name = entry.name,
                job = entry.job,
                grade = entry.grade,
                duty = entry.duty,
                coords = entry.coords,
                label = Duty.GetJobLabel(entry.job),
                blipName = Duty.FormatBlipName(entry.name, entry.job, entry.duty),
                blip = Duty.GetBlipStyle(entry.job, entry.duty),
            }
        end
    end

    return visible
end

---@param jobName string
---@return table[]
function Duty.GetEmployeesOnDuty(jobName)
    local list = {}
    for _, entry in pairs(DutyPlayers) do
        if entry.job == jobName and entry.duty then
            list[#list + 1] = {
                serverId = entry.serverId,
                citizenid = entry.citizenid,
                name = entry.name,
                grade = entry.grade,
                coords = entry.coords,
            }
        end
    end
    return list
end

---@param jobName string
---@return number
function Duty.GetOnDutyCount(jobName)
    local n = 0
    for _, entry in pairs(DutyPlayers) do
        if entry.job == jobName and entry.duty then
            n = n + 1
        end
    end
    return n
end

---@param entry table
function Duty.OpenDutySession(entry)
    if not Config.TrackDutyTime or not entry or not entry.citizenid then return end
    ActiveSessions[entry.citizenid] = {
        job = entry.job,
        grade = entry.grade,
        clockIn = os.time(),
    }
end

---@param entry table
function Duty.CloseDutySession(entry)
    if not Config.TrackDutyTime or not entry or not entry.citizenid then return end

    local session = ActiveSessions[entry.citizenid]
    if not session then return end

    local clockOut = os.time()
    local duration = math.max(0, clockOut - (session.clockIn or clockOut))

    MySQL.insert('INSERT INTO duty_logs (citizenid, job, grade, clock_in, clock_out, duration) VALUES (?, ?, ?, FROM_UNIXTIME(?), FROM_UNIXTIME(?), ?)', {
        entry.citizenid,
        session.job or entry.job,
        session.grade or entry.grade or 0,
        session.clockIn or clockOut,
        clockOut,
        duration,
    })

    ActiveSessions[entry.citizenid] = nil
end

--- Notifie les viewers concernés par un changement
---@param affectedJobs table<string, boolean>|nil
function Duty.BroadcastBlipRefresh(affectedJobs)
    for viewerSrc, viewer in pairs(DutyPlayers) do
        if GetPlayerName(viewerSrc) then
            local shouldSync = not affectedJobs
            if affectedJobs and viewer.job and affectedJobs[viewer.job] then
                shouldSync = true
            end
            if shouldSync then
                TriggerClientEvent('qbx-duty:client:updateBlips', viewerSrc, Duty.GetVisibleForViewer(viewerSrc))
            end
        end
    end
end

--- Sync coords uniquement (payload léger)
function Duty.BroadcastCoordRefresh()
    for viewerSrc in pairs(DutyPlayers) do
        if GetPlayerName(viewerSrc) then
            local visible = Duty.GetVisibleForViewer(viewerSrc)
            local coordsPayload = {}
            for sid, data in pairs(visible) do
                if data.coords then
                    coordsPayload[sid] = data.coords
                end
            end
            if next(coordsPayload) then
                TriggerClientEvent('qbx-duty:client:updateCoords', viewerSrc, coordsPayload)
            end
        end
    end
end

---@param src number
function Duty.SyncViewer(src)
    if not GetPlayerName(src) then return end
    TriggerClientEvent('qbx-duty:client:updateBlips', src, Duty.GetVisibleForViewer(src))
end

--- Jobs impactés par une entrée
---@param entry table|nil
---@return table<string, boolean>
function Duty.JobsAffectedByEntry(entry)
    local jobs = {}
    if not entry or not entry.job then return jobs end
    jobs[entry.job] = true
    local rules = Config.Visibility and Config.Visibility[entry.job]
    if rules then
        for viewerJob in pairs(rules) do
            jobs[viewerJob] = true
        end
    end
    return jobs
end

--- Sync duty avec qbx_core si disponible
---@param player table
---@param onDuty boolean
function Duty.SyncQbxJobDuty(player, onDuty)
    if not player or not player.Functions then return end
    pcall(function()
        if player.Functions.SetJobDuty then
            player.Functions.SetJobDuty(onDuty)
        end
    end)
end
