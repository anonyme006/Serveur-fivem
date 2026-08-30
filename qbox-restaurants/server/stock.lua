function Rest.InitStock(restaurantKey)
    for item, data in pairs(StockItems) do
        MySQL.insert.await([[
            INSERT IGNORE INTO qbox_restaurants_stock (restaurant, item, quantity, max_quantity, min_quantity)
            VALUES (?, ?, ?, ?, ?)
        ]], { restaurantKey, item, data.min or 20, data.max or 100, data.min or 10 })
    end
end

function Rest.GetStockRow(restaurantKey, item)
    return MySQL.single.await(
        'SELECT * FROM qbox_restaurants_stock WHERE restaurant = ? AND item = ? LIMIT 1',
        { restaurantKey, item }
    )
end

function Rest.GetStock(restaurantKey)
    local rows = MySQL.query.await(
        'SELECT * FROM qbox_restaurants_stock WHERE restaurant = ? ORDER BY item ASC',
        { restaurantKey }
    ) or {}
    local result = {}
    for i = 1, #rows do
        local row = rows[i]
        local meta = StockItems[row.item] or {}
        local qty = tonumber(row.quantity) or 0
        local minQty = tonumber(row.min_quantity) or meta.min or 10
        local status = qty <= 0 and 'out' or (qty <= minQty and 'low' or 'ok')
        result[#result + 1] = {
            item = row.item,
            label = meta.label or row.item,
            icon = meta.icon or '📦',
            quantity = qty,
            max = tonumber(row.max_quantity) or meta.max or 100,
            min = minQty,
            status = status,
            orderPrice = meta.orderPrice or 10,
        }
    end
    return result
end

