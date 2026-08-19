---@param cart table[]
---@return boolean
---@return string|table
local function validateCart(cart)
    if type(cart) ~= 'table' or #cart == 0 then
        return false, 'Ticket vide.'
    end

    local lines = {}
    local subtotal = 0

    for i = 1, #cart do
        local entry = cart[i]
        local productId = type(entry.id) == 'string' and entry.id or (type(entry.productId) == 'string' and entry.productId)
        local qty = math.floor(tonumber(entry.quantity) or 0)
        local product = productId and GetProduct(productId)

        if not product or product.sellable == false or product.available == false then
            return false, 'Produit invalide dans le ticket.'
        end
        if qty < 1 or qty > 100 then
            return false, 'Quantité invalide.'
        end

        local unit = math.floor(tonumber(product.price) or 0)
        local lineTotal = unit * qty
        subtotal = subtotal + lineTotal
        lines[#lines + 1] = {
            productId = productId,
            label = product.label,
            quantity = qty,
            unitPrice = unit,
            totalPrice = lineTotal,
            item = product.item,
        }
    end

    return true, { lines = lines, subtotal = subtotal }
end

---@param source number
---@param targetId number
---@param cart table[]
---@param paymentMethod string
---@param discountPercent number|nil
---@return boolean
---@return string|table
function RexDiner.ProcessSale(source, targetId, cart, paymentMethod, discountPercent)
    if not RexDiner.CheckCooldown(source, 'sale') then
        return false, 'Patientez avant une nouvelle vente.'
    end

    local ok, err, ctx = RexDiner.Authorize(source, 'sales')
    if not ok then return false, err end

    targetId = tonumber(targetId)
    if not targetId or not GetPlayerPed(targetId) or targetId < 1 then
        return false, 'Client invalide.'
    end

    local employeePed = GetPlayerPed(source)
    local targetPed = GetPlayerPed(targetId)
    if employeePed == 0 or targetPed == 0 then
        return false, 'Client hors de portée.'
    end

    local dist = #(GetEntityCoords(employeePed) - GetEntityCoords(targetPed))
    if dist > (Config.PaymentDistance or 5.0) + 1.0 then
        return false, 'Client trop loin.'
    end

    local valid, payload = validateCart(cart)
    if not valid then return false, payload end

    discountPercent = math.floor(tonumber(discountPercent) or 0)
    if discountPercent < 0 then discountPercent = 0 end
    if discountPercent > 50 then discountPercent = 50 end
    if discountPercent > 0 and ctx.grade < 3 then
        return false, 'Grade insuffisant pour appliquer une réduction.'
    end

    local discountAmount = math.floor(payload.subtotal * (discountPercent / 100))
    local total = payload.subtotal - discountAmount
    if total < 1 then
        return false, 'Montant invalide.'
    end

    paymentMethod = paymentMethod == 'bank' and 'bank' or 'cash'

    local targetPlayer = RexDiner.GetPlayer(targetId)
    if not targetPlayer then
        return false, 'Client introuvable.'
    end

    local targetName = RexDiner.GetCharName(targetId)
    local targetCid = RexDiner.GetCitizenId(targetId)

    if not RexDiner.RemoveMoney(targetId, paymentMethod, total, 'rex_diner:sale') then
        return false, ('Le client n\'a pas assez d\'argent (%s).'):format(paymentMethod)
    end

    local commissionRate = GetCommissionRate(ctx.grade)
    local commission = math.floor(total * commissionRate)
    local societyAmount = total - commission

    if commission > 0 then
        RexDiner.AddMoney(source, 'bank', commission, 'rex_diner:commission')
    end
    if societyAmount > 0 then
        RexDiner.AddSocietyMoney(RexDiner.SocietyAccount(ctx.restaurantKey), societyAmount, 'sale')
    end

    RexDiner.EnsureEmployeeRow(ctx.restaurantKey, ctx.citizenid, ctx.name, ctx.grade)

    local saleId = MySQL.insert.await([[
        INSERT INTO rex_diner_sales
            (restaurant, employee_identifier, employee_name, customer_identifier, customer_name,
             amount, commission, commission_rate, payment_method, discount)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        ctx.restaurantKey,
        ctx.citizenid,
        ctx.name,
        targetCid,
        targetName,
        total,
        commission,
        commissionRate,
        paymentMethod,
        discountAmount,
    })

    if saleId then
        for i = 1, #payload.lines do
            local line = payload.lines[i]
            MySQL.insert.await([[
                INSERT INTO rex_diner_sale_items
                    (sale_id, product_id, product_label, quantity, unit_price, total_price)
                VALUES (?, ?, ?, ?, ?, ?)
            ]], { saleId, line.productId, line.label, line.quantity, line.unitPrice, line.totalPrice })
        end

        MySQL.update.await([[
            UPDATE rex_diner_employees
            SET total_sales = total_sales + ?, total_commission = total_commission + ?
            WHERE restaurant = ? AND identifier = ?
        ]], { total, commission, ctx.restaurantKey, ctx.citizenid })
    end

    local summaryParts = {}
    for i = 1, #payload.lines do
        summaryParts[#summaryParts + 1] = ('%s x%s'):format(payload.lines[i].label, payload.lines[i].quantity)
    end
    local summary = table.concat(summaryParts, ' ')

    local payLabel = paymentMethod == 'bank' and 'par carte' or 'en espèces'
    RexDiner.Notify(source, 'TPE — Paiement reçu',
        ('%s a payé %s (%s) %s.'):format(targetName, RexDiner.FormatMoney(total), summary, payLabel),
        'success')
    RexDiner.Notify(targetId, 'Paiement',
        ('Vous avez payé %s à %s (%s).'):format(RexDiner.FormatMoney(total), ctx.restaurant.label, payLabel),
        'inform')

    return true, {
        saleId = saleId,
        total = total,
        commission = commission,
        customer = targetName,
        summary = summary,
    }
end

---@param restaurantKey string
---@param filters table|nil
---@return table[]
function RexDiner.GetSalesHistory(restaurantKey, filters)
    filters = filters or {}
    local query = [[
        SELECT s.*,
            (SELECT GROUP_CONCAT(CONCAT(product_label, ' x', quantity) SEPARATOR ', ')
             FROM rex_diner_sale_items si WHERE si.sale_id = s.id) AS items_summary
        FROM rex_diner_sales s
        WHERE s.restaurant = ?
    ]]
    local params = { restaurantKey }

    local period = filters.period
    if period == 'today' then
        query = query .. ' AND DATE(s.created_at) = CURDATE()'
    elseif period == 'week' then
        query = query .. ' AND s.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)'
    elseif period == 'month' then
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

---@param restaurantKey string
---@param citizenid string|nil
---@return table
function RexDiner.GetStats(restaurantKey, citizenid)
    local function sumAmount(whereExtra, params)
        local row = MySQL.single.await(
            ('SELECT COALESCE(SUM(amount),0) AS total, COUNT(*) AS count FROM rex_diner_sales WHERE restaurant = ? %s'):format(whereExtra),
            params
        )
        return tonumber(row and row.total) or 0, tonumber(row and row.count) or 0
    end

    local salesTotal, salesCount = sumAmount('', { restaurantKey })
    local salesToday = sumAmount('AND DATE(created_at) = CURDATE()', { restaurantKey })
    local salesWeek = sumAmount('AND created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)', { restaurantKey })
    local salesMonth = sumAmount('AND created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)', { restaurantKey })

    local deliveryRow = MySQL.single.await([[
        SELECT COUNT(*) AS count, COALESCE(SUM(o.total_cost),0) AS total
        FROM rex_diner_deliveries d
        JOIN rex_diner_orders o ON o.id = d.order_id
        WHERE d.restaurant = ? AND d.status = 'completed'
    ]], { restaurantKey })

    local commissionTotal = 0
    local mySales = 0
    if citizenid then
        local emp = MySQL.single.await(
            'SELECT total_commission, total_sales FROM rex_diner_employees WHERE restaurant = ? AND identifier = ? LIMIT 1',
            { restaurantKey, citizenid }
        )
        commissionTotal = tonumber(emp and emp.total_commission) or 0
        mySales = tonumber(emp and emp.total_sales) or 0
    end

    local topProducts = MySQL.query.await([[
        SELECT product_id, product_label, SUM(quantity) AS qty, SUM(total_price) AS revenue
        FROM rex_diner_sale_items si
        JOIN rex_diner_sales s ON s.id = si.sale_id
        WHERE s.restaurant = ?
        GROUP BY product_id, product_label
        ORDER BY qty DESC
        LIMIT 8
    ]], { restaurantKey }) or {}

    local chartWeek = MySQL.query.await([[
        SELECT DATE(created_at) AS day, COALESCE(SUM(amount),0) AS total, COUNT(*) AS count
        FROM rex_diner_sales
        WHERE restaurant = ? AND created_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
        GROUP BY DATE(created_at)
        ORDER BY day ASC
    ]], { restaurantKey }) or {}

    return {
        salesTotal = salesTotal,
        salesCount = salesCount,
        salesToday = salesToday,
        salesWeek = salesWeek,
        salesMonth = salesMonth,
        deliveryCount = tonumber(deliveryRow and deliveryRow.count) or 0,
        deliveryEarnings = tonumber(deliveryRow and deliveryRow.total) or 0,
        commission = commissionTotal,
        mySales = mySales,
        topProducts = topProducts,
        chartWeek = chartWeek,
    }
end
