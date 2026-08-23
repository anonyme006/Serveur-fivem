local dutyPoints = {}

local function setupDuty()
    for job, coords in pairs(Config.DutyLocations) do
        if GetResourceState('ox_target') == 'started' then
            exports.ox_target:addSphereZone({
                coords = coords,
                radius = 1.5,
                debug = Config.Debug,
                options = {
                    {
                        name = 'rp_duty_' .. job,
                        icon = 'fa-solid fa-briefcase',
                        label = 'Prise / Fin de service',
                        canInteract = function()
                            local pd = exports.qbx_core:GetPlayerData()
                            return pd and pd.job and pd.job.name == job
                        end,
                        onSelect = function()
                            lib.callback.await('rp_jobs:toggleDuty', false)
                        end,
                    }
                }
            })
        end
        dutyPoints[job] = coords
    end
end

CreateThread(function()
    Wait(1500)
    setupDuty()
end)

RegisterCommand('duty', function()
    lib.callback.await('rp_jobs:toggleDuty', false)
end, false)
