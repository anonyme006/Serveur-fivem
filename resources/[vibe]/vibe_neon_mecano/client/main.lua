CreateThread(function()
    local g = Config.Garage
    exports.ox_target:addSphereZone({
        coords = g.coords,
        radius = 2.0,
        options = {{
            name = 'neon_garage',
            icon = 'fa-solid fa-truck-pickup',
            label = 'Garage Neon Mechanic',
            canInteract = Neon.IsMechanic,
            onSelect = function()
                local options = {}
                for _, v in ipairs(g.vehicles) do
                    options[#options + 1] = {
                        title = v.label,
                        icon = 'truck',
                        onSelect = function()
                            TriggerServerEvent('vibe_neon_mecano:server:spawnVehicle', v.model)
                        end,
                    }
                end
                lib.registerContext({ id = 'neon_garage_menu', title = 'Véhicules de service', options = options })
                lib.showContext('neon_garage_menu')
            end,
        }},
    })
end)

RegisterNetEvent('vibe_neon_mecano:client:spawnVehicle', function(model)
    local s = Config.Garage.spawn
    local hash = joaat(model)
    lib.requestModel(hash)
    local veh = CreateVehicle(hash, s.x, s.y, s.z, s.w, true, false)
    SetPedIntoVehicle(cache.ped, veh, -1)
    SetVehicleNumberPlateText(veh, 'NEON')
    SetModelAsNoLongerNeeded(hash)
    Neon.Notify(nil, 'Véhicule de service sorti.', 'success')
end)

-- Alerte automatique quand un mécano prend son service
RegisterNetEvent('QBCore:Client:SetDuty', function(onDuty)
    if onDuty and Neon.IsMechanic() then
        Neon.Notify(nil, 'Bipeur activé — tu recevras les appels de dépannage.', 'inform')
    end
end)

RegisterNetEvent('qbx_core:client:onJobUpdate', function()
    -- noop — rafraîchit le cache job via vibe_api callbacks
end)
