RegisterNetEvent('vibe_discord:client:announce', function(title, message)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(('~b~%s~s~\n%s'):format(title or 'Annonce', message or ''))
    EndTextCommandThefeedPostTicker(false, true)

    if GetResourceState('ox_lib') == 'started' then
        exports.ox_lib:notify({
            title = title or 'Annonce',
            description = message,
            type = 'inform',
            duration = 10000,
            position = 'top',
        })
    end
end)

RegisterNetEvent('vibe_discord:client:warn', function(reason, staff)
    if GetResourceState('ox_lib') == 'started' then
        exports.ox_lib:notify({
            title = 'Avertissement Staff',
            description = ('Par %s\n%s'):format(staff or 'Staff', reason or ''),
            type = 'error',
            duration = 12000,
        })
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(('~r~WARN~s~ (%s): %s'):format(staff or 'Staff', reason or ''))
        EndTextCommandThefeedPostTicker(false, true)
    end
end)

RegisterNetEvent('vibe_discord:client:heal', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetPedArmour(ped, 100)
    ClearPedBloodDamage(ped)
    if GetResourceState('ox_lib') == 'started' then
        exports.ox_lib:notify({ title = 'Staff', description = 'Tu as été soigné.', type = 'success' })
    end
end)

RegisterNetEvent('vibe_discord:client:revive', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false)
    SetEntityInvincible(ped, false)
    ClearPedBloodDamage(ped)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    if GetResourceState('ox_lib') == 'started' then
        exports.ox_lib:notify({ title = 'Staff', description = 'Tu as été réanimé.', type = 'success' })
    end
end)

-- /report [id] message
RegisterCommand('report', function(_, args)
    local target = tonumber(args[1])
    if not target then
        if GetResourceState('ox_lib') == 'started' then
            exports.ox_lib:notify({ title = 'Report', description = 'Usage : /report [id] message', type = 'error' })
        end
        return
    end
    local msg = table.concat(args, ' ', 2)
    if msg == '' then
        if GetResourceState('ox_lib') == 'started' then
            exports.ox_lib:notify({ title = 'Report', description = 'Message requis', type = 'error' })
        end
        return
    end
    TriggerServerEvent('vibe_discord:server:report', target, msg)
    if GetResourceState('ox_lib') == 'started' then
        exports.ox_lib:notify({ title = 'Report', description = 'Envoyé au staff Discord.', type = 'success' })
    end
end, false)
