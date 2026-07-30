local shops = {}
local nearbyId = nil

local function rebuildShops(rows)
    ClientCore.ClearEntities('peds')
    shops = rows or {}
    for i = 1, #shops do
        local shop = shops[i]
        local data = shop.data or {}
        if data.ped and data.ped.enabled and shop.coords then
            ClientCore.SpawnPed(
                'shop_' .. shop.id,
                data.ped.model or Config.Defaults.ped.model,
                shop.coords,
                shop.coords.w or 0.0,
                data.ped.scenario or Config.Defaults.ped.scenario
            )
        end
        if data.blip and data.blip.enabled and shop.coords then
            ClientCore.CreateBlip('shop_blip_' .. shop.id, shop.coords, data.blip, shop.label)
        end
    end
end

RegisterNetEvent('core_creator:shops:sync', function(rows)
    rebuildShops(rows)
end)

CreateThread(function()
    while true do
        local sleep = Config.Tick.idleSleep
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        nearbyId = nil

        for i = 1, #shops do
            local shop = shops[i]
            if shop.coords then
                local dist = #(coords - vector3(shop.coords.x, shop.coords.y, shop.coords.z))
                local data = shop.data or {}
                local drawDist = data.drawDistance or Config.Distances.markerDraw
                if dist < drawDist then
                    sleep = 0
                    local useTarget = (Bridge.Target ~= 'marker' and Bridge.Target ~= 'none') and (data.interaction ~= 'marker')
                    if not useTarget then
                        ClientCore.DrawMarkerAt(shop.coords, data.marker)
                    end
                    local interact = data.interactDistance or Config.Distances.interaction
                    if dist < interact then
                        nearbyId = shop.id
                        ClientCore.HelpNotify('[E] ' .. (shop.label or 'Boutique'))
                        if IsControlJustReleased(0, 38) then
                            SendNUIMessage({
                                action = 'openShop',
                                data = shop,
                            })
                            -- For gameplay shops we use a simple prompt buy via command list in chat for now
                            -- Full shop UI can be extended; trigger first item buy example disabled.
                            Bridge.Notify(('Boutique: %s (%s articles)'):format(shop.label, #(data.items or {})), 'inform')
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- Target registration if ox_target / qb-target available
CreateThread(function()
    Wait(1500)
    if Bridge.Target == 'ox_target' then
        for i = 1, #shops do
            local shop = shops[i]
            if shop.coords then
                exports.ox_target:addSphereZone({
                    name = 'cc_shop_' .. shop.id,
                    coords = vec3(shop.coords.x, shop.coords.y, shop.coords.z),
                    radius = (shop.data and shop.data.interactDistance) or 2.0,
                    options = {{
                        name = 'cc_shop_open_' .. shop.id,
                        label = shop.label or 'Boutique',
                        onSelect = function()
                            Bridge.Notify(('Boutique: %s'):format(shop.label), 'inform')
                        end,
                    }},
                })
            end
        end
    end
end)

exports('GetNearbyShop', function()
    return nearbyId
end)
