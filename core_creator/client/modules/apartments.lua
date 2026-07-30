local apartments = {}

RegisterNetEvent('core_creator:apartments:sync', function(rows)
    apartments = rows or {}
end)

RegisterNetEvent('core_creator:apartments:teleport', function(coords, entering)
    if not coords then return end
    local ped = PlayerPedId()
    DoScreenFadeOut(400)
    Wait(450)
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    if coords.w then SetEntityHeading(ped, coords.w + 0.0) end
    Wait(200)
    DoScreenFadeIn(400)
    Bridge.Notify(entering and 'Entrée appartement' or 'Sortie appartement', 'inform')
end)

CreateThread(function()
    while true do
        local sleep = Config.Tick.idleSleep
        local coords = GetEntityCoords(PlayerPedId())
        for i = 1, #apartments do
            local apt = apartments[i]
            if apt.coords then
                local dist = #(coords - vector3(apt.coords.x, apt.coords.y, apt.coords.z))
                if dist < Config.Distances.markerDraw then
                    sleep = 0
                    ClientCore.DrawMarkerAt(apt.coords, apt.data and apt.data.marker)
                    if dist < Config.Distances.interaction then
                        ClientCore.HelpNotify('[E] Entrer | [G] Acheter — ' .. (apt.label or 'Appartement'))
                        if IsControlJustReleased(0, 38) then
                            TriggerServerEvent('core_creator:apartments:enter', apt.id)
                        end
                        if IsControlJustReleased(0, 47) then -- G
                            TriggerServerEvent('core_creator:apartments:buy', apt.id)
                        end
                    end
                end
            end
            local interior = apt.data and apt.data.interior
            if interior then
                local dist2 = #(coords - vector3(interior.x, interior.y, interior.z))
                if dist2 < Config.Distances.interaction then
                    sleep = 0
                    ClientCore.HelpNotify('[E] Sortir')
                    if IsControlJustReleased(0, 38) then
                        TriggerServerEvent('core_creator:apartments:exit', apt.id)
                    end
                end
            end
        end
        Wait(sleep)
    end
end)
