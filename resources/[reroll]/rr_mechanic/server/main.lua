RegisterNetEvent('rr_mechanic:server:repair', function(netId)
    local src = source
    local job = exports.rr_api:GetJob(src)
    if not job or not Config.Jobs[job.name] or not job.onduty then return end
    TriggerClientEvent('rr_mechanic:client:fixVehicle', -1, netId)
    exports.rr_api:Notify(src, 'Mecano', 'Vehicule repare.', 'success')
end)
