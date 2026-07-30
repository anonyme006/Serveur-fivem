local gangs = {}

RegisterNetEvent('core_creator:gangs:sync', function(rows)
    gangs = rows or {}
    for i = 1, #gangs do
        local gang = gangs[i]
        local data = gang.data or {}
        if data.blip and data.blip.enabled and gang.coords then
            ClientCore.CreateBlip('gang_' .. gang.id, gang.coords, data.blip, gang.label)
        end
    end
end)

CreateThread(function()
    while true do
        local sleep = Config.Tick.idleSleep
        local coords = GetEntityCoords(PlayerPedId())
        for i = 1, #gangs do
            local gang = gangs[i]
            local data = gang.data or {}
            local points = data.points or {}
            for p = 1, #points do
                local point = points[p]
                if point.coords then
                    local dist = #(coords - vector3(point.coords.x, point.coords.y, point.coords.z))
                    if dist < Config.Distances.markerDraw then
                        sleep = 0
                        ClientCore.DrawMarkerAt(point.coords, point.marker)
                        if dist < Config.Distances.interaction then
                            ClientCore.HelpNotify('[E] ' .. (point.label or gang.label))
                            if IsControlJustReleased(0, 38) then
                                Bridge.Notify((point.type or 'point') .. ' — ' .. gang.label, 'inform')
                            end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)
