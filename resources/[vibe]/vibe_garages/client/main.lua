local function openGarage(garage)
    local vehicles = lib.callback.await('vibe_garages:server:list', false, garage.id)
    if not vehicles or #vehicles == 0 then
        lib.notify({ title = garage.label, description = 'Aucun véhicule rangé ici.', type = 'inform' })
        return
    end

    local options = {}
    for _, veh in ipairs(vehicles) do
        options[#options + 1] = {
            title = ('%s — %s'):format(veh.vehicle or 'Véhicule', veh.plate or '?'),
            description = 'Sortir ce véhicule',
            onSelect = function()
                TriggerServerEvent('vibe_garages:server:spawn', garage.id, veh.plate)
            end,
        }
    end

    lib.registerContext({ id = 'vibe_garage_' .. garage.id, title = garage.label, options = options })
    lib.showContext('vibe_garage_' .. garage.id)
end

CreateThread(function()
    for _, garage in ipairs(Config.Garages) do
        exports.ox_target:addSphereZone({
            coords = garage.coords,
            radius = 2.0,
            debug = false,
            options = {
                {
                    name = 'vibe_garage_' .. garage.id,
                    icon = 'fa-solid fa-warehouse',
                    label = garage.label,
                    onSelect = function()
                        openGarage(garage)
                    end,
                },
            },
        })
    end
end)

RegisterNetEvent('vibe_garages:client:spawnVehicle', function(model, coords, plate)
    local hash = joaat(model)
    lib.requestModel(hash)
    local veh = CreateVehicle(hash, coords.x, coords.y, coords.z, coords.w, true, false)
    SetVehicleNumberPlateText(veh, plate or 'VIBE')
    SetPedIntoVehicle(cache.ped, veh, -1)
    SetModelAsNoLongerNeeded(hash)
end)
