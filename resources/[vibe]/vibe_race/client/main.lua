local racing = false

RegisterCommand('course', function()
    if racing then return end
    if #(GetEntityCoords(cache.ped) - Config.Start) > 15.0 then
        exports.vibe_api:Notify('Course', 'Va au point de depart.', 'error')
        return
    end
    racing = true
    exports.vibe_api:Notify('Course', 'GO ! Passe les checkpoints.', 'success')
    CreateThread(function()
        for i, cp in ipairs(Config.Checkpoints) do
            local blip = AddBlipForCoord(cp.x, cp.y, cp.z)
            SetBlipRoute(blip, true)
            while #(GetEntityCoords(cache.ped) - cp) > 8.0 and racing do
                DrawMarker(1, cp.x, cp.y, cp.z - 1.0, 0,0,0,0,0,0, 6.0,6.0,1.0, 111,191,138,120, false,false,2,false,nil,nil,false)
                Wait(0)
            end
            RemoveBlip(blip)
            exports.vibe_api:Notify('Course', ('Checkpoint %s/%s'):format(i, #Config.Checkpoints), 'inform')
        end
        if racing then
            TriggerServerEvent('vibe_race:server:finish')
        end
        racing = false
    end)
end, false)

CreateThread(function()
    local blip = AddBlipForCoord(Config.Start.x, Config.Start.y, Config.Start.z)
    SetBlipSprite(blip, 315)
    SetBlipScale(blip, 0.8)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Course')
    EndTextCommandSetBlipName(blip)
end)
