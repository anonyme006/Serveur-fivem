CreateThread(function()
    Wait(1000)
    local success, message = exports.qbx_core:CreateJobs(SharedJobs)
    if Config.Debug then
        print(('[rp_jobs] CreateJobs: %s %s'):format(tostring(success), tostring(message)))
    else
        print('[rp_jobs] Métiers custom enregistrés (burgershot, uwu, government, doj)')
    end
end)

lib.callback.register('rp_jobs:toggleDuty', function(source)
    local player = exports.rp_core:GetPlayer(source)
    if not player then return false end
    local job = player.PlayerData.job
    if not job then return false end
    local newState = not job.onduty
    player.Functions.SetJobDuty(newState)
    exports.rp_core:Notify(source, newState and L('duty_on') or L('duty_off'), 'inform')
    TriggerEvent('rp_core:server:jobUpdate', source, player.PlayerData.job)
    return newState
end)
