local lastCall = 0

RegisterCommand('911', function(_, args)
    local msg = table.concat(args or {}, ' ')
    if msg == '' then
        local input = lib.inputDialog('Appel 911', {
            { type = 'input', label = 'Description', required = true },
        })
        if not input then return end
        msg = input[1]
    end
    if GetGameTimer() - lastCall < Config.Cooldown * 1000 then
        exports.vibe_api:Notify('911', 'Patiente avant un nouvel appel.', 'error')
        return
    end
    lastCall = GetGameTimer()
    local coords = GetEntityCoords(cache.ped)
    TriggerServerEvent('vibe_dispatch:server:alert', '911', msg, { x = coords.x, y = coords.y, z = coords.z })
end, false)

RegisterNetEvent('vibe_dispatch:client:alert', function(data)
    exports.vibe_api:Notify(('Dispatch — %s'):format(data.code), data.message, 'inform')
    local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
    SetBlipSprite(blip, 161)
    SetBlipColour(blip, data.code == '911' and 1 or 3)
    SetBlipScale(blip, 1.1)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(('Alert: %s'):format(data.code))
    EndTextCommandSetBlipName(blip)
    SetTimeout(Config.BlipTime * 1000, function()
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end)
end)

-- helper pour autres scripts
exports('SendAlert', function(code, message, coords)
    coords = coords or GetEntityCoords(cache.ped)
    TriggerServerEvent('vibe_dispatch:server:alert', code, message, { x = coords.x, y = coords.y, z = coords.z })
end)
