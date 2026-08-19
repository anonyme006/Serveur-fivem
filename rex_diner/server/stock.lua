---@param restaurantKey string
function RexDiner.InitStock(restaurantKey)
    for item, data in pairs(StockItems) do
        MySQL.insert.await([[
            INSERT IGNORE INTO rex_diner_stock (restaurant, item, quantity, max_quantity, min_quantity)
            VALUES (?, ?, ?, ?, ?)
        ]], { restaurantKey, item, data.min or 20, data.max or 100, data.min or 10 })
    end
end

---@param restaurantKey string
---@param item string
---@return table|nil
function RexDiner.GetStockItem(restaurantKey, item)
    return MySQL.single.await(
        'SELECT * FROM rex_diner_stock WHERE restaurant = ? AND item = ? LIMIT 1',
        { restaurantKey, item }
    )
end

---@param restaurantKey string
---@return table[]
function RexDiner.GetStock(restaurantKey)
    local rows = MySQL.query.await(
        'SELECT * FROM rex_diner_stock WHERE restaurant = ? ORDER BY item ASC',
        { restaurantKey }
    ) or {}

    local result = {}
    for i = 1, #rows do
        local row = rows[i]
        local meta = StockItems[row.item] or {}
        local qty = tonumber(row.quantity) or 0
        local minQty = tonumber(row.min_quantity) or meta.min or 10
        local status = 'ok'
        if qty <= 0 then
            status = 'out'
        elseif qty <= minQty then
            status = 'low'
        end
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

