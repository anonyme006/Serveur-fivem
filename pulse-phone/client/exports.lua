--[[
    Pulse Phone — Exports client
]]

exports('OpenPhone', function()
    Pulse.Client.OpenPhone()
end)

exports('ClosePhone', function()
    Pulse.Client.ClosePhone()
end)

exports('TogglePhone', function()
    Pulse.Client.TogglePhone()
end)

exports('IsPhoneOpen', function()
    return Pulse.Client.IsOpen()
end)

exports('SendNotification', function(data)
    Pulse.Notifications.Push(data)
end)

exports('StartCall', function(number)
    return lib.callback.await('pulse-phone:server:startCall', false, number)
end)
