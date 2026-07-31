CreateThread(function()
    exports.ox_target:addSphereZone({
        coords = Config.Start,
        radius = 1.5,
        options = {
            {
                name = 'vibe_jewelry_start',
                icon = 'fa-solid fa-gem',
                label = 'Lancer le braquage',
                onSelect = function()
                    TriggerServerEvent('vibe_crimi_jewelry:server:start')
                end,
            },
        },
    })
    for i, coords in ipairs(Config.Vitrines) do
        exports.ox_target:addSphereZone({
            coords = coords,
            radius = 0.9,
            options = {
                {
                    name = 'vibe_jewelry_vitrine_' .. i,
                    icon = 'fa-solid fa-hammer',
                    label = 'Casser la vitrine',
                    onSelect = function()
                        if lib.progressCircle({
                            duration = Config.Duration,
                            label = 'Cassage...',
                            position = 'bottom',
                            canCancel = true,
                            disable = { move = true, combat = true },
                            anim = { dict = 'missheist_jewel', clip = 'smash_case' },
                        }) then
                            TriggerServerEvent('vibe_crimi_jewelry:server:loot', i)
                        end
                    end,
                },
            },
        })
    end
end)
