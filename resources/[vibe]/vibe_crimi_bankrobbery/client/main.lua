CreateThread(function()
    for _, bank in ipairs(Config.Banks) do
        exports.ox_target:addSphereZone({
            coords = bank.hack,
            radius = 1.2,
            options = {
                {
                    name = 'vibe_bank_hack_' .. bank.id,
                    icon = 'fa-solid fa-laptop-code',
                    label = 'Hack du panneau',
                    onSelect = function()
                        local can = lib.callback.await('vibe_crimi_bankrobbery:server:canStart', false, bank.id)
                        if not can then return end
                        local success = lib.skillCheck({'easy', 'easy', { areaSize = 50, speedMultiplier = 1.2 }}, {'w', 'a', 's', 'd'})
                        if success then
                            TriggerServerEvent('vibe_crimi_bankrobbery:server:hacked', bank.id)
                        else
                            exports.vibe_api:Notify('Braquage', 'Hack raté.', 'error')
                        end
                    end,
                },
            },
        })
        exports.ox_target:addSphereZone({
            coords = bank.vault,
            radius = 1.4,
            options = {
                {
                    name = 'vibe_bank_loot_' .. bank.id,
                    icon = 'fa-solid fa-vault',
                    label = 'Vider le coffre',
                    onSelect = function()
                        if lib.progressCircle({
                            duration = Config.Duration,
                            label = 'Ramassage des liasses...',
                            position = 'bottom',
                            canCancel = true,
                            disable = { move = true, combat = true },
                            anim = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab' },
                        }) then
                            TriggerServerEvent('vibe_crimi_bankrobbery:server:loot', bank.id)
                        end
                    end,
                },
            },
        })
    end
end)
