if Config.Modules and Config.Modules.core == false then return end

--[[
    Hooks client — demande les clés au serveur après achat / spawn.
]]

if not Config.Keys.enabled then return end

--- Achat qbx_vehicleshop / forks (évite double si serveur a déjà hooké)
RegisterNetEvent('qbx_vehicleshop:client:successfulBuy', function(vehicle, plate)
    if not Config.Keys.giveOnPurchase then return end
    local p = type(vehicle) == 'table' and (vehicle.plate or plate) or plate
    local label = type(vehicle) == 'table' and (vehicle.model or vehicle.name) or vehicle
    if type(p) == 'string' and p ~= '' then
        TriggerServerEvent('qbx_ressources:keys:onVehicleAcquired', p, label or p)
    end
end)

RegisterNetEvent('qb-vehicleshop:client:buyShowroomVehicle', function(data)
    if not Config.Keys.giveOnPurchase then return end
    if type(data) ~= 'table' or not data.plate then return end
    TriggerServerEvent('qbx_ressources:keys:onVehicleAcquired', data.plate, data.model or data.plate)
end)

--- Compat scripts qui trigger un event client générique
AddEventHandler('qbx_ressources:client:giveVehicleKey', function(plate, label)
    if not plate then return end
    TriggerServerEvent('qbx_ressources:keys:onVehicleAcquired', plate, label or plate)
end)
