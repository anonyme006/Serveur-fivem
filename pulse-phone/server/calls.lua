--[[
    Pulse Phone — Appels serveur (fondation pma-voice)
]]

Pulse = Pulse or {}
Pulse.Calls = {
    active = {}, -- callId -> state
}

local callCooldown = {}

local function nextChannel(callId)
    -- canal dédié simple et unique par appel
    return 5000 + (callId % 4000)
end

lib.callback.register('pulse-phone:server:startCall', function(source, number, companyId)
    local citizenid = Pulse.Server.GetCitizenId(source)
    if not citizenid then return { ok = false } end

    local now = os.time()
    if callCooldown[source] and now - callCooldown[source] < (Config.Cooldowns.startCall / 1000) then
        return { ok = false, error = 'cooldown' }
    end
    callCooldown[source] = now

    local user = Pulse.Database.GetUser(citizenid)
    number = Pulse.Utils.NormalizeNumber(number)
    if not user or not number then return { ok = false, error = 'invalid' } end

    local targetSrc = Pulse.Players.GetSourceByNumber(number)
    local callee = Pulse.Database.GetUserByNumber(number)

    local callId = MySQL.insert.await([[
        INSERT INTO phone_calls (caller_citizenid, caller_number, callee_number, callee_citizenid, direction, status, company_id)
        VALUES (?, ?, ?, ?, 'outgoing', 'ringing', ?)
    ]], {
        citizenid,
        user.phone_number,
        number,
        callee and callee.citizenid or nil,
        companyId,
    })

    local state = {
        id = callId,
        callerSrc = source,
        calleeSrc = targetSrc,
        callerNumber = user.phone_number,
        number = number,
        name = Pulse.Players.GetFullName(source),
        direction = 'outgoing',
        status = 'ringing',
        companyId = companyId,
        channel = nextChannel(callId),
    }
    Pulse.Calls.active[callId] = state

    if targetSrc then
        TriggerClientEvent('pulse-phone:client:callIncoming', targetSrc, {
            id = callId,
            number = user.phone_number,
            name = state.name,
            direction = 'incoming',
            status = 'ringing',
            companyId = companyId,
        })
    end

    TriggerClientEvent('pulse-phone:client:callUpdate', source, state)
    return { ok = true, call = state }
end)

lib.callback.register('pulse-phone:server:acceptCall', function(source, callId)
    callId = tonumber(callId)
    local state = callId and Pulse.Calls.active[callId]
    if not state or state.calleeSrc ~= source then
        return { ok = false, error = 'forbidden' }
    end

    state.status = 'accepted'
    state.answeredAt = os.time()
    MySQL.update.await(
        'UPDATE phone_calls SET status = ?, answered_at = NOW() WHERE id = ?',
        { 'accepted', callId }
    )

    TriggerClientEvent('pulse-phone:client:callUpdate', state.callerSrc, state)
    TriggerClientEvent('pulse-phone:client:callUpdate', state.calleeSrc, state)
    return { ok = true, call = state }
end)

lib.callback.register('pulse-phone:server:declineCall', function(source, callId)
    callId = tonumber(callId)
    local state = callId and Pulse.Calls.active[callId]
    if not state then return { ok = false } end
    if source ~= state.callerSrc and source ~= state.calleeSrc then
        return { ok = false, error = 'forbidden' }
    end

    state.status = 'declined'
    MySQL.update.await('UPDATE phone_calls SET status = ?, ended_at = NOW() WHERE id = ?', { 'declined', callId })
    if state.callerSrc then TriggerClientEvent('pulse-phone:client:callUpdate', state.callerSrc, state) end
    if state.calleeSrc then TriggerClientEvent('pulse-phone:client:callUpdate', state.calleeSrc, state) end
    Pulse.Calls.active[callId] = nil
    return { ok = true }
end)

lib.callback.register('pulse-phone:server:endCall', function(source, callId)
    callId = tonumber(callId)
    local state = callId and Pulse.Calls.active[callId]
    if not state then return { ok = false } end
    if source ~= state.callerSrc and source ~= state.calleeSrc then
        return { ok = false, error = 'forbidden' }
    end

    local duration = 0
    if state.answeredAt then
        duration = math.max(0, os.time() - state.answeredAt)
    end
    state.status = 'ended'
    state.duration = duration
    MySQL.update.await(
        'UPDATE phone_calls SET status = ?, ended_at = NOW(), duration = ? WHERE id = ?',
        { 'ended', duration, callId }
    )
    if state.callerSrc then TriggerClientEvent('pulse-phone:client:callUpdate', state.callerSrc, state) end
    if state.calleeSrc then TriggerClientEvent('pulse-phone:client:callUpdate', state.calleeSrc, state) end
    Pulse.Calls.active[callId] = nil
    return { ok = true }
end)

function Pulse.Calls.OnPlayerDropped(src, _citizenid)
    for callId, state in pairs(Pulse.Calls.active) do
        if state.callerSrc == src or state.calleeSrc == src then
            state.status = 'ended'
            if state.callerSrc and state.callerSrc ~= src then
                TriggerClientEvent('pulse-phone:client:callUpdate', state.callerSrc, state)
            end
            if state.calleeSrc and state.calleeSrc ~= src then
                TriggerClientEvent('pulse-phone:client:callUpdate', state.calleeSrc, state)
            end
            MySQL.update.await('UPDATE phone_calls SET status = ?, ended_at = NOW() WHERE id = ?', { 'ended', callId })
            Pulse.Calls.active[callId] = nil
        end
    end
end
