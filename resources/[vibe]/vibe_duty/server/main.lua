RegisterNetEvent('vibe_duty:server:toggle', function(expectedJob)
    local src = source
    local player = exports.vibe_api:GetPlayer(src)
    if not player then return end
    local job = player.PlayerData.job
    if expectedJob and job.name ~= expectedJob then
        exports.vibe_api:Notify(src, 'Service', 'Tu n\'es pas dans ce métier.', 'error')
        return
    end
    local newState = not job.onduty
    player.Functions.SetJobDuty(newState)
    exports.vibe_api:Notify(src, 'Service', newState and 'Tu es en service.' or 'Tu es hors service.', newState and 'success' or 'inform')
    TriggerEvent('vibe_duty:server:changed', src, job.name, newState)
end)
