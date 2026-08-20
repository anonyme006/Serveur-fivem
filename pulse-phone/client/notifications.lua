--[[
    Pulse Phone — Notifications client
]]

Pulse = Pulse or {}
Pulse.Notifications = Pulse.Notifications or {}

---@param data table
function Pulse.Notifications.Push(data)
    if type(data) ~= 'table' then return end
    SendNUIMessage({
        action = 'notifications:push',
        data = {
            type = data.type or 'info',
            title = data.title or 'Pulse',
            body = data.body or '',
            duration = data.duration or Config.Notifications.defaultDuration,
            payload = data.payload,
        },
    })
    if Config.Sounds.enabled then
        local soundId = data.sound or 'notification'
        SendNUIMessage({ action = 'sounds:play', data = { id = soundId } })
    end
end

RegisterNetEvent('pulse-phone:client:notify', function(data)
    Pulse.Notifications.Push(data)
end)

RegisterNUICallback('notifications:markRead', function(data, cb)
    if data and data.id then
        TriggerServerEvent('pulse-phone:server:markNotificationRead', data.id)
    end
    cb({ ok = true })
end)
