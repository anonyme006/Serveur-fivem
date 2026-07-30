local MODULE = 'blips'

CoreCreator.RegisterModule(MODULE, {})

RegisterNetEvent('core_creator:blips:requestSync', function()
    local src = source
    TriggerClientEvent('core_creator:blips:sync', src, Database.GetAll(MODULE, true))
end)

AddEventHandler('core_creator:databaseReady', function()
    Wait(100)
    TriggerClientEvent('core_creator:blips:sync', -1, Database.GetAll(MODULE, true))
end)

AddEventHandler('core_creator:entityChanged', function(moduleName)
    if moduleName ~= MODULE then return end
    TriggerClientEvent('core_creator:blips:sync', -1, Database.GetAll(MODULE, true))
end)
