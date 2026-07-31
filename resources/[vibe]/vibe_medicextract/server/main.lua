local function isEms(src)
    local job = exports.vibe_api:GetJob(src)
    return job and Config.Jobs[job.name] and job.onduty
end

RegisterNetEvent('vibe_medicextract:server:revive', function(target)
    local src = source
    if not isEms(src) then return end
    TriggerClientEvent('vibe_medicextract:client:revive', target)
    exports.vibe_api:Notify(src, 'EMS', 'Patient reanime.', 'success')
end)

RegisterNetEvent('vibe_medicextract:server:heal', function(target)
    local src = source
    if not isEms(src) then return end
    TriggerClientEvent('vibe_medicextract:client:heal', target)
end)

RegisterNetEvent('vibe_medicextract:server:extract', function(target)
    local src = source
    if not isEms(src) then return end
    TriggerClientEvent('vibe_medicextract:client:extract', target)
    exports.vibe_api:Notify(src, 'EMS', 'Extraction vers hopital.', 'inform')
end)
