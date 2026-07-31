CreateThread(function()
    for _, loc in ipairs(Config.Locations) do
        exports.ox_target:addSphereZone({
            coords = loc.coords,
            radius = 1.5,
            options = {
                {
                    name = 'vibe_evidence_' .. loc.id,
                    icon = 'fa-solid fa-box-archive',
                    label = loc.label,
                    canInteract = function()
                        return exports.vibe_api:IsPolice(true)
                    end,
                    onSelect = function()
                        TriggerServerEvent('vibe_evidence:server:open', loc.id)
                    end,
                },
            },
        })
    end
end)
