--[[
    Pulse Phone — Events + NUI Services
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

RegisterNetEvent('pulse-phone:client:companyMessage', function(payload)
    SendNUIMessage({ action = 'services:companyMessage', data = payload })
end)

-- NUI Services
RegisterNUICallback('services:bootstrap', function(_, cb)
    local data = lib.callback.await('pulse-phone:server:getServicesBootstrap', false)
    cb(data or { companies = {}, me = { isEmployee = false } })
end)

RegisterNUICallback('services:getCompanies', function(_, cb)
    local list = lib.callback.await('pulse-phone:server:getCompanies', false) or {}
    cb(list)
end)

RegisterNUICallback('services:createRequest', function(data, cb)
    local result = lib.callback.await('pulse-phone:server:createServiceRequest', false, data)
    cb(result or { ok = false })
end)

RegisterNUICallback('services:acceptRequest', function(data, cb)
    local result = lib.callback.await('pulse-phone:server:acceptServiceRequest', false, data and data.id)
    cb(result or { ok = false })
end)

RegisterNUICallback('services:setWaypoint', function(data, cb)
    if type(data) ~= 'table' or not data.x or not data.y then
        cb({ ok = false })
        return
    end
    SetNewWaypoint(data.x + 0.0, data.y + 0.0)
    lib.notify({ title = 'Pulse', description = L('waypoint_set'), type = 'success' })
    cb({ ok = true })
end)

RegisterNUICallback('services:toggleDuty', function(_, cb)
    local result = lib.callback.await('pulse-phone:server:toggleDuty', false)
    cb(result or { ok = false })
end)

RegisterNUICallback('services:getManagement', function(_, cb)
    local result = lib.callback.await('pulse-phone:server:getCompanyManagement', false)
    cb(result or { ok = false })
end)

RegisterNUICallback('services:setStatus', function(data, cb)
    local result = lib.callback.await('pulse-phone:server:setCompanyStatus', false, data and data.companyId, data and data.status)
    cb(result or { ok = false })
end)

RegisterNUICallback('services:getThreads', function(_, cb)
    local threads = lib.callback.await('pulse-phone:server:getCompanyThreads', false) or {}
    cb(threads)
end)

RegisterNUICallback('services:getChat', function(data, cb)
    local result = lib.callback.await('pulse-phone:server:getCompanyChat', false, data)
    cb(result or { ok = false })
end)

RegisterNUICallback('services:sendMessage', function(data, cb)
    local result = lib.callback.await('pulse-phone:server:sendCompanyMessage', false, data)
    cb(result or { ok = false })
end)
