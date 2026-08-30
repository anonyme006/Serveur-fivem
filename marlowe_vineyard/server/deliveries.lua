local function generateClientName()
    local names = {
        'Vinoteca Del Perro',
        'Le Bouchon',
        'Restaurant Eclipse',
        'Club Vinewood',
        'Hôtel Von Crastenburg',
        'Cave Downtown',
        'Bistro Vespucci',
    }
    return names[math.random(#names)]
end

local function createRandomOrder()
    local product = Config.Deliveries.Products[math.random(#Config.Deliveries.Products)]
    local destination = Config.Deliveries.DeliveryPoints[math.random(#Config.Deliveries.DeliveryPoints)]
    local quantity = math.random(1, 5)

    MarloweDB.CreateOrder({
        client_name = generateClientName(),
        product_item = product.item,
        product_label = product.label,
        quantity = quantity,
        price = product.price * quantity,
        destination_label = destination.label,
        destination_x = destination.coords.x,
        destination_y = destination.coords.y,
        destination_z = destination.coords.z,
        status = 'pending',
    })
end

CreateThread(function()
    while not MarloweDB.IsReady() do
        Wait(500)
    end

    local existing = MarloweDB.GetOrders()
    if #existing < 3 then
        for _ = 1, 5 do
            createRandomOrder()
        end
    end

    while true do
        Wait(15 * 60 * 1000)
        local pending = MarloweDB.GetOrders('pending')
        if #pending < 3 then
            createRandomOrder()
        end
    end
end)

lib.callback.register('marlowe:server:getOrders', function(source, filter)
    local player, err = Marlowe.ValidatePlayer(source, Config.Permissions.Orders, Config.RequireDuty.Deliveries)
    if not player then return nil, err end
    return MarloweDB.GetOrders(filter)
end)

lib.callback.register('marlowe:server:getOrderDetails', function(source, orderId)
    local player, err = Marlowe.ValidatePlayer(source, Config.Permissions.Deliveries, false)
    if not player then return nil, err end
    return MarloweDB.GetOrder(orderId)
end)

lib.callback.register('marlowe:server:createDelivery', function(source, productIndex, quantity, destinationIndex)
    local player, err = Marlowe.ValidatePlayer(source, Config.Permissions.Deliveries, Config.RequireDuty.Deliveries)
    if not player then return false, err end

    local product = Config.Deliveries.Products[productIndex]
    local destination = Config.Deliveries.DeliveryPoints[destinationIndex]
    if not product or not destination then return false, 'Sélection invalide.' end

    quantity = math.max(1, math.min(quantity or 1, 20))
    local totalPrice = product.price * quantity

    local orderId = MarloweDB.CreateOrder({
        client_name = generateClientName(),
        product_item = product.item,
        product_label = product.label,
        quantity = quantity,
        price = totalPrice,
        destination_label = destination.label,
        destination_x = destination.coords.x,
        destination_y = destination.coords.y,
        destination_z = destination.coords.z,
        status = 'pending',
    })

    return true, orderId
end)

local validTransitions = {
    accept = { from = { pending = true }, to = 'accepted' },
    prepare = { from = { accepted = true }, to = 'preparing' },
    assign = { from = { preparing = true, ready = true }, to = 'assigned' },
    deliver = { from = { assigned = true }, to = 'delivering' },
    complete = { from = { delivering = true, ready = true, assigned = true }, to = 'completed' },
    ready = { from = { preparing = true }, to = 'ready' },
}

local function completeOrder(source, orderId)
    local player, err = Marlowe.ValidatePlayer(source, Config.Permissions.Orders, Config.RequireDuty.Deliveries)
    if not player then return false, err end

    local order = MarloweDB.GetOrder(orderId)
    if not order then return false, 'Commande introuvable.' end

    if not Marlowe.HasItem(source, order.product_item, order.quantity) then
        return false, ('Il vous manque %dx %s.'):format(order.quantity, order.product_label)
    end

    if not exports.ox_inventory:RemoveItem(source, order.product_item, order.quantity) then
        return false, Config.Notifications.Failed
    end

    local citizenid = player.PlayerData.citizenid
    MarloweDB.UpdateOrderStatus(orderId, 'completed', order.assigned_citizenid or citizenid)
    MarloweFinances.AddRevenue(order.price, ('Livraison commande #%s'):format(orderId), citizenid)
    MarloweDB.IncrementStat(citizenid, 'deliveries_completed', 1)
    MarloweDB.IncrementStat(citizenid, 'revenue_generated', order.price)

    return true, order.price
end

lib.callback.register('marlowe:server:updateOrder', function(source, orderId, action)
    local player, err = Marlowe.ValidatePlayer(source, Config.Permissions.Orders, Config.RequireDuty.Deliveries)
    if not player then return false, err end

    local order = MarloweDB.GetOrder(orderId)
    if not order then return false, 'Commande introuvable.' end

    local transition = validTransitions[action]
    if not transition or not transition.from[order.status] then
        return false, 'Action impossible pour ce statut.'
    end

    local citizenid = player.PlayerData.citizenid

    if action == 'assign' or action == 'deliver' then
        MarloweDB.UpdateOrderStatus(orderId, transition.to, citizenid)
        return true
    end

    if action == 'complete' then
        return completeOrder(source, orderId)
    end

    MarloweDB.UpdateOrderStatus(orderId, transition.to)
    return true
end)

lib.callback.register('marlowe:server:completeDeliveryAtPoint', function(source, orderId)
    local player, err = Marlowe.ValidatePlayer(source, Config.Permissions.Deliveries, Config.RequireDuty.Deliveries)
    if not player then return false, err end

    local order = MarloweDB.GetOrder(orderId)
    if not order then return false, 'Commande introuvable.' end
    if order.status ~= 'delivering' and order.status ~= 'assigned' then
        return false, 'Cette commande ne peut pas être livrée.'
    end

    local coords = Marlowe.GetPlayerCoords(source)
    local destination = vec3(order.destination_x, order.destination_y, order.destination_z)
    if not coords or not Marlowe.IsNearCoords(coords, destination, 8.0) then
        return false, Config.Notifications.TooFar
    end

    return completeOrder(source, orderId)
end)
