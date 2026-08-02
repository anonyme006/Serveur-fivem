CreateThread(function()
    while true do
        local wait = 800
        local veh = cache.vehicle
        if veh and cache.seat == -1 then
            wait = 200
            local allowed = lib.callback.await('rr_vehicle_restrictions:server:canDrive', false, GetEntityModel(veh), GetVehicleClass(veh))
            if not allowed then
                TaskLeaveVehicle(cache.ped, veh, 16)
                exports.rr_api:Notify('Véhicule', 'Tu ne peux pas conduire ce véhicule.', 'error')
                Wait(1500)
            end
        end
        Wait(wait)
    end
end)
