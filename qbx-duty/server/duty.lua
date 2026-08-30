--[[
    Prise / fin de service — validations serveur
]]

---@param src number
---@param jobName string
---@return boolean
function Duty.IsNearDutyPoint(src, jobName)
    local points = Config.DutyPoints and Config.DutyPoints[jobName]
    if not points or #points == 0 then
        return true
    end

    local coords = Duty.GetPlayerCoords(src)
    if not coords then return false end

    local radius = Config.DutyPointRadius or 3.0
    for i = 1, #points do
        local point = points[i]
        if #(coords - point) <= radius then
            return true
        end
    end
    return false
end

---@param src number
---@param desired boolean
---@param opts table|nil
---@return boolean success, string|nil reason
function Duty.SetDutyState(src, desired, opts)
    opts = opts or {}
    desired = desired == true

    local player = Duty.GetQbxPlayer(src)
    if not player then return false, 'no_player' end

    local jobName, grade = Duty.GetJobInfo(player)
    if not Duty.JobHasDuty(jobName) then
        return false, 'job_not_configured'
    end

    local entry = DutyPlayers[src]
    if not entry or entry.job ~= jobName then
        Duty.RegisterPlayer(src, player)
        entry = DutyPlayers[src]
    end
    if not entry then return false, 'job_not_configured' end

    if entry.duty == desired then
        return true, desired and 'already_on' or 'already_off'
    end

    if not opts.skipPointCheck and not Duty.IsNearDutyPoint(src, jobName) then
        return false, 'too_far'
    end

    entry.duty = desired
    entry.grade = grade
    entry.name = Duty.GetCharacterName(player)
    Duty.UpdatePlayerCoords(src)
    Duty.ApplyStateBag(src, desired, jobName)
    Duty.SyncQbxJobDuty(player, desired)

    if desired then
        Duty.OpenDutySession(entry)
        TriggerClientEvent('qbx-duty:client:onDuty', src, {
            job = jobName,
            label = Duty.GetJobLabel(jobName),
            grade = grade,
        })
    else
        Duty.CloseDutySession(entry)
        TriggerClientEvent('qbx-duty:client:offDuty', src, {
            job = jobName,
            label = Duty.GetJobLabel(jobName),
            grade = grade,
        })
    end

    Duty.BroadcastBlipRefresh(Duty.JobsAffectedByEntry(entry))
    Duty.SyncViewer(src)

    return true, desired and 'on' or 'off'
end

---@param src number
---@return boolean, string|nil
function Duty.ToggleDuty(src)
    local entry = DutyPlayers[src]
    local current = entry and entry.duty or false
    return Duty.SetDutyState(src, not current)
end

---@param src number
---@return boolean
function Duty.IsOnDuty(src)
    local entry = DutyPlayers[src]
    return entry and entry.duty == true or false
end

---@param src number
---@return table|nil
function Duty.GetDuty(src)
    local entry = DutyPlayers[src]
    if not entry then return nil end
    return {
        duty = entry.duty == true,
        job = entry.job,
        grade = entry.grade,
        label = Duty.GetJobLabel(entry.job),
        citizenid = entry.citizenid,
        name = entry.name,
    }
end

---@param jobName string
---@return boolean
function Duty.IsJobOnDuty(jobName)
    return Duty.GetOnDutyCount(jobName) > 0
end

RegisterNetEvent('qbx-duty:server:requestBlipSync', function()
    Duty.SyncViewer(source)
end)

RegisterNetEvent('qbx-duty:server:setDuty', function(desired, skipPointCheck)
    local src = source
    if type(desired) ~= 'boolean' then return end
    local ok, reason = Duty.SetDutyState(src, desired, { skipPointCheck = skipPointCheck == true })
    if not ok then
        TriggerClientEvent('qbx-duty:client:dutyDenied', src, reason)
    end
end)

lib.callback.register('qbx-duty:server:getDuty', function(source)
    return Duty.GetDuty(source)
end)

lib.callback.register('qbx-duty:server:getOnDutyCount', function(_, jobName)
    if type(jobName) ~= 'string' then return 0 end
    return Duty.GetOnDutyCount(jobName)
end)

lib.callback.register('qbx-duty:server:getEmployeesOnDuty', function(_, jobName)
    if type(jobName) ~= 'string' then return {} end
    return Duty.GetEmployeesOnDuty(jobName)
end)

lib.callback.register('qbx-duty:server:toggleDuty', function(source)
    local entry = DutyPlayers[source]
    local desired = not (entry and entry.duty)
    local ok, reason = Duty.SetDutyState(source, desired)
    return ok, reason, Duty.GetDuty(source)
end)

--- Exports serveur
exports('IsOnDuty', function(src)
    return Duty.IsOnDuty(src)
end)

exports('SetDuty', function(src, state, skipPointCheck)
    local ok = Duty.SetDutyState(src, state == true, { skipPointCheck = skipPointCheck == true })
    return ok
end)

exports('GetDuty', function(src)
    return Duty.GetDuty(src)
end)

exports('GetEmployeesOnDuty', function(jobName)
    return Duty.GetEmployeesOnDuty(jobName)
end)

exports('IsJobOnDuty', function(jobName)
    return Duty.IsJobOnDuty(jobName)
end)

exports('GetOnDutyCount', function(jobName)
    return Duty.GetOnDutyCount(jobName)
end)

exports('ToggleDuty', function(src)
    return Duty.ToggleDuty(src)
end)
