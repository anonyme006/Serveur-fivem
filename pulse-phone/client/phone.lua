--[[
    Pulse Phone — État UI / shell
]]

Pulse = Pulse or {}
Pulse.Phone = Pulse.Phone or {}

Pulse.Phone.state = {
    locked = true,
    app = nil,
}

RegisterNUICallback('phone:unlock', function(_, cb)
    Pulse.Phone.state.locked = false
    cb({ ok = true })
end)

RegisterNUICallback('phone:lock', function(_, cb)
    Pulse.Phone.state.locked = true
    Pulse.Phone.state.app = nil
    cb({ ok = true })
end)

RegisterNUICallback('phone:openApp', function(data, cb)
    if type(data) ~= 'table' or type(data.app) ~= 'string' then
        cb({ ok = false })
        return
    end
    if Config.Apps[data.app] == false then
        cb({ ok = false, error = 'disabled' })
        return
    end
    Pulse.Phone.state.app = data.app
    cb({ ok = true, app = data.app })
end)

RegisterNUICallback('phone:closeApp', function(_, cb)
    Pulse.Phone.state.app = nil
    cb({ ok = true })
end)

--- Met à jour status bar (heure gérée côté NUI; batterie/signal poussés ponctuellement)
function Pulse.Phone.PushStatus(partial)
    if not Pulse.Client.IsOpen() then return end
    SendNUIMessage({
        action = 'phone:status',
        data = partial or {},
    })
end

-- Batterie simulée légère (pas de boucle 0ms)
CreateThread(function()
    while true do
        Wait(60000)
        if Pulse.Client.IsOpen() then
            Pulse.Phone.PushStatus({
                battery = math.random(15, 100),
                signal = math.random(2, 4),
            })
        end
    end
end)
