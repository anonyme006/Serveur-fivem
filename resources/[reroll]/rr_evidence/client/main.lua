CreateThread(function()
    for _, loc in ipairs(Config.Locations) do
        exports.ox_target:addSphereZone({
            coords = loc.coords,
            radius = 1.5,
            options = {
                {
                    name = 'rr_evidence_' .. loc.id,
                    icon = 'fa-solid fa-box-archive',
                    label = loc.label,
                    canInteract = function()
                        return exports.rr_api:IsPolice(true)
                    end,
                    onSelect = function()
                        TriggerServerEvent('rr_evidence:server:open', loc.id)
                    end,
                },
            },
        })
    end
end)
