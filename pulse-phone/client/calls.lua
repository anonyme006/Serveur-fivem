--[[
    Pulse Phone — Appels (client) — fondation
    Audio via pma-voice (call channel)
]]

Pulse = Pulse or {}
Pulse.Calls = Pulse.Calls or {}

Pulse.Calls.active = nil -- { id, number, name, direction, status }

local function setCallState(state)
    Pulse.Calls.active = state
    SendNUIMessage({ action = 'calls:update', data = state })
end

RegisterNUICallback('calls:start', function(data, cb)
    if type(data) ~= 'table' or not data.number then
        cb({ ok = false })
        return
    end
    local result = lib.callback.await('pulse-phone:server:startCall', false, data.number, data.companyId)
    cb(result or { ok = false })
end)

RegisterNUICallback('calls:accept', function(data, cb)
    local callId = data and data.callId
    local result = lib.callback.await('pulse-phone:server:acceptCall', false, callId)
    cb(result or { ok = false })
end)

RegisterNUICallback('calls:decline', function(data, cb)
    local callId = data and data.callId
    local result = lib.callback.await('pulse-phone:server:declineCall', false, callId)
    cb(result or { ok = false })
end)

RegisterNUICallback('calls:end', function(data, cb)
    local callId = data and data.callId
    local result = lib.callback.await('pulse-phone:server:endCall', false, callId)
    cb(result or { ok = false })
end)

RegisterNetEvent('pulse-phone:client:callIncoming', function(payload)
    setCallState(payload)
    if Config.Sounds.enabled then
        SendNUIMessage({ action = 'sounds:play', data = { id = 'incomingCall' } })
    end
    SendNUIMessage({
        action = 'notifications:push',
        data = {
            type = 'call',
            title = L('incoming_call'),
            body = payload.name or payload.number,
            payload = payload,
        },
    })
end)

RegisterNetEvent('pulse-phone:client:callUpdate', function(payload)
    setCallState(payload)
    if payload and payload.status == 'accepted' and payload.channel then
        exports['pma-voice']:setCallChannel(payload.channel)
    end
    if payload and (payload.status == 'ended' or payload.status == 'declined' or payload.status == 'missed') then
        exports['pma-voice']:setCallChannel(0)
        Pulse.Calls.active = nil
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    exports['pma-voice']:setCallChannel(0)
end)
