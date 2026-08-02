local function playersWithJob()
    local list = {}
    for _, src in pairs(GetPlayers()) do
        src = tonumber(src)
        local job = exports.rr_api:GetJob(src)
        if job and Config.Jobs[job.name] and job.onduty then
            list[#list+1] = src
        end
    end
    return list
end

RegisterNetEvent('rr_dispatch:server:alert', function(code, message, coords)
    local src = source
    local payload = {
        code = tostring(code or 'ALERT'),
        message = tostring(message or ''):sub(1, 200),
        coords = coords,
        from = exports.rr_api:GetCharName(src),
    }
    for _, id in ipairs(playersWithJob()) do
        TriggerClientEvent('rr_dispatch:client:alert', id, payload)
    end
    exports.rr_api:Notify(src, 'Dispatch', 'Ton alerte a été transmise.', 'success')
end)

AddEventHandler('rr_dispatch:server:log', function(kind, data)
    print(('[rr_dispatch] %s %s'):format(kind, json.encode(data or {})))
end)

exports('Alert', function(code, message, coords)
    local payload = { code = code, message = message, coords = coords, from = 'Système' }
    for _, id in ipairs(playersWithJob()) do
        TriggerClientEvent('rr_dispatch:client:alert', id, payload)
    end
end)
