local farms = {}
local busy = false

RegisterNetEvent('core_creator:farms:sync', function(rows)
    farms = rows or {}
end)

CreateThread(function()
    while true do
        local sleep = Config.Tick.idleSleep
        local coords = GetEntityCoords(PlayerPedId())

        for i = 1, #farms do
            local farm = farms[i]
            local data = farm.data or {}
            local stages = data.stages or {}
            for s = 1, #stages do
                local stage = stages[s]
                local c = stage.coords or farm.coords
                if c then
                    local dist = #(coords - vector3(c.x, c.y, c.z))
                    if dist < (stage.drawDistance or Config.Distances.markerDraw) then
                        sleep = 0
                        if stage.interaction ~= 'target' then
                            ClientCore.DrawMarkerAt(c, stage.marker or data.marker)
                        end
                        if dist < (stage.interactDistance or Config.Distances.interaction) and not busy then
                            ClientCore.HelpNotify('[E] ' .. (stage.label or farm.label or 'Farming'))
                            if IsControlJustReleased(0, 38) then
                                busy = true
                                local duration = tonumber(stage.duration) or 3000
                                if Bridge.Progress == 'ox_lib' and lib and lib.progressCircle then
                                    local ok = lib.progressCircle({
                                        duration = duration,
                                        label = stage.label or 'Action',
                                        position = 'bottom',
                                        useWhileDead = false,
                                        canCancel = true,
                                        disable = { move = true, combat = true },
                                        anim = stage.animation and { dict = stage.animation.dict, clip = stage.animation.clip } or nil,
                                    })
                                    if ok then
                                        TriggerServerEvent('core_creator:farms:action', farm.id, s)
                                    end
                                else
                                    Wait(duration)
                                    TriggerServerEvent('core_creator:farms:action', farm.id, s)
                                end
                                busy = false
                            end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)
