CreateThread(function()
    local c = Config.Cook
    exports.ox_target:addSphereZone({
        coords = c.coords,
        radius = 1.6,
        options = {{
            name = 'vibe_meth_cook',
            icon = 'fa-solid fa-flask-vial',
            label = c.label,
            onSelect = function()
                if lib.progressCircle({
                    duration = c.duration,
                    label = c.label,
                    position = 'bottom',
                    canCancel = true,
                    disable = { move = true, combat = true },
                }) then
                    TriggerServerEvent('vibe_crimi_methkitchen:server:cook')
                end
            end,
        }},
    })
    exports.ox_target:addSphereZone({
        coords = Config.Sell.coords,
        radius = 1.5,
        options = {{
            name = 'vibe_meth_sell',
            icon = 'fa-solid fa-dollar-sign',
            label = 'Vendre meth',
            onSelect = function()
                TriggerServerEvent('vibe_crimi_methkitchen:server:sell')
            end,
        }},
    })
end)
