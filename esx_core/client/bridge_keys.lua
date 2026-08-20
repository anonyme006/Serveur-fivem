--[[
    Hooks client — demande les clés au serveur après achat / spawn.
]]

if not Config.Keys.enabled then return end

--- Achat esx_concessionnaire (un seul hook pour éviter le double envoi)
RegisterNetEvent('esx_concessionnaire:spawnPurchased', function(data)
    if not Config.Keys.giveOnPurchase then return end
    if type(data) ~= 'table' or not data.plate then return end
    TriggerServerEvent('esx_core:keys:onVehicleAcquired', data.plate, data.model or data.plate)
end)

--- Compat scripts qui trigger un event client générique
AddEventHandler('esx_core:client:giveVehicleKey', function(plate, label)
    if not plate then return end
    TriggerServerEvent('esx_core:keys:onVehicleAcquired', plate, label or plate)
end)
