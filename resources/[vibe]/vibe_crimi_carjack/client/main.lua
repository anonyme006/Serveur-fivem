local last = 0

exports.ox_target:addGlobalVehicle({
    {
        name = 'vibe_carjack',
        icon = 'fa-solid fa-key',
        label = 'Crocheter / démarrer',
        bones = { 'door_dside_f', 'seat_dside_f' },
        canInteract = function(entity)
            return not IsPedAPlayer(GetPedInVehicleSeat(entity, -1)) or GetPedInVehicleSeat(entity, -1) == 0
        end,
        onSelect = function(data)
            if GetGameTimer() - last < Config.Cooldown * 1000 then
                exports.vibe_api:Notify('Carjack', 'Cooldown actif.', 'error')
                return
            end
            local veh = data.entity
            if Config.HotwireItem then
                local has = lib.callback.await('vibe_crimi_carjack:server:hasItem', false)
                if not has then
                    exports.vibe_api:Notify('Carjack', 'Il te faut un lockpick.', 'error')
                    return
                end
            end
            if lib.progressCircle({
                duration = Config.Duration,
                label = 'Crochetage...',
                position = 'bottom',
                canCancel = true,
                disable = { car = true, move = true, combat = true },
                anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer' },
            }) then
                last = GetGameTimer()
                SetVehicleDoorsLocked(veh, 1)
                SetVehicleEngineOn(veh, true, true, false)
                TaskWarpPedIntoVehicle(cache.ped, veh, -1)
                local coords = GetEntityCoords(veh)
                TriggerServerEvent('vibe_crimi_carjack:server:done', { x = coords.x, y = coords.y, z = coords.z })
            end
        end,
    },
})
