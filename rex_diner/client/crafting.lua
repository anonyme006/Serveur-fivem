local deliveryBlip, deliveryVehicle

function Rex.OpenCraftMenu()
    if not Rex.Can('kitchen') then
        Rex.Notify('Cuisine', 'Permission refusée.', 'error')
        return
    end

    local options = {}
    for _, recipe in ipairs(Rex.GetRecipeList()) do
        local parts = {}
        for _, ing in ipairs(recipe.ingredients) do
            parts[#parts + 1] = ('%sx %s'):format(ing.amount, ing.label)
        end
        options[#options + 1] = {
            title = recipe.label,
            description = table.concat(parts, ' · ') .. ('\n⏱ %ss'):format(math.floor((recipe.time or 0) / 1000)),
            icon = 'utensils',
            onSelect = function()
                local result = lib.callback.await('rex_diner:startCraft', false, recipe.id)
                if not result or not result.ok then
                    Rex.Notify('Cuisine', result and result.error or 'Impossible.', 'error')
                    return
                end
                Rex.RunCraft(result.craft)
            end,
        }
    end

    lib.registerContext({ id = 'rex_diner_craft', title = '🍳 Cuisine', options = options })
    lib.showContext('rex_diner_craft')
end

function Rex.RunCraft(craft)
    if not craft or not craft.recipeId then return end
    if Rex.IsTabletOpen then
        Rex.CloseTablet()
        Wait(200)
    end

    local ok = lib.progressBar({
        duration = craft.time or 8000,
        label = ('Préparation du %s...'):format(craft.label or 'plat'),
        useWhileDead = false,
        canCancel = Config.Craft.cancelable ~= false,
        disable = { move = true, car = true, combat = true },
        anim = { dict = Config.Craft.animDict, clip = Config.Craft.animClip },
    })

    if not ok then
        TriggerServerEvent('rex_diner:server:cancelCraft')
        Rex.Notify('Cuisine', 'Préparation annulée.', 'error')
        return
    end

    local result = lib.callback.await('rex_diner:finishCraft', false, {
        recipeId = craft.recipeId,
        useStock = craft.useStock == true,
    })
    if not result or not result.ok then
        Rex.Notify('Cuisine', result and result.message or 'Échec.', 'error')
    end
end

function Rex.StartDelivery(data)
    Rex.CurrentDelivery = data
    if deliveryBlip and DoesBlipExist(deliveryBlip) then RemoveBlip(deliveryBlip) end

    local pickup = data.pickup
    if pickup then
        deliveryBlip = AddBlipForCoord(pickup.x, pickup.y, pickup.z)
        SetBlipSprite(deliveryBlip, Config.Delivery.blip.sprite or 478)
        SetBlipColour(deliveryBlip, Config.Delivery.blip.color or 2)
        SetBlipScale(deliveryBlip, Config.Delivery.blip.scale or 0.85)
        SetBlipRoute(deliveryBlip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(Config.Delivery.blip.label or 'Livraison')
        EndTextCommandSetBlipName(deliveryBlip)
        SetNewWaypoint(pickup.x, pickup.y)
    end

    if data.vehicle and pickup then
        local model = joaat(data.vehicle)
        lib.requestModel(model)
        deliveryVehicle = CreateVehicle(model, pickup.x, pickup.y, pickup.z, pickup.w or 0.0, true, false)
        SetVehicleOnGroundProperly(deliveryVehicle)
        SetPedIntoVehicle(cache.ped, deliveryVehicle, -1)
        SetModelAsNoLongerNeeded(model)
    end

    Rex.Notify('Livraisons', 'Récupérez la commande puis déposez au restaurant.', 'inform')

    CreateThread(function()
        local switched = false
        while Rex.CurrentDelivery and Rex.CurrentDelivery.deliveryId == data.deliveryId do
            Wait(1000)
            if not switched and pickup and data.dropoff then
                if #(GetEntityCoords(cache.ped) - vec3(pickup.x, pickup.y, pickup.z)) < 20.0 then
                    SetNewWaypoint(data.dropoff.x, data.dropoff.y)
                    if deliveryBlip and DoesBlipExist(deliveryBlip) then RemoveBlip(deliveryBlip) end
                    deliveryBlip = AddBlipForCoord(data.dropoff.x, data.dropoff.y, data.dropoff.z)
                    SetBlipSprite(deliveryBlip, 478)
                    SetBlipColour(deliveryBlip, 2)
                    SetBlipRoute(deliveryBlip, true)
                    BeginTextCommandSetBlipName('STRING')
                    AddTextComponentSubstringPlayerName('Dépôt restaurant')
                    EndTextCommandSetBlipName(deliveryBlip)
                    Rex.Notify('Livraisons', 'Retournez au restaurant.', 'success')
                    switched = true
                end
            end
        end
    end)
end

function Rex.CompleteDelivery()
    if not Rex.CurrentDelivery then
        Rex.Notify('Livraisons', 'Aucune livraison.', 'error')
        return
    end
    local result = lib.callback.await('rex_diner:completeDelivery', false, Rex.CurrentDelivery.deliveryId)
    if not result or not result.ok then
        Rex.Notify('Livraisons', result and result.message or 'Échec.', 'error')
        return
    end
    if deliveryBlip and DoesBlipExist(deliveryBlip) then RemoveBlip(deliveryBlip) deliveryBlip = nil end
    if deliveryVehicle and DoesEntityExist(deliveryVehicle) then DeleteEntity(deliveryVehicle) deliveryVehicle = nil end
    Rex.CurrentDelivery = nil
end
