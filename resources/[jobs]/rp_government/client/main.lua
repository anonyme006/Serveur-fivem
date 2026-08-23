CreateThread(function()
    Wait(2000)
    if GetResourceState('ox_target') ~= 'started' then return end
    exports.ox_target:addSphereZone({
        coords = Config.Duty,
        radius = 1.5,
        options = {
            {
                name = 'rp_government_duty',
                icon = 'fa-solid fa-briefcase',
                label = 'Service — ' .. Config.Label,
                canInteract = function()
                    local pd = exports.qbx_core:GetPlayerData()
                    return pd and pd.job and pd.job.name == Config.Job
                end,
                onSelect = function()
                    if GetResourceState('rp_jobs') == 'started' then
                        lib.callback.await('rp_jobs:toggleDuty', false)
                    end
                end,
            },
            {
                name = 'rp_government_stash',
                icon = 'fa-solid fa-box',
                label = 'Coffre — ' .. Config.Label,
                canInteract = function()
                    local pd = exports.qbx_core:GetPlayerData()
                    return pd and pd.job and pd.job.name == Config.Job and pd.job.onduty
                end,
                onSelect = function()
                    exports.ox_inventory:openInventory('stash', Config.Stash)
                end,
            },
        }
    })
end)
