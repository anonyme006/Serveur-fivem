-- Creator helpers shared by admin tools

RegisterNetEvent('core_creator:syncModule', function(moduleName)
    if moduleName == 'shops' then TriggerServerEvent('core_creator:shops:requestSync') end
    if moduleName == 'blips' then TriggerServerEvent('core_creator:blips:requestSync') end
    if moduleName == 'farms' then TriggerServerEvent('core_creator:farms:requestSync') end
    if moduleName == 'jobs' then TriggerServerEvent('core_creator:jobs:requestSync') end
    if moduleName == 'garages' then TriggerServerEvent('core_creator:garages:requestSync') end
    if moduleName == 'gangs' then TriggerServerEvent('core_creator:gangs:requestSync') end
    if moduleName == 'apartments' then TriggerServerEvent('core_creator:apartments:requestSync') end
    if moduleName == 'robberies' then TriggerServerEvent('core_creator:robberies:requestSync') end
end)

RegisterNetEvent('core_creator:client:exportData', function(dump)
    SendNUIMessage({ action = 'exportDump', data = dump })
end)
