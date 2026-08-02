CreateThread(function()
    for i, zone in ipairs(Config.PickZones) do
        exports.ox_target:addSphereZone({
            coords = zone.coords,
            radius = zone.radius,
            options = {{
                name = 'rr_weed_pick_' .. i,
                icon = 'fa-solid fa-cannabis',
                label = zone.label,
                onSelect = function()
                    if lib.progressCircle({
                        duration = zone.duration,
                        label = zone.label,
                        position = 'bottom',
                        useWhileDead = false,
                        canCancel = true,
                        disable = { move = true, car = true, combat = true },
                        anim = { dict = 'amb@world_human_gardener_plant@male@base', clip = 'base' },
                    }) then
                        TriggerServerEvent('rr_crimi_weed:server:pick', i)
                    end
                end,
            }},
        })
    end

    local p = Config.Process
    exports.ox_target:addSphereZone({
        coords = p.coords,
        radius = p.radius,
        options = {{
            name = 'rr_weed_process',
            icon = 'fa-solid fa-flask',
            label = p.label,
            onSelect = function()
                if lib.progressCircle({
                    duration = p.duration,
                    label = p.label,
                    position = 'bottom',
                    canCancel = true,
                    disable = { move = true, car = true, combat = true },
                }) then
                    TriggerServerEvent('rr_crimi_weed:server:process')
                end
            end,
        }},
    })

    local s = Config.Sell
    exports.ox_target:addSphereZone({
        coords = s.coords,
        radius = 1.5,
        options = {{
            name = 'rr_weed_sell',
            icon = 'fa-solid fa-dollar-sign',
            label = s.label,
            onSelect = function()
                TriggerServerEvent('rr_crimi_weed:server:sell')
            end,
        }},
    })
end)
