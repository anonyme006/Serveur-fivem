RexDiner.CurrentDelivery = nil
local deliveryBlip = nil
local deliveryVehicle = nil

function RexDiner.OpenCraftMenu()
    if not RexDiner.HasLocalPermission('kitchen') then
        RexDiner.Notify('Cuisine', 'Permission refusée.', 'error')
        return
    end

    local recipes = GetRecipeList()
    local options = {}

    for i = 1, #recipes do
        local recipe = recipes[i]
        local ingredientText = {}
        for j = 1, #recipe.ingredients do
            local ing = recipe.ingredients[j]
            ingredientText[#ingredientText + 1] = ('%sx %s'):format(ing.amount, ing.label)
        end

        options[#options + 1] = {
            title = recipe.label,
            description = table.concat(ingredientText, ' · ') .. ('\n⏱ %ss'):format(math.floor((recipe.time or 0) / 1000)),
            icon = 'utensils',
            onSelect = function()
                local result = lib.callback.await('rex_diner:startCraft', false, recipe.id)
                if not result or not result.ok then
                    RexDiner.Notify('Cuisine', result and result.error or 'Impossible de préparer.', 'error')
                    return
                end
                RexDiner.RunCraft(result.craft)
            end,
        }
    end

    lib.registerContext({
        id = 'rex_diner_craft',
        title = '🍳 Cuisine — Préparer une recette',
        options = options,
    })
    lib.showContext('rex_diner_craft')
end

---@param craft table
function RexDiner.RunCraft(craft)
    if not craft or not craft.recipeId then return end

    if RexDiner.IsTabletOpen then
        RexDiner.CloseTablet()
        Wait(200)
    end

    local success = lib.progressBar({
        duration = craft.time or 8000,
        label = ('Préparation du %s...'):format(craft.label or 'plat'),
        useWhileDead = false,
        canCancel = Config.Craft.cancelable ~= false,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = Config.Craft.animDict,
            clip = Config.Craft.animClip,
        },
    })

    if not success then
        TriggerServerEvent('rex_diner:server:cancelCraft')
        RexDiner.Notify('Cuisine', 'Préparation annulée.', 'error')
        return
    end

    local result = lib.callback.await('rex_diner:finishCraft', false, {
        recipeId = craft.recipeId,
        useStock = craft.useStock == true,
    })

    if not result or not result.ok then
        RexDiner.Notify('Cuisine', result and result.message or 'Échec de la préparation.', 'error')
        return
    end
end

function RexDiner.StartDelivery(data)
    RexDiner.CurrentDelivery = data
    if deliveryBlip and DoesBlipExist(deliveryBlip) then
        RemoveBlip(deliveryBlip)
    end

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

    RexDiner.Notify('Livraisons', 'Récupérez la commande puis déposez-la au restaurant.', 'inform')

    -- After pickup proximity, switch waypoint to dropoff
    CreateThread(function()
        local switched = false
        while RexDiner.CurrentDelivery and RexDiner.CurrentDelivery.deliveryId == data.deliveryId do
            Wait(1000)
            if not switched and pickup then
                local coords = GetEntityCoords(cache.ped)
                if #(coords - vec3(pickup.x, pickup.y, pickup.z)) < 20.0 and data.dropoff then
                    SetNewWaypoint(data.dropoff.x, data.dropoff.y)
                    if deliveryBlip and DoesBlipExist(deliveryBlip) then
                        RemoveBlip(deliveryBlip)
                    end
                    deliveryBlip = AddBlipForCoord(data.dropoff.x, data.dropoff.y, data.dropoff.z)
                    SetBlipSprite(deliveryBlip, 478)
                    SetBlipColour(deliveryBlip, 2)
                    SetBlipRoute(deliveryBlip, true)
                    BeginTextCommandSetBlipName('STRING')
                    AddTextComponentSubstringPlayerName('Dépôt restaurant')
                    EndTextCommandSetBlipName(deliveryBlip)
                    RexDiner.Notify('Livraisons', 'Retournez au restaurant pour déposer.', 'success')
                    switched = true
                end
            end
        end
    end)
end

function RexDiner.CompleteDelivery()
    if not RexDiner.CurrentDelivery then
        RexDiner.Notify('Livraisons', 'Aucune livraison en cours.', 'error')
        return
    end

    local deliveryId = RexDiner.CurrentDelivery.deliveryId
    local result = lib.callback.await('rex_diner:completeDelivery', false, deliveryId)
    if not result or not result.ok then
        RexDiner.Notify('Livraisons', result and result.message or 'Échec dépôt.', 'error')
        return
    end

    if deliveryBlip and DoesBlipExist(deliveryBlip) then
        RemoveBlip(deliveryBlip)
        deliveryBlip = nil
    end
    if deliveryVehicle and DoesEntityExist(deliveryVehicle) then
        DeleteEntity(deliveryVehicle)
        deliveryVehicle = nil
    end
    RexDiner.CurrentDelivery = nil
end
