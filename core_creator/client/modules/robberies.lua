local robberies = {}
local active = {}

RegisterNetEvent('core_creator:robberies:sync', function(rows, activeStates)
    robberies = rows or {}
    active = activeStates or {}
end)

RegisterNetEvent('core_creator:robberies:started', function(id, state)
    active[id] = state
    Bridge.Notify('Braquage démarré', 'inform')
end)

RegisterNetEvent('core_creator:robberies:stage', function(id, stage)
    if active[id] then active[id].stage = stage end
end)

RegisterNetEvent('core_creator:robberies:finished', function(id)
    active[id] = nil
    Bridge.Notify('Braquage terminé', 'success')
end)

RegisterNetEvent('core_creator:robberies:cancelled', function(id)
    active[id] = nil
    Bridge.Notify('Braquage annulé', 'error')
end)

RegisterNetEvent('core_creator:robberies:policeAlert', function(payload)
    Bridge.Notify(payload.message or 'Alerte braquage', 'error', 8000)
    if payload.coords then
        local blip = AddBlipForCoord(payload.coords.x, payload.coords.y, payload.coords.z)
        SetBlipSprite(blip, 161)
        SetBlipColour(blip, 1)
        SetBlipScale(blip, 1.0)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName('Braquage')
        EndTextCommandSetBlipName(blip)
        SetTimeout(120000, function()
            if DoesBlipExist(blip) then RemoveBlip(blip) end
        end)
    end
end)

CreateThread(function()
    while true do
        local sleep = Config.Tick.idleSleep
        local coords = GetEntityCoords(PlayerPedId())
        for i = 1, #robberies do
            local rob = robberies[i]
            if rob.coords then
                local dist = #(coords - vector3(rob.coords.x, rob.coords.y, rob.coords.z))
                if dist < Config.Distances.markerDraw then
                    sleep = 0
                    ClientCore.DrawMarkerAt(rob.coords, rob.data and rob.data.marker)
                    if dist < Config.Distances.interaction and not active[rob.id] then
                        ClientCore.HelpNotify('[E] Démarrer braquage — ' .. (rob.label or ''))
                        if IsControlJustReleased(0, 38) then
                            TriggerServerEvent('core_creator:robberies:start', rob.id)
                        end
                    end
                end
            end

            if active[rob.id] then
                local stages = (rob.data and rob.data.stages) or {}
                local stageIndex = active[rob.id].stage or 1
                local stage = stages[stageIndex]
                if stage and stage.coords then
                    local dist = #(coords - vector3(stage.coords.x, stage.coords.y, stage.coords.z))
                    if dist < Config.Distances.markerDraw then
                        sleep = 0
                        ClientCore.DrawMarkerAt(stage.coords, stage.marker)
                        if dist < Config.Distances.interaction then
                            ClientCore.HelpNotify('[E] Étape braquage')
                            if IsControlJustReleased(0, 38) then
                                local duration = tonumber(stage.duration) or 5000
                                Wait(duration)
                                TriggerServerEvent('core_creator:robberies:progress', rob.id, stageIndex)
                            end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)