function Rest.AddStock(restaurantKey, item, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount == 0 then return true end
    local affected = MySQL.update.await(
        'UPDATE qbox_restaurants_stock SET quantity = GREATEST(0, quantity + ?) WHERE restaurant = ? AND item = ?',
        { amount, restaurantKey, item }
    )
    if affected and affected > 0 then return true end
    local meta = StockItems[item]
    if not meta then return false end
    MySQL.insert.await(
        'INSERT INTO qbox_restaurants_stock (restaurant, item, quantity, max_quantity, min_quantity) VALUES (?, ?, ?, ?, ?)',
        { restaurantKey, item, math.max(0, amount), meta.max or 100, meta.min or 10 }
    )
    return true
end

function Rest.RemoveStock(restaurantKey, item, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return true end
    local row = Rest.GetStockRow(restaurantKey, item)
    if not row or (tonumber(row.quantity) or 0) < amount then return false end
    MySQL.update.await(
        'UPDATE qbox_restaurants_stock SET quantity = quantity - ? WHERE restaurant = ? AND item = ? AND quantity >= ?',
        { amount, restaurantKey, item, amount }
    )
    return true
end

function Rest.HasStock(restaurantKey, ingredients)
    for item, amount in pairs(ingredients) do
        amount = math.floor(tonumber(amount) or 0)
        if amount > 0 then
            local row = Rest.GetStockRow(restaurantKey, item)
            if not row or (tonumber(row.quantity) or 0) < amount then
                return false, item
            end
        end
    end
    return true
end

function Rest.ConsumeStock(restaurantKey, ingredients)
    local ok, missing = Rest.HasStock(restaurantKey, ingredients)
    if not ok then return false, missing end
    for item, amount in pairs(ingredients) do
        amount = math.floor(tonumber(amount) or 0)
        if amount > 0 and not Rest.RemoveStock(restaurantKey, item, amount) then
            return false, item
        end
    end
    return true
end

function Rest.CreateOrder(source, items)
    if not Config.EnableStock then return false, 'Stock désactivé.' end
    if not Rest.Cooldown(source, 'order') then return false, 'Patientez.' end
    local ok, err, ctx = Rest.Authorize(source, 'orders')
    if not ok then return false, err end
    if type(items) ~= 'table' or #items == 0 then return false, 'Panier vide.' end

    local lines, total = {}, 0
    for i = 1, #items do
        local entry = items[i]
        local name = type(entry.item) == 'string' and entry.item
        local qty = math.floor(tonumber(entry.quantity) or 0)
        local meta = name and StockItems[name]
        if meta and qty > 0 and qty <= 500 then
            local unit = meta.orderPrice or 10
            lines[#lines + 1] = { item = name, label = meta.label, quantity = qty, unit_price = unit }
            total = total + unit * qty
        end
    end
    if #lines == 0 then return false, 'Aucun article valide.' end

    local orderId = MySQL.insert.await(
        'INSERT INTO qbox_restaurants_orders (restaurant, ordered_by, ordered_by_name, total_cost, status) VALUES (?, ?, ?, ?, ?)',
        { ctx.key, ctx.citizenid, ctx.name, total, 'pending' }
    )
    if not orderId then return false, 'Erreur SQL.' end

    for i = 1, #lines do
        local l = lines[i]
        MySQL.insert.await(
            'INSERT INTO qbox_restaurants_order_items (order_id, item, label, quantity, unit_price) VALUES (?, ?, ?, ?, ?)',
            { orderId, l.item, l.label, l.quantity, l.unit_price }
        )
    end
    MySQL.insert.await(
        'INSERT INTO qbox_restaurants_deliveries (order_id, restaurant, status) VALUES (?, ?, ?)',
        { orderId, ctx.key, 'waiting' }
    )
    Rest.Notify(source, 'Commandes', ('Commande #%s créée (%s).'):format(orderId, Rest.FormatMoney(total)), 'success')
    return true, orderId
end

function Rest.GetOrders(restaurantKey)
    local orders = MySQL.query.await([[
        SELECT o.*, d.id AS delivery_id, d.status AS delivery_status, d.driver_name
        FROM qbox_restaurants_orders o
        LEFT JOIN qbox_restaurants_deliveries d ON d.order_id = o.id
        WHERE o.restaurant = ?
        ORDER BY o.created_at DESC LIMIT 50
    ]], { restaurantKey }) or {}
    for i = 1, #orders do
        orders[i].items = MySQL.query.await(
            'SELECT item, label, quantity, unit_price FROM qbox_restaurants_order_items WHERE order_id = ?',
            { orders[i].id }
        ) or {}
    end
    return orders
end

function Rest.TakeDelivery(source, deliveryId)
    if not Config.EnableDeliveries then return false, 'Livraisons désactivées.' end
    local ok, err, ctx = Rest.Authorize(source, 'deliveries')
    if not ok then return false, err end
    deliveryId = tonumber(deliveryId)
    if not deliveryId then return false, 'Livraison invalide.' end
    if Rest.ActiveDeliveries[source] then return false, 'Livraison déjà en cours.' end

    local delivery = MySQL.single.await([[
        SELECT d.*, o.status AS order_status FROM qbox_restaurants_deliveries d
        JOIN qbox_restaurants_orders o ON o.id = d.order_id
        WHERE d.id = ? AND d.restaurant = ? LIMIT 1
    ]], { deliveryId, ctx.key })
    if not delivery or delivery.status ~= 'waiting' then
        return false, 'Livraison indisponible.'
    end

    MySQL.update.await([[
        UPDATE qbox_restaurants_deliveries
        SET status = 'in_progress', driver_identifier = ?, driver_name = ?, started_at = CURRENT_TIMESTAMP
        WHERE id = ? AND status = 'waiting'
    ]], { ctx.citizenid, ctx.name, deliveryId })
    MySQL.update.await('UPDATE qbox_restaurants_orders SET status = ? WHERE id = ?', { 'in_transit', delivery.order_id })
    Rest.ActiveDeliveries[source] = deliveryId

    local pickup = Config.Delivery.pickup
    local drop = ctx.restaurant.locations and ctx.restaurant.locations.Delivery
    return true, {
        deliveryId = deliveryId,
        orderId = delivery.order_id,
        pickup = { x = pickup.x, y = pickup.y, z = pickup.z, w = pickup.w },
        vehicle = Config.Delivery.vehicle,
        dropoff = drop and { x = drop.coords.x, y = drop.coords.y, z = drop.coords.z } or nil,
    }
end

function Rest.CompleteDelivery(source, deliveryId)
    local ok, err, ctx = Rest.Authorize(source, 'deliveries')
    if not ok then return false, err end
    deliveryId = tonumber(deliveryId)
    if not deliveryId or Rest.ActiveDeliveries[source] ~= deliveryId then
        return false, 'Livraison non assignée.'
    end

    local delivery = MySQL.single.await(
        'SELECT * FROM qbox_restaurants_deliveries WHERE id = ? AND restaurant = ? LIMIT 1',
        { deliveryId, ctx.key }
    )
    if not delivery or delivery.status ~= 'in_progress' then
        return false, 'Livraison invalide.'
    end

    local drop = ctx.restaurant.locations and ctx.restaurant.locations.Delivery
    if drop then
        local dist = #(GetEntityCoords(GetPlayerPed(source)) - drop.coords)
        if dist > 15.0 then return false, 'Trop loin du dépôt.' end
    end

    local items = MySQL.query.await(
        'SELECT item, quantity FROM qbox_restaurants_order_items WHERE order_id = ?',
        { delivery.order_id }
    ) or {}
    for i = 1, #items do
        Rest.AddStock(ctx.key, items[i].item, items[i].quantity)
    end

    MySQL.update.await(
        'UPDATE qbox_restaurants_deliveries SET status = ?, completed_at = CURRENT_TIMESTAMP WHERE id = ?',
        { 'completed', deliveryId }
    )
    MySQL.update.await(
        'UPDATE qbox_restaurants_orders SET status = ?, delivered_at = CURRENT_TIMESTAMP WHERE id = ?',
        { 'delivered', delivery.order_id }
    )
    Rest.ActiveDeliveries[source] = nil
    Rest.Notify(source, 'Livraisons', ('Livraison #%s déposée.'):format(delivery.order_id), 'success')
    return true, 'OK'
end
