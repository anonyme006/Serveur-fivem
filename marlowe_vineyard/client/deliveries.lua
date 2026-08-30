MarloweDeliveries = MarloweDeliveries or {}

local activeDeliveryBlip = nil
local activeDeliveryOrderId = nil

local function notify(message, nType)
    lib.notify({
        title = Config.Label,
        description = message,
        type = nType or 'inform',
    })
end

local function clearDeliveryBlip()
    if activeDeliveryBlip then
        RemoveBlip(activeDeliveryBlip)
        activeDeliveryBlip = nil
    end
    activeDeliveryOrderId = nil
end

local function setDeliveryBlip(order)
    clearDeliveryBlip()
    activeDeliveryOrderId = order.id

    activeDeliveryBlip = AddBlipForCoord(order.destination_x, order.destination_y, order.destination_z)
    SetBlipSprite(activeDeliveryBlip, 478)
    SetBlipColour(activeDeliveryBlip, 5)
    SetBlipRoute(activeDeliveryBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(('Livraison #%s'):format(order.id))
    EndTextCommandSetBlipName(activeDeliveryBlip)
end

local function formatOrderDescription(order)
    return ('Client: %s | Produit: %s x%s | Prix: $%s | Destination: %s | Statut: %s'):format(
        order.client_name,
        order.product_label,
        order.quantity,
        order.price,
        order.destination_label,
        Marlowe.GetOrderStatusLabel(order.status)
    )
end

function MarloweDeliveries.PopulateOrdersMenu(menu, filter, withActions)
    menu:ClearItems()

    local orders = lib.callback.await('marlowe:server:getOrders', false, filter)
    if not orders or #orders == 0 then
        menu:AddButton({
            icon = 'ℹ️',
            label = 'Aucune commande',
            description = 'Aucune commande disponible',
            disabled = true,
        })
        return
    end

    for i = 1, #orders do
        local order = orders[i]
        local item = menu:AddButton({
            icon = '📋',
            label = ('Commande #%s — %s'):format(order.id, order.client_name),
            description = formatOrderDescription(order),
        })

        if withActions then
            item:On('select', function()
                MarloweDeliveries.OpenOrderActionsMenu(order)
            end)
        elseif order.status == 'assigned' or order.status == 'delivering' then
            item:On('select', function()
                setDeliveryBlip(order)
                notify(('Itinéraire vers %s défini.'):format(order.destination_label), 'inform')
            end)
        end
    end
end

function MarloweDeliveries.OpenOrderActionsMenu(order)
    local actionMenu = MenuV:CreateMenu(
        ('Commande #%s'):format(order.id),
        formatOrderDescription(order),
        'bottomright',
        Config.Colors.Red,
        Config.Colors.Green,
        Config.Colors.Blue,
        Config.Menu.Size,
        false,
        'menuv',
        'marlowe_vineyard',
        Config.Menu.Theme
    )

    local actions = {
        { action = 'accept', label = 'Accepter', icon = '✅', statuses = { pending = true } },
        { action = 'prepare', label = 'Préparer', icon = '🍷', statuses = { accepted = true } },
        { action = 'ready', label = 'Marquer prête', icon = '📦', statuses = { preparing = true } },
        { action = 'assign', label = 'Assigner', icon = '👤', statuses = { preparing = true, ready = true } },
        { action = 'deliver', label = 'Livrer', icon = '🚚', statuses = { assigned = true } },
        { action = 'complete', label = 'Terminer', icon = '🏁', statuses = { delivering = true, assigned = true, ready = true } },
    }

    for i = 1, #actions do
        local entry = actions[i]
        if entry.statuses[order.status] then
            actionMenu:AddButton({
                icon = entry.icon,
                label = entry.label,
                description = ('Action: %s'):format(entry.label),
            }):On('select', function()
                local ok, result = lib.callback.await('marlowe:server:updateOrder', false, order.id, entry.action)
                if ok then
                    if entry.action == 'deliver' or entry.action == 'assign' then
                        setDeliveryBlip(order)
                    end
                    if entry.action == 'complete' and result then
                        notify(('Livraison terminée — $%s'):format(result), 'success')
                        clearDeliveryBlip()
                    else
                        notify('Commande mise à jour.', 'success')
                    end
                    MenuV:CloseMenu(actionMenu)
                else
                    notify(result or Config.Notifications.Failed, 'error')
                end
            end)
        end
    end

    MenuV:OpenMenu(actionMenu)
end

function MarloweDeliveries.CreateOrder(productIndex, quantity, destinationIndex)
    local ok, result = lib.callback.await('marlowe:server:createDelivery', false, productIndex, quantity, destinationIndex)
    if ok then
        notify(('Commande #%s créée.'):format(result), 'success')
    else
        notify(result or Config.Notifications.Failed, 'error')
    end
end

CreateThread(function()
    while true do
        if activeDeliveryOrderId and activeDeliveryBlip then
            Wait(500)
            local coords = GetEntityCoords(cache.ped)
            local order = lib.callback.await('marlowe:server:getOrderDetails', false, activeDeliveryOrderId)
            if order then
                local destination = vec3(order.destination_x, order.destination_y, order.destination_z)
                if #(coords - destination) <= 8.0 then
                    lib.showTextUI('[E] Livrer la commande')
                    if IsControlJustReleased(0, 38) then
                        lib.hideTextUI()
                        local ok, result = lib.callback.await('marlowe:server:completeDeliveryAtPoint', false, activeDeliveryOrderId)
                        if ok then
                            notify(('Livraison terminée — $%s'):format(result or 0), 'success')
                            clearDeliveryBlip()
                        else
                            notify(result or Config.Notifications.Failed, 'error')
                        end
                    end
                else
                    lib.hideTextUI()
                end
            else
                clearDeliveryBlip()
                lib.hideTextUI()
            end
        else
            Wait(2000)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    clearDeliveryBlip()
    lib.hideTextUI()
end)
