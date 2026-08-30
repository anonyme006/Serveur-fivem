local function buildCart(cart, restaurantKey)
    if type(cart) ~= 'table' or #cart == 0 then
        return false, 'Ticket vide.'
    end
    local lines, subtotal = {}, 0
    for i = 1, #cart do
        local entry = cart[i]
        local productId = type(entry.id) == 'string' and entry.id or entry.productId
        local qty = math.floor(tonumber(entry.quantity) or 0)
        local product = productId and Rex.GetProduct(productId)
        if not product or product.sellable == false or product.available == false then
            return false, 'Produit invalide.'
        end
        if restaurantKey and product.restaurants and not product.restaurants[restaurantKey] then
            return false, 'Produit non disponible dans cet établissement.'
        end
        if qty < 1 or qty > 100 then
            return false, 'Quantité invalide.'
        end
        local unit = math.floor(tonumber(product.price) or 0)
        local total = unit * qty
        subtotal = subtotal + total
        lines[#lines + 1] = {
            productId = productId,
            label = product.label,
            quantity = qty,
            unitPrice = unit,
            totalPrice = total,
        }
    end
    return true, { lines = lines, subtotal = subtotal }
end

function Rex.ProcessSale(source, targetId, cart, paymentMethod, discountPercent)
    if not Rex.Cooldown(source, 'sale') then return false, 'Patientez.' end
    local ok, err, ctx = Rex.Authorize(source, 'sales')
    if not ok then return false, err end

    targetId = tonumber(targetId)
    if not targetId or GetPlayerPed(targetId) == 0 then
        return false, 'Client invalide.'
    end

    local dist = #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(GetPlayerPed(targetId)))
    if dist > (Config.PaymentDistance or 5.0) + 1.0 then
        return false, 'Client trop loin.'
    end

    local valid, payload = buildCart(cart, ctx.key)
    if not valid then return false, payload end

    discountPercent = math.floor(tonumber(discountPercent) or 0)
    if discountPercent < 0 then discountPercent = 0 end
    if discountPercent > (Config.MaxDiscount or 50) then
        discountPercent = Config.MaxDiscount or 50
    end
    if discountPercent > 0 and ctx.grade < 3 then
        return false, 'Grade insuffisant pour une réduction.'
    end

    local discountAmount = math.floor(payload.subtotal * (discountPercent / 100))
    local total = payload.subtotal - discountAmount
    if total < 1 then return false, 'Montant invalide.' end

    paymentMethod = paymentMethod == 'bank' and 'bank' or 'cash'
    if not Rex.GetPlayer(targetId) then return false, 'Client introuvable.' end

    local targetName = Rex.GetName(targetId)
    local targetCid = Rex.GetCitizenId(targetId)

    if not Rex.RemoveMoney(targetId, paymentMethod, total, 'rex_diner:sale') then
        return false, ('Fonds insuffisants (%s).'):format(paymentMethod)
    end

    local rate = Rex.GetCommissionRate(ctx.grade)
    local commission = math.floor(total * rate)
    local society = total - commission

    if commission > 0 then
        Rex.AddMoney(source, 'bank', commission, 'rex_diner:commission')
    end
    if society > 0 then
        Rex.AddSociety(Rex.SocietyAccount(ctx.key), society, 'sale')
    end

    Rex.EnsureEmployee(ctx.key, ctx.citizenid, ctx.name, ctx.grade)

    local saleId = MySQL.insert.await([[
        INSERT INTO rex_diner_sales
            (restaurant, employee_identifier, employee_name, customer_identifier, customer_name,
             amount, commission, commission_rate, payment_method, discount)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        ctx.key, ctx.citizenid, ctx.name, targetCid, targetName,
        total, commission, rate, paymentMethod, discountAmount,
    })

    if saleId then
        for i = 1, #payload.lines do
            local l = payload.lines[i]
            MySQL.insert.await([[
                INSERT INTO rex_diner_sale_items
                    (sale_id, product_id, product_label, quantity, unit_price, total_price)
                VALUES (?, ?, ?, ?, ?, ?)
            ]], { saleId, l.productId, l.label, l.quantity, l.unitPrice, l.totalPrice })
        end
        MySQL.update.await([[
            UPDATE rex_diner_employees
            SET total_sales = total_sales + ?, total_commission = total_commission + ?
            WHERE restaurant = ? AND identifier = ?
        ]], { total, commission, ctx.key, ctx.citizenid })
    end

    local parts = {}
    for i = 1, #payload.lines do
        parts[#parts + 1] = ('%s x%s'):format(payload.lines[i].label, payload.lines[i].quantity)
    end
    local summary = table.concat(parts, ' ')
    local payLabel = paymentMethod == 'bank' and 'par carte en sans contact' or 'en espèces'

    Rex.Notify(source, 'TPE — Paiement reçu',
        ('%s a payé %s (%s) %s.'):format(targetName, Rex.FormatMoney(total), summary, payLabel), 'success')
    Rex.Notify(targetId, 'Paiement',
        ('Vous avez payé %s à %s.'):format(Rex.FormatMoney(total), ctx.restaurant.label), 'inform')

    return true, {
        saleId = saleId,
        total = total,
        commission = commission,
        customer = targetName,
        summary = summary,
    }
end

function Rex.GetSales(restaurantKey, filters)
    filters = filters or {}
    local query = [[
        SELECT s.*,
            (SELECT GROUP_CONCAT(CONCAT(product_label, ' x', quantity) SEPARATOR ', ')
             FROM rex_diner_sale_items si WHERE si.sale_id = s.id) AS items_summary
        FROM rex_diner_sales s WHERE s.restaurant = ?
    ]]
    local params = { restaurantKey }

    if filters.period == 'today' then
        query = query .. ' AND DATE(s.created_at) = CURDATE()'
    elseif filters.period == 'week' then
        query = query .. ' AND s.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)'
    elseif filters.period == 'month' then
        query = query .. ' AND s.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)'
    end
    if filters.employee and filters.employee ~= '' then
        query = query .. ' AND s.employee_identifier = ?'
        params[#params + 1] = filters.employee
    end
    if filters.minAmount then
        query = query .. ' AND s.amount >= ?'
        params[#params + 1] = math.floor(tonumber(filters.minAmount) or 0)
    end
    query = query .. ' ORDER BY s.created_at DESC LIMIT 100'
    return MySQL.query.await(query, params) or {}
end

function Rex.GetStats(restaurantKey, citizenid)
    local function agg(extra, params)
        local row = MySQL.single.await(
            ('SELECT COALESCE(SUM(amount),0) AS total, COUNT(*) AS count FROM rex_diner_sales WHERE restaurant = ? %s'):format(extra),
            params
        )
        return tonumber(row and row.total) or 0, tonumber(row and row.count) or 0
    end

    local salesTotal, salesCount = agg('', { restaurantKey })
    local salesToday = agg('AND DATE(created_at) = CURDATE()', { restaurantKey })
    local salesWeek = agg('AND created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)', { restaurantKey })
    local salesMonth = agg('AND created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)', { restaurantKey })

    local delivery = MySQL.single.await([[
        SELECT COUNT(*) AS count, COALESCE(SUM(o.total_cost),0) AS total
        FROM rex_diner_deliveries d
        JOIN rex_diner_orders o ON o.id = d.order_id
        WHERE d.restaurant = ? AND d.status = 'completed'
    ]], { restaurantKey })

    local commission, mySales = 0, 0
    if citizenid then
        local emp = MySQL.single.await(
            'SELECT total_commission, total_sales FROM rex_diner_employees WHERE restaurant = ? AND identifier = ? LIMIT 1',
            { restaurantKey, citizenid }
        )
        commission = tonumber(emp and emp.total_commission) or 0
        mySales = tonumber(emp and emp.total_sales) or 0
    end

    local topProducts = MySQL.query.await([[
        SELECT product_id, product_label, SUM(quantity) AS qty, SUM(total_price) AS revenue
        FROM rex_diner_sale_items si
        JOIN rex_diner_sales s ON s.id = si.sale_id
        WHERE s.restaurant = ?
        GROUP BY product_id, product_label
        ORDER BY qty DESC LIMIT 8
    ]], { restaurantKey }) or {}

    local chartWeek = MySQL.query.await([[
        SELECT DATE(created_at) AS day, COALESCE(SUM(amount),0) AS total, COUNT(*) AS count
        FROM rex_diner_sales
        WHERE restaurant = ? AND created_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
        GROUP BY DATE(created_at) ORDER BY day ASC
    ]], { restaurantKey }) or {}

    return {
        salesTotal = salesTotal,
        salesCount = salesCount,
        salesToday = salesToday,
        salesWeek = salesWeek,
        salesMonth = salesMonth,
        deliveryCount = tonumber(delivery and delivery.count) or 0,
        deliveryEarnings = tonumber(delivery and delivery.total) or 0,
        commission = commission,
        mySales = mySales,
        topProducts = topProducts,
        chartWeek = chartWeek,
    }
end
