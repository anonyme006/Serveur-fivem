CreateThread(function()
    for i, loc in ipairs(Config.Locations) do
        exports.ox_target:addSphereZone({
            coords = loc.coords,
            radius = 1.8,
            options = {
                {
                    name = 'vibe_whitening_' .. i,
                    icon = 'fa-solid fa-money-bill-transfer',
                    label = loc.label,
                    onSelect = function()
                        local input = lib.inputDialog('Blanchiment', {
                            { type = 'number', label = 'Montant sale', required = true, min = Config.MinAmount, max = Config.MaxAmount },
                        })
                        if not input then return end
                        if lib.progressCircle({
                            duration = Config.Duration,
                            label = 'Blanchiment...',
                            position = 'bottom',
                            canCancel = true,
                            disable = { move = true, combat = true },
                        }) then
                            TriggerServerEvent('vibe_crimi_whitening:server:wash', i, tonumber(input[1]))
                        end
                    end,
                },
            },
        })
    end
end)
