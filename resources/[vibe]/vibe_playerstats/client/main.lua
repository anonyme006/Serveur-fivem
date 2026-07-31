local stats = { hunger = 100, thirst = 100 }
local shown = false

RegisterNetEvent('vibe_playerstats:client:sync', function(data)
    stats = data or stats
    lib.showTextUI(('Faim %d%%  |  Soif %d%%'):format(math.floor(stats.hunger or 0), math.floor(stats.thirst or 0)), {
        position = 'top-center',
    })
    shown = true
end)

RegisterNetEvent('vibe_playerstats:client:add', function(key, amount)
    TriggerServerEvent('vibe_playerstats:server:add', key, amount)
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and shown then
        lib.hideTextUI()
    end
end)