---@param restaurantKey string
---@param item string
---@param amount number
---@return boolean
function RexDiner.AddStock(restaurantKey, item, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount == 0 then return true end
    local affected = MySQL.update.await([[
        UPDATE rex_diner_stock
        SET quantity = GREATEST(0, quantity + ?)
        WHERE restaurant = ? AND item = ?
    ]], { amount, restaurantKey, item })
    if affected and affected > 0 then return true end

    local meta = StockItems[item]
    if not meta then return false end
    MySQL.insert.await([[
        INSERT INTO rex_diner_stock (restaurant, item, quantity, max_quantity, min_quantity)
        VALUES (?, ?, ?, ?, ?)
    ]], { restaurantKey, item, math.max(0, amount), meta.max or 100, meta.min or 10 })
    return true
end

---@param restaurantKey string
---@param item string
---@param amount number
---@return boolean
function RexDiner.RemoveStock(restaurantKey, item, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return true end
    local row = RexDiner.GetStockItem(restaurantKey, item)
    if not row or (tonumber(row.quantity) or 0) < amount then
        return false
    end
    MySQL.update.await(
        'UPDATE rex_diner_stock SET quantity = quantity - ? WHERE restaurant = ? AND item = ? AND quantity >= ?',
        { amount, restaurantKey, item, amount }
    )
    return true
end

---@param restaurantKey string
---@param ingredients table<string, number>
---@return boolean
---@return string|nil
function RexDiner.HasStockIngredients(restaurantKey, ingredients)
    for item, amount in pairs(ingredients) do
        amount = math.floor(tonumber(amount) or 0)
        if amount > 0 then
            local row = RexDiner.GetStockItem(restaurantKey, item)
            if not row or (tonumber(row.quantity) or 0) < amount then
                return false, item
            end
        end
    end
    return true
end

---@param restaurantKey string
---@param ingredients table<string, number>
---@return boolean
function RexDiner.ConsumeStockIngredients(restaurantKey, ingredients)
    local ok, missing = RexDiner.HasStockIngredients(restaurantKey, ingredients)
    if not ok then return false, missing end
    for item, amount in pairs(ingredients) do
        amount = math.floor(tonumber(amount) or 0)
        if amount > 0 then
            if not RexDiner.RemoveStock(restaurantKey, item, amount) then
                return false, item
            end
        end
    end
    return true
end

--- Create a supplier order
---@param source number
---@param items table[] { item: string, quantity: number }
---@return boolean
---@return string|number
function RexDiner.CreateOrder(source, items)
    if not Config.EnableDeliveries and not Config.EnableStock then
        return false, 'Commandes désactivées.'
    end
    if not RexDiner.CheckCooldown(source, 'order') then
        return false, 'Patientez avant de commander à nouveau.'
    end

    local ok, err, ctx = RexDiner.Authorize(source, 'orders')
    if not ok then return false, err end

    if type(items) ~= 'table' or #items == 0 then
        return false, 'Panier de commande vide.'
    end

    local orderItems = {}
    local totalCost = 0
    for i = 1, #items do
        local entry = items[i]
        local itemName = type(entry.item) == 'string' and entry.item or nil
        local qty = math.floor(tonumber(entry.quantity) or 0)
        local meta = itemName and StockItems[itemName]
        if meta and qty > 0 then
            local unit = meta.orderPrice or 10
            orderItems[#orderItems + 1] = {
                item = itemName,
                label = meta.label or itemName,
                quantity = qty,
                unit_price = unit,
            }
            totalCost = totalCost + (unit * qty)
        end
    end

    if #orderItems == 0 then
        return false, 'Aucun article valide.'
    end

    local orderId = MySQL.insert.await([[
        INSERT INTO rex_diner_orders (restaurant, ordered_by, ordered_by_name, total_cost, status)
        VALUES (?, ?, ?, ?, 'pending')
    ]], { ctx.restaurantKey, ctx.citizenid, ctx.name, totalCost })

    if not orderId then
        return false, 'Erreur SQL commande.'
    end

    for i = 1, #orderItems do
        local it = orderItems[i]
        MySQL.insert.await([[
            INSERT INTO rex_diner_order_items (order_id, item, label, quantity, unit_price)
            VALUES (?, ?, ?, ?, ?)
        ]], { orderId, it.item, it.label, it.quantity, it.unit_price })
    end

    MySQL.insert.await([[
        INSERT INTO rex_diner_deliveries (order_id, restaurant, status)
        VALUES (?, ?, 'waiting')
    ]], { orderId, ctx.restaurantKey })

    RexDiner.Notify(source, 'Commandes', ('Commande #%s créée (%s).'):format(orderId, RexDiner.FormatMoney(totalCost)), 'success')
    return true, orderId
end

---@param restaurantKey string
---@return table[]
function RexDiner.GetOrders(restaurantKey)
    local orders = MySQL.query.await([[
        SELECT o.*, d.id AS delivery_id, d.status AS delivery_status, d.driver_name
        FROM rex_diner_orders o
        LEFT JOIN rex_diner_deliveries d ON d.order_id = o.id
        WHERE o.restaurant = ?
        ORDER BY o.created_at DESC
        LIMIT 50
    ]], { restaurantKey }) or {}

    for i = 1, #orders do
        orders[i].items = MySQL.query.await(
            'SELECT item, label, quantity, unit_price FROM rex_diner_order_items WHERE order_id = ?',
            { orders[i].id }
        ) or {}
    end
    return orders
end

---@param source number
---@param deliveryId number
---@return boolean
---@return string|table
function RexDiner.TakeDelivery(source, deliveryId)
    if not Config.EnableDeliveries then
        return false, 'Livraisons désactivées.'
    end

    local ok, err, ctx = RexDiner.Authorize(source, 'deliveries')
    if not ok then return false, err end

    deliveryId = tonumber(deliveryId)
    if not deliveryId then return false, 'Livraison invalide.' end

    if RexDiner.ActiveDeliveries[source] then
        return false, 'Vous avez déjà une livraison en cours.'
    end

    local delivery = MySQL.single.await([[
        SELECT d.*, o.status AS order_status
        FROM rex_diner_deliveries d
        JOIN rex_diner_orders o ON o.id = d.order_id
        WHERE d.id = ? AND d.restaurant = ?
        LIMIT 1
    ]], { deliveryId, ctx.restaurantKey })

    if not delivery then
        return false, 'Livraison introuvable.'
    end
    if delivery.status ~= 'waiting' then
        return false, 'Cette livraison n\'est plus disponible.'
    end

    MySQL.update.await([[
        UPDATE rex_diner_deliveries
        SET status = 'in_progress', driver_identifier = ?, driver_name = ?, started_at = CURRENT_TIMESTAMP
        WHERE id = ? AND status = 'waiting'
    ]], { ctx.citizenid, ctx.name, deliveryId })

    MySQL.update.await(
        'UPDATE rex_diner_orders SET status = ? WHERE id = ?',
        { 'in_transit', delivery.order_id }
    )

    RexDiner.ActiveDeliveries[source] = deliveryId

    local pickup = Config.Delivery.pickup
    return true, {
        deliveryId = deliveryId,
        orderId = delivery.order_id,
        pickup = { x = pickup.x, y = pickup.y, z = pickup.z, w = pickup.w },
        vehicle = Config.Delivery.vehicle,
        dropoff = ctx.restaurant.locations and ctx.restaurant.locations.Delivery and {
            x = ctx.restaurant.locations.Delivery.coords.x,
            y = ctx.restaurant.locations.Delivery.coords.y,
            z = ctx.restaurant.locations.Delivery.coords.z,
        } or nil,
    }
end

---@param source number
---@param deliveryId number
---@return boolean
---@return string
function RexDiner.CompleteDelivery(source, deliveryId)
    local ok, err, ctx = RexDiner.Authorize(source, 'deliveries')
    if not ok then return false, err end

    deliveryId = tonumber(deliveryId)
    if not deliveryId then return false, 'Livraison invalide.' end
    if RexDiner.ActiveDeliveries[source] ~= deliveryId then
        return false, 'Cette livraison ne vous est pas assignée.'
    end

    local delivery = MySQL.single.await(
        'SELECT * FROM rex_diner_deliveries WHERE id = ? AND restaurant = ? LIMIT 1',
        { deliveryId, ctx.restaurantKey }
    )
    if not delivery or delivery.status ~= 'in_progress' then
        return false, 'Livraison invalide.'
    end

    local drop = ctx.restaurant.locations and ctx.restaurant.locations.Delivery
    if drop then
        local ped = GetPlayerPed(source)
        local coords = GetEntityCoords(ped)
        local dist = #(coords - drop.coords)
        if dist > 15.0 then
            return false, 'Trop loin du point de dépôt.'
        end
    end

    local items = MySQL.query.await(
        'SELECT item, quantity FROM rex_diner_order_items WHERE order_id = ?',
        { delivery.order_id }
    ) or {}

    for i = 1, #items do
        RexDiner.AddStock(ctx.restaurantKey, items[i].item, items[i].quantity)
    end

    MySQL.update.await([[
        UPDATE rex_diner_deliveries
        SET status = 'completed', completed_at = CURRENT_TIMESTAMP
        WHERE id = ?
    ]], { deliveryId })

    MySQL.update.await([[
        UPDATE rex_diner_orders
        SET status = 'delivered', delivered_at = CURRENT_TIMESTAMP
        WHERE id = ?
    ]], { delivery.order_id })

    RexDiner.ActiveDeliveries[source] = nil
    RexDiner.Notify(source, 'Livraisons', ('Livraison #%s déposée en stock.'):format(delivery.order_id), 'success')
    return true, 'Livraison terminée.'
end
