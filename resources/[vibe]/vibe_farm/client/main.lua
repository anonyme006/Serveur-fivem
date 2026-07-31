CreateThread(function()
    for i, z in ipairs(Config.Pick) do
        exports.ox_target:addSphereZone({
            coords = z.coords,
            radius = z.radius,
            options = {{
                name = 'vibe_farm_' .. i,
                icon = 'fa-solid fa-seedling',
                label = z.label,
                onSelect = function()
                    if lib.progressCircle({
                        duration = z.duration,
                        label = z.label,
                        position = 'bottom',
                        canCancel = true,
                        disable = { move = true, car = true, combat = true },
                        anim = { dict = 'amb@world_human_gardener_plant@male@base', clip = 'base' },
                    }) then
                        TriggerServerEvent('vibe_farm:server:pick', i)
                    end
                end,
            }},
        })
    end
    exports.ox_target:addSphereZone({
        coords = Config.Sell.coords,
        radius = 1.5,
        options = {{
            name = 'vibe_farm_sell',
            icon = 'fa-solid fa-hand-holding-dollar',
            label = Config.Sell.label,
            onSelect = function()
                TriggerServerEvent('vibe_farm:server:sell')
            end,
        }},
    })
end)
