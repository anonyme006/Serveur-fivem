---@param source number
---@param targetId number
---@param amount number
---@param reason string
---@return boolean
---@return string|number
function RexDiner.CreateInvoice(source, targetId, amount, reason)
    if not Config.EnableBilling then
        return false, 'Facturation désactivée.'
    end
    if not RexDiner.CheckCooldown(source, 'invoice') then
        return false, 'Patientez avant une nouvelle facture.'
    end

    local ok, err, ctx = RexDiner.Authorize(source, 'billing')
    if not ok then return false, err end

    targetId = tonumber(targetId)
    amount = math.floor(tonumber(amount) or 0)
    reason = type(reason) == 'string' and reason:sub(1, 240) or ''

    if not targetId or targetId < 1 or not GetPlayerPed(targetId) then
        return false, 'Cible invalide.'
    end
    if amount < 1 or amount > 10000000 then
        return false, 'Montant invalide.'
    end
    if reason == '' then
        reason = 'Facture restaurant'
    end

    local employeePed = GetPlayerPed(source)
    local targetPed = GetPlayerPed(targetId)
    local dist = #(GetEntityCoords(employeePed) - GetEntityCoords(targetPed))
    if dist > (Config.PaymentDistance or 5.0) + 2.0 then
        return false, 'Client trop loin.'
    end

    local targetCid = RexDiner.GetCitizenId(targetId)
    local targetName = RexDiner.GetCharName(targetId)
    if not targetCid then
        return false, 'Client introuvable.'
    end

    local invoiceId = MySQL.insert.await([[
        INSERT INTO rex_diner_invoices
            (restaurant, issuer_identifier, issuer_name, target_identifier, target_name, amount, reason, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, 'pending')
    ]], {
        ctx.restaurantKey,
        ctx.citizenid,
        ctx.name,
        targetCid,
        targetName,
        amount,
        reason,
    })

    if not invoiceId then
        return false, 'Erreur SQL facture.'
    end

    RexDiner.Notify(source, 'Factures',
        ('Facture de %s envoyée à %s — TPE affiché.'):format(RexDiner.FormatMoney(amount), targetName),
        'success')

    TriggerClientEvent('rex_diner:client:invoicePrompt', targetId, {
        id = invoiceId,
        amount = amount,
        reason = reason,
        issuer = ctx.name,
        restaurant = ctx.restaurant.label,
    })

    return true, invoiceId
end

