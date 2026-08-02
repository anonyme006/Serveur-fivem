local last = 0
exports.ox_target:addGlobalPed({
    {
        name = 'rr_deal',
        icon = 'fa-solid fa-handshake',
        label = 'Proposer un deal',
        distance = 2.0,
        canInteract = function(entity)
            return not IsPedAPlayer(entity) and not IsPedDeadOrDying(entity, true) and not IsPedInAnyVehicle(entity, false)
        end,
        onSelect = function()
            if GetGameTimer() - last < Config.Cooldown * 1000 then return end
            local options = {}
            for item, data in pairs(Config.Items) do
                options[#options+1] = {
                    title = item,
                    description = ('~$%s'):format(data.price),
                    onSelect = function()
                        if lib.progressCircle({
                            duration = Config.Duration,
                            label = 'Negociation...',
                            position = 'bottom',
                            canCancel = true,
                            disable = { move = true, combat = true },
                        }) then
                            last = GetGameTimer()
                            local c = GetEntityCoords(cache.ped)
                            TriggerServerEvent('rr_crimi_deal:server:sell', item, { x = c.x, y = c.y, z = c.z })
                        end
                    end,
                }
            end
            lib.registerContext({ id = 'rr_deal', title = 'Deal', options = options })
            lib.showContext('rr_deal')
        end,
    },
})
