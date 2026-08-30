local deliveryBlip, deliveryVehicle

function Rest.OpenCraftMenu()
    if not Rest.Can('kitchen') then
        Rest.Notify('Cuisine', 'Permission refusée.', 'error')
        return
    end

    local options = {}
    for _, recipe in ipairs(Rest.GetRecipeList()) do
        local parts = {}
        for _, ing in ipairs(recipe.ingredients) do
            parts[#parts + 1] = ('%sx %s'):format(ing.amount, ing.label)
        end
        options[#options + 1] = {
            title = recipe.label,
            description = table.concat(parts, ' · ') .. ('\n⏱ %ss'):format(math.floor((recipe.time or 0) / 1000)),
            icon = 'utensils',
            onSelect = function()
                local result = lib.callback.await('qbox_restaurants:startCraft', false, recipe.id)
                if not result or not result.ok then
                    Rest.Notify('Cuisine', result and result.error or 'Impossible.', 'error')
                    return
                end
                Rest.RunCraft(result.craft)
            end,
        }
    end

    lib.registerContext({ id = 'qbox_restaurants_craft', title = '🍳 Cuisine', options = options })
    lib.showContext('qbox_restaurants_craft')
end

function Rest.RunCraft(craft)
    if not craft or not craft.recipeId then return end
    if Rest.IsTabletOpen then
        Rest.CloseTablet()
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
        TriggerServerEvent('qbox_restaurants:server:cancelCraft')
        Rest.Notify('Cuisine', 'Préparation annulée.', 'error')
        return
    end

    local result = lib.callback.await('qbox_restaurants:finishCraft', false, {
        recipeId = craft.recipeId,
        useStock = craft.useStock == true,
    })
    if not result or not result.ok then
        Rest.Notify('Cuisine', result and result.message or 'Échec.', 'error')
    end
end

function Rest.StartDelivery(data)
    Rest.CurrentDelivery = data
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

    Rest.Notify('Livraisons', 'Récupérez la commande puis déposez au restaurant.', 'inform')

    CreateThread(function()
        local switched = false
        while Rest.CurrentDelivery and Rest.CurrentDelivery.deliveryId == data.deliveryId do
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
                    Rest.Notify('Livraisons', 'Retournez au restaurant.', 'success')
                    switched = true
                end
            end
        end
    end)
end

function Rest.CompleteDelivery()
    if not Rest.CurrentDelivery then
        Rest.Notify('Livraisons', 'Aucune livraison.', 'error')
        return
    end
    local result = lib.callback.await('qbox_restaurants:completeDelivery', false, Rest.CurrentDelivery.deliveryId)
    if not result or not result.ok then
        Rest.Notify('Livraisons', result and result.message or 'Échec.', 'error')
        return
    end
    if deliveryBlip and DoesBlipExist(deliveryBlip) then RemoveBlip(deliveryBlip) deliveryBlip = nil end
    if deliveryVehicle and DoesEntityExist(deliveryVehicle) then DeleteEntity(deliveryVehicle) deliveryVehicle = nil end
    Rest.CurrentDelivery = nil
end