---@param source number
---@param invoiceId number
---@param paymentMethod string
---@return boolean
---@return string
function RexDiner.PayInvoice(source, invoiceId, paymentMethod)
    invoiceId = tonumber(invoiceId)
    if not invoiceId then return false, 'Facture invalide.' end

    local citizenid = RexDiner.GetCitizenId(source)
    if not citizenid then return false, 'Joueur invalide.' end

    local invoice = MySQL.single.await(
        'SELECT * FROM rex_diner_invoices WHERE id = ? LIMIT 1',
        { invoiceId }
    )
    if not invoice then return false, 'Facture introuvable.' end
    if invoice.target_identifier ~= citizenid then
        return false, 'Cette facture ne vous appartient pas.'
    end
    if invoice.status ~= 'pending' then
        return false, 'Facture déjà traitée.'
    end

    paymentMethod = paymentMethod == 'bank' and 'bank' or 'cash'
    local amount = math.floor(tonumber(invoice.amount) or 0)
    if amount < 1 then return false, 'Montant invalide.' end

    if not RexDiner.RemoveMoney(source, paymentMethod, amount, 'rex_diner:invoice') then
        return false, 'Fonds insuffisants.'
    end

    local restaurantKey = invoice.restaurant
    local issuerSource = nil
    for src, player in pairs(RexDiner.GetOnlinePlayers()) do
        if player and player.PlayerData and player.PlayerData.citizenid == invoice.issuer_identifier then
            issuerSource = src
            break
        end
    end

    local grade = 1
    if issuerSource then
        local _, g = RexDiner.GetJob(issuerSource)
        grade = g
    else
        local emp = MySQL.single.await(
            'SELECT grade FROM rex_diner_employees WHERE restaurant = ? AND identifier = ? LIMIT 1',
            { restaurantKey, invoice.issuer_identifier }
        )
        grade = emp and tonumber(emp.grade) or 1
    end

    local commissionRate = GetCommissionRate(grade)
    local commission = math.floor(amount * commissionRate)
    local societyAmount = amount - commission

    if issuerSource and commission > 0 then
        RexDiner.AddMoney(issuerSource, 'bank', commission, 'rex_diner:invoice_commission')
    end
    RexDiner.AddSocietyMoney(RexDiner.SocietyAccount(restaurantKey), societyAmount, 'invoice')

    local saleId = MySQL.insert.await([[
        INSERT INTO rex_diner_sales
            (restaurant, employee_identifier, employee_name, customer_identifier, customer_name,
             amount, commission, commission_rate, payment_method, discount)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
    ]], {
        restaurantKey,
        invoice.issuer_identifier,
        invoice.issuer_name,
        invoice.target_identifier,
        invoice.target_name,
        amount,
        commission,
        commissionRate,
        paymentMethod == 'bank' and 'card' or 'cash',
    })

    if saleId and invoice.reason and invoice.reason ~= '' then
        MySQL.insert.await([[
            INSERT INTO rex_diner_sale_items
                (sale_id, product_id, product_label, quantity, unit_price, total_price)
            VALUES (?, 'invoice', ?, 1, ?, ?)
        ]], { saleId, invoice.reason, amount, amount })
    end

    MySQL.update.await([[
        UPDATE rex_diner_invoices
        SET status = 'paid', paid_at = CURRENT_TIMESTAMP, sale_id = ?
        WHERE id = ? AND status = 'pending'
    ]], { saleId, invoiceId })

    MySQL.update.await([[
        UPDATE rex_diner_employees
        SET total_sales = total_sales + ?, total_commission = total_commission + ?
        WHERE restaurant = ? AND identifier = ?
    ]], { amount, commission, restaurantKey, invoice.issuer_identifier })

    local payerName = RexDiner.GetCharName(source)
    if issuerSource then
        RexDiner.Notify(issuerSource, 'TPE — Paiement reçu',
            ('%s a payé %s (%s) par carte.'):format(payerName, RexDiner.FormatMoney(amount), invoice.reason),
            'success')
    end
    RexDiner.Notify(source, 'Factures', ('Facture #%s payée.'):format(invoiceId), 'success')

    return true, 'Facture payée.'
end

---@param source number
---@param invoiceId number
---@return boolean
---@return string
function RexDiner.CancelInvoice(source, invoiceId)
    invoiceId = tonumber(invoiceId)
    if not invoiceId then return false, 'Facture invalide.' end

    local citizenid = RexDiner.GetCitizenId(source)
    local invoice = MySQL.single.await('SELECT * FROM rex_diner_invoices WHERE id = ? LIMIT 1', { invoiceId })
    if not invoice or invoice.status ~= 'pending' then
        return false, 'Facture introuvable.'
    end

    local isIssuer = invoice.issuer_identifier == citizenid
    local isTarget = invoice.target_identifier == citizenid
    if not isIssuer and not isTarget then
        local ok = RexDiner.Authorize(source, 'finances', false)
        if not ok then return false, 'Permission refusée.' end
    end

    MySQL.update.await(
        'UPDATE rex_diner_invoices SET status = ? WHERE id = ? AND status = ?',
        { 'cancelled', invoiceId, 'pending' }
    )
    return true, 'Facture annulée.'
end

---@param restaurantKey string
---@param citizenid string|nil
---@return table[]
function RexDiner.GetInvoices(restaurantKey, citizenid)
    if citizenid then
        return MySQL.query.await([[
            SELECT * FROM rex_diner_invoices
            WHERE restaurant = ? AND (issuer_identifier = ? OR target_identifier = ?)
            ORDER BY created_at DESC LIMIT 50
        ]], { restaurantKey, citizenid, citizenid }) or {}
    end
    return MySQL.query.await([[
        SELECT * FROM rex_diner_invoices
        WHERE restaurant = ?
        ORDER BY created_at DESC LIMIT 50
    ]], { restaurantKey }) or {}
end
