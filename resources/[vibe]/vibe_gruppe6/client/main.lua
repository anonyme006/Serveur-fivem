local onRun = false
local dropBlip

local function setDrop(coords)
    if dropBlip then RemoveBlip(dropBlip) end
    dropBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipRoute(dropBlip, true)
    SetBlipColour(dropBlip, 5)
end

CreateThread(function()
    exports.ox_target:addSphereZone({
        coords = Config.Start,
        radius = 1.5,
        options = {{
            name = 'vibe_g6_start',
            icon = 'fa-solid fa-truck',
            label = 'Prendre une tournée Gruppe6',
            onSelect = function()
                TriggerServerEvent('vibe_gruppe6:server:start')
            end,
        }},
    })
end)

RegisterNetEvent('vibe_gruppe6:client:begin', function(drop)
    onRun = true
    setDrop(drop)
    local s = Config.Spawn
    local hash = joaat(Config.Vehicle)
    lib.requestModel(hash)
    local veh = CreateVehicle(hash, s.x, s.y, s.z, s.w, true, false)
    SetPedIntoVehicle(cache.ped, veh, -1)
    SetModelAsNoLongerNeeded(hash)
    exports.ox_target:addSphereZone({
        coords = drop,
        radius = 3.0,
        options = {{
            name = 'vibe_g6_drop',
            icon = 'fa-solid fa-box',
            label = 'Déposer les fonds',
            onSelect = function()
                if lib.progressCircle({
                    duration = 8000,
                    label = 'Livraison...',
                    position = 'bottom',
                    canCancel = true,
                    disable = { move = true, car = true },
                }) then
                    TriggerServerEvent('vibe_gruppe6:server:complete')
                    if dropBlip then RemoveBlip(dropBlip) dropBlip = nil end
                    onRun = false
                end
            end,
        }},
    })
end)
