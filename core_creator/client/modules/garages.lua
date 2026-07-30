local garages = {}
local lastList = {}

RegisterNetEvent('core_creator:garages:sync', function(rows)
    garages = rows or {}
end)

RegisterNetEvent('core_creator:garages:vehicles', function(garageId, vehicles)
    lastList = vehicles or {}
    SendNUIMessage({ action = 'garageVehicles', data = { garageId = garageId, vehicles = lastList } })
    if #lastList == 0 then
        Bridge.Notify('Aucun véhicule', 'inform')
        return
    end
    Bridge.Notify(('Véhicules: %s — utilisez /corecreator pour gérer, ou E encore pour sortir le 1er'):format(#lastList), 'inform')
end)

RegisterNetEvent('core_creator:garages:doSpawn', function(payload)
    local model = payload.props and (payload.props.modelName or payload.props.model)
    local hash = type(model) == 'number' and model or joaat(model or 'adder')
    RequestModel(hash)
    local t = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < t do Wait(10) end
    if not HasModelLoaded(hash) then return end

    local c = payload.coords
    local veh = CreateVehicle(hash, c.x, c.y, c.z, payload.heading or 0.0, true, false)
    SetVehicleNumberPlateText(veh, payload.plate or '')
    SetVehicleOnGroundProperly(veh)
    SetPedIntoVehicle(PlayerPedId(), veh, -1)
    SetModelAsNoLongerNeeded(hash)
    TriggerServerEvent('core_creator:garages:markOut', payload.plate, NetworkGetNetworkIdFromEntity(veh))

    if Bridge.Fuel ~= 'none' and payload.props and payload.props.fuel then
        pcall(function()
            if Bridge.Fuel == 'LegacyFuel' or Bridge.Fuel == 'cdn-fuel' then
                exports[Bridge.Fuel]:SetFuel(veh, payload.props.fuel)
            end
        end)
    end
end)

CreateThread(function()
    while true do
        local sleep = Config.Tick.idleSleep
        local coords = GetEntityCoords(PlayerPedId())
        for i = 1, #garages do
            local g = garages[i]
            if g.coords then
                local dist = #(coords - vector3(g.coords.x, g.coords.y, g.coords.z))
                if dist < Config.Distances.markerDraw then
                    sleep = 0
                    ClientCore.DrawMarkerAt(g.coords, g.data and g.data.marker)
                    if dist < Config.Distances.interaction then
                        ClientCore.HelpNotify('[E] ' .. (g.label or 'Garage'))
                        if IsControlJustReleased(0, 38) then
                            local ped = PlayerPedId()
                            if IsPedInAnyVehicle(ped, false) then
                                local veh = GetVehiclePedIsIn(ped, false)
                                local plate = GetVehicleNumberPlateText(veh)
                                local props = { model = GetEntityModel(veh), modelName = nil, fuel = 100 }
                                TriggerServerEvent('core_creator:garages:store', g.id, plate, props)
                                TaskLeaveVehicle(ped, veh, 0)
                                Wait(1200)
                                if DoesEntityExist(veh) then DeleteVehicle(veh) end
                            else
                                TriggerServerEvent('core_creator:garages:listVehicles', g.id)
                                Wait(200)
                                if lastList[1] then
                                    TriggerServerEvent('core_creator:garages:spawn', g.id, lastList[1].plate, 1)
                                end
                            end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)
