--[[
    Pulse Phone — Events services côté client
]]

RegisterNetEvent('pulse-phone:client:serviceRequest', function(payload)
    SendNUIMessage({ action = 'services:request', data = payload })
    if not Pulse.Client.IsOpen() then
        Pulse.Notifications.Push({
            type = 'service',
            title = 'SERVICE',
            body = payload and payload.description or L('new_service_request'),
            sound = 'company',
            payload = payload,
        })
    end
end)

RegisterNetEvent('pulse-phone:client:serviceUpdate', function(payload)
    SendNUIMessage({ action = 'services:update', data = payload })
end)

RegisterNetEvent('pulse-phone:client:messageNew', function(payload)
    SendNUIMessage({ action = 'messages:new', data = payload })
end)
