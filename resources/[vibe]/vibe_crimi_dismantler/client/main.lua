CreateThread(function()
    exports.ox_target:addSphereZone({
        coords = Config.Yard,
        radius = Config.Radius,
        options = {{
            name = 'vibe_dismantle',
            icon = 'fa-solid fa-car-burst',
            label = 'Detruire le vehicule',
            onSelect = function()
                local veh = cache.vehicle
                if not veh then
                    exports.vibe_api:Notify('Casse', 'Monte dans un vehicule.', 'error')
                    return
                end
                if lib.progressCircle({
                    duration = Config.Duration,
                    label = 'Decoupe...',
                    position = 'bottom',
                    canCancel = true,
                    disable = { move = true, car = true, combat = true },
                }) then
                    local netId = NetworkGetNetworkIdFromEntity(veh)
                    TriggerServerEvent('vibe_crimi_dismantler:server:scrap', netId)
                end
            end,
        }},
    })
end)

RegisterNetEvent('vibe_crimi_dismantler:client:delete', function(netId)
    local veh = NetworkGetEntityFromNetworkId(netId)
    if veh ~= 0 and DoesEntityExist(veh) then
        SetEntityAsMissionEntity(veh, true, true)
        DeleteVehicle(veh)
    end
end)
