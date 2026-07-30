local jobs = {}

RegisterNetEvent('core_creator:jobs:sync', function(rows)
    jobs = rows or {}
    -- duty / wardrobe / boss markers
end)

CreateThread(function()
    while true do
        local sleep = Config.Tick.idleSleep
        local coords = GetEntityCoords(PlayerPedId())
        for i = 1, #jobs do
            local job = jobs[i]
            local data = job.data or {}
            local points = data.points or {}
            for p = 1, #points do
                local point = points[p]
                if point.coords then
                    local dist = #(coords - vector3(point.coords.x, point.coords.y, point.coords.z))
                    if dist < Config.Distances.markerDraw then
                        sleep = 0
                        ClientCore.DrawMarkerAt(point.coords, point.marker)
                        if dist < Config.Distances.interaction then
                            ClientCore.HelpNotify('[E] ' .. (point.label or job.label))
                            if IsControlJustReleased(0, 38) then
                                Bridge.Notify((point.type or 'point') .. ' — ' .. job.label, 'inform')
                            end
                        end
                    end
                end
            end
            if data.blip and data.blip.enabled and job.coords then
                -- blips created once via sync rebuild could be added; keep lightweight
            end
        end
        Wait(sleep)
    end
end)

exports('GetCreatedJobsClient', function()
    return jobs
end)
