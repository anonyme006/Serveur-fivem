local function isEms(src)
    local job = exports.rr_api:GetJob(src)
    return job and Config.Jobs[job.name] and job.onduty
end

RegisterNetEvent('rr_medicextract:server:revive', function(target)
    local src = source
    if not isEms(src) then return end
    TriggerClientEvent('rr_medicextract:client:revive', target)
    exports.rr_api:Notify(src, 'EMS', 'Patient reanime.', 'success')
end)

RegisterNetEvent('rr_medicextract:server:heal', function(target)
    local src = source
    if not isEms(src) then return end
    TriggerClientEvent('rr_medicextract:client:heal', target)
end)

RegisterNetEvent('rr_medicextract:server:extract', function(target)
    local src = source
    if not isEms(src) then return end
    TriggerClientEvent('rr_medicextract:client:extract', target)
    exports.rr_api:Notify(src, 'EMS', 'Extraction vers hopital.', 'inform')
end)
