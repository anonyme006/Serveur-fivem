function Rest.CreateInvoice(source, targetId, amount, reason)
    if not Config.EnableBilling then return false, 'Facturation désactivée.' end
    if not Rest.Cooldown(source, 'invoice') then return false, 'Patientez.' end
    local ok, err, ctx = Rest.Authorize(source, 'billing')
    if not ok then return false, err end

    targetId = tonumber(targetId)
    amount = math.floor(tonumber(amount) or 0)
    reason = type(reason) == 'string' and reason:sub(1, 240) or ''
    if reason == '' then reason = 'Facture restaurant' end

    if not targetId or GetPlayerPed(targetId) == 0 then return false, 'Cible invalide.' end
    if amount < 1 or amount > 10000000 then return false, 'Montant invalide.' end

    local dist = #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(GetPlayerPed(targetId)))
    if dist > (Config.PaymentDistance or 5.0) + 2.0 then
        return false, 'Client trop loin.'
    end

    local targetCid = Rest.GetCitizenId(targetId)
    local targetName = Rest.GetName(targetId)
    if not targetCid then return false, 'Client introuvable.' end

    local invoiceId = MySQL.insert.await([[
        INSERT INTO qbox_restaurants_invoices
            (restaurant, issuer_identifier, issuer_name, target_identifier, target_name, amount, reason, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, 'pending')
    ]], { ctx.key, ctx.citizenid, ctx.name, targetCid, targetName, amount, reason })

    if not invoiceId then return false, 'Erreur SQL.' end

    Rest.Notify(source, 'Factures',
        ('Facture de %s envoyée à %s — TPE affiché.'):format(Rest.FormatMoney(amount), targetName), 'success')

    TriggerClientEvent('qbox_restaurants:client:invoicePrompt', targetId, {
        id = invoiceId,
        amount = amount,
        reason = reason,
        issuer = ctx.name,
        restaurant = ctx.restaurant.label,
    })
    return true, invoiceId
end

function Rest.PayInvoice(source, invoiceId, paymentMethod)
    invoiceId = tonumber(invoiceId)
    if not invoiceId then return false, 'Facture invalide.' end
    local citizenid = Rest.GetCitizenId(source)
    if not citizenid then return false, 'Joueur invalide.' end

    local invoice = MySQL.single.await('SELECT * FROM qbox_restaurants_invoices WHERE id = ? LIMIT 1', { invoiceId })
    if not invoice then return false, 'Facture introuvable.' end
    if invoice.target_identifier ~= citizenid then return false, 'Facture non assignée.' end
    if invoice.status ~= 'pending' then return false, 'Facture déjà traitée.' end

    paymentMethod = paymentMethod == 'bank' and 'bank' or 'cash'
    local amount = math.floor(tonumber(invoice.amount) or 0)
    if amount < 1 then return false, 'Montant invalide.' end
    if not Rest.RemoveMoney(source, paymentMethod, amount, 'qbox_restaurants:invoice') then
        return false, 'Fonds insuffisants.'
    end

    local issuerSource
    for src, player in pairs(Rest.GetOnlinePlayers()) do
        if player.PlayerData and player.PlayerData.citizenid == invoice.issuer_identifier then
            issuerSource = src
            break
        end
    end

    local grade = 1
    if issuerSource then
        local _, g = Rest.GetJob(issuerSource)
        grade = g
    else
        local emp = MySQL.single.await(
            'SELECT grade FROM qbox_restaurants_employees WHERE restaurant = ? AND identifier = ? LIMIT 1',
            { invoice.restaurant, invoice.issuer_identifier }
        )
        grade = emp and tonumber(emp.grade) or 1
    end

    local rate = Rest.GetCommissionRate(grade)
    local commission = math.floor(amount * rate)
    local society = amount - commission

    if issuerSource and commission > 0 then
        Rest.AddMoney(issuerSource, 'bank', commission, 'qbox_restaurants:invoice_commission')
    end
    Rest.AddSociety(Rest.SocietyAccount(invoice.restaurant), society, 'invoice')

    local saleId = MySQL.insert.await([[
        INSERT INTO qbox_restaurants_sales
            (restaurant, employee_identifier, employee_name, customer_identifier, customer_name,
             amount, commission, commission_rate, payment_method, discount)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
    ]], {
        invoice.restaurant, invoice.issuer_identifier, invoice.issuer_name,
        invoice.target_identifier, invoice.target_name,
        amount, commission, rate, paymentMethod == 'bank' and 'card' or 'cash',
    })

    if saleId then
        MySQL.insert.await([[
            INSERT INTO qbox_restaurants_sale_items
                (sale_id, product_id, product_label, quantity, unit_price, total_price)
            VALUES (?, 'invoice', ?, 1, ?, ?)
        ]], { saleId, invoice.reason, amount, amount })
    end

    MySQL.update.await([[
        UPDATE qbox_restaurants_invoices SET status = 'paid', paid_at = CURRENT_TIMESTAMP, sale_id = ?
        WHERE id = ? AND status = 'pending'
    ]], { saleId, invoiceId })

    MySQL.update.await([[
        UPDATE qbox_restaurants_employees
        SET total_sales = total_sales + ?, total_commission = total_commission + ?
        WHERE restaurant = ? AND identifier = ?
    ]], { amount, commission, invoice.restaurant, invoice.issuer_identifier })

    local payer = Rest.GetName(source)
    if issuerSource then
        Rest.Notify(issuerSource, 'TPE — Paiement reçu',
            ('%s a payé %s (%s) par carte.'):format(payer, Rest.FormatMoney(amount), invoice.reason), 'success')
    end
    Rest.Notify(source, 'Factures', ('Facture #%s payée.'):format(invoiceId), 'success')
    return true, 'OK'
end

function Rest.CancelInvoice(source, invoiceId)
    invoiceId = tonumber(invoiceId)
    if not invoiceId then return false, 'Facture invalide.' end
    local citizenid = Rest.GetCitizenId(source)
    local invoice = MySQL.single.await('SELECT * FROM qbox_restaurants_invoices WHERE id = ? LIMIT 1', { invoiceId })
    if not invoice or invoice.status ~= 'pending' then return false, 'Facture introuvable.' end

    local allowed = invoice.issuer_identifier == citizenid or invoice.target_identifier == citizenid
    if not allowed then
        local ok = Rest.Authorize(source, 'finances', false)
        if not ok then return false, 'Permission refusée.' end
    end

    MySQL.update.await(
        'UPDATE qbox_restaurants_invoices SET status = ? WHERE id = ? AND status = ?',
        { 'cancelled', invoiceId, 'pending' }
    )
    return true, 'Annulée'
end

function Rest.GetInvoices(restaurantKey, citizenid)
    if citizenid then
        return MySQL.query.await([[
            SELECT * FROM qbox_restaurants_invoices
            WHERE restaurant = ? AND (issuer_identifier = ? OR target_identifier = ?)
            ORDER BY created_at DESC LIMIT 50
        ]], { restaurantKey, citizenid, citizenid }) or {}
    end
    return MySQL.query.await(
        'SELECT * FROM qbox_restaurants_invoices WHERE restaurant = ? ORDER BY created_at DESC LIMIT 50',
        { restaurantKey }
    ) or {}
end
