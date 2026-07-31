RegisterNetEvent('vibe_mechanic:server:repair', function(netId)
    local src = source
    local job = exports.vibe_api:GetJob(src)
    if not job or not Config.Jobs[job.name] or not job.onduty then return end
    TriggerClientEvent('vibe_mechanic:client:fixVehicle', -1, netId)
    exports.vibe_api:Notify(src, 'Mecano', 'Vehicule repare.', 'success')
end)
