CreateThread(function()
    for i, loc in ipairs(Config.Locations) do
        exports.ox_target:addSphereZone({
            coords = loc.coords,
            radius = Config.Radius,
            options = {
                {
                    name = 'rr_duty_' .. i,
                    icon = 'fa-solid fa-clipboard-user',
                    label = loc.label,
                    canInteract = function()
                        local job = exports.rr_api:GetJob()
                        return job and job.name == loc.job
                    end,
                    onSelect = function()
                        TriggerServerEvent('rr_duty:server:toggle', loc.job)
                    end,
                },
            },
        })
    end
end)

RegisterCommand('duty', function()
    TriggerServerEvent('rr_duty:server:toggle')
end, false)
