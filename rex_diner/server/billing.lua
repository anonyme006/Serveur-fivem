function Rex.CreateInvoice(source, targetId, amount, reason)
    if not Config.EnableBilling then return false, 'Facturation désactivée.' end
    if not Rex.Cooldown(source, 'invoice') then return false, 'Patientez.' end
    local ok, err, ctx = Rex.Authorize(source, 'billing')
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

    local targetCid = Rex.GetCitizenId(targetId)
    local targetName = Rex.GetName(targetId)
    if not targetCid then return false, 'Client introuvable.' end

    local invoiceId = MySQL.insert.await([[
        INSERT INTO rex_diner_invoices
            (restaurant, issuer_identifier, issuer_name, target_identifier, target_name, amount, reason, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, 'pending')
    ]], { ctx.key, ctx.citizenid, ctx.name, targetCid, targetName, amount, reason })

    if not invoiceId then return false, 'Erreur SQL.' end

    Rex.Notify(source, 'Factures',
        ('Facture de %s envoyée à %s — TPE affiché.'):format(Rex.FormatMoney(amount), targetName), 'success')

    TriggerClientEvent('rex_diner:client:invoicePrompt', targetId, {
        id = invoiceId,
        amount = amount,
        reason = reason,
        issuer = ctx.name,
        restaurant = ctx.restaurant.label,
    })
    return true, invoiceId
end

function Rex.PayInvoice(source, invoiceId, paymentMethod)
    invoiceId = tonumber(invoiceId)
    if not invoiceId then return false, 'Facture invalide.' end
    local citizenid = Rex.GetCitizenId(source)
    if not citizenid then return false, 'Joueur invalide.' end

    local invoice = MySQL.single.await('SELECT * FROM rex_diner_invoices WHERE id = ? LIMIT 1', { invoiceId })
    if not invoice then return false, 'Facture introuvable.' end
    if invoice.target_identifier ~= citizenid then return false, 'Facture non assignée.' end
    if invoice.status ~= 'pending' then return false, 'Facture déjà traitée.' end

    paymentMethod = paymentMethod == 'bank' and 'bank' or 'cash'
    local amount = math.floor(tonumber(invoice.amount) or 0)
    if amount < 1 then return false, 'Montant invalide.' end
    if not Rex.RemoveMoney(source, paymentMethod, amount, 'rex_diner:invoice') then
        return false, 'Fonds insuffisants.'
    end

    local issuerSource
    for src, player in pairs(Rex.GetOnlinePlayers()) do
        if player.PlayerData and player.PlayerData.citizenid == invoice.issuer_identifier then
            issuerSource = src
            break
        end
    end

    local grade = 1
    if issuerSource then
        local _, g = Rex.GetJob(issuerSource)
        grade = g
    else
        local emp = MySQL.single.await(
            'SELECT grade FROM rex_diner_employees WHERE restaurant = ? AND identifier = ? LIMIT 1',
            { invoice.restaurant, invoice.issuer_identifier }
        )
        grade = emp and tonumber(emp.grade) or 1
    end

    local rate = Rex.GetCommissionRate(grade)
    local commission = math.floor(amount * rate)
    local society = amount - commission

    if issuerSource and commission > 0 then
        Rex.AddMoney(issuerSource, 'bank', commission, 'rex_diner:invoice_commission')
    end
    Rex.AddSociety(Rex.SocietyAccount(invoice.restaurant), society, 'invoice')

    local saleId = MySQL.insert.await([[
        INSERT INTO rex_diner_sales
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
            INSERT INTO rex_diner_sale_items
                (sale_id, product_id, product_label, quantity, unit_price, total_price)
            VALUES (?, 'invoice', ?, 1, ?, ?)
        ]], { saleId, invoice.reason, amount, amount })
    end

    MySQL.update.await([[
        UPDATE rex_diner_invoices SET status = 'paid', paid_at = CURRENT_TIMESTAMP, sale_id = ?
        WHERE id = ? AND status = 'pending'
    ]], { saleId, invoiceId })

    MySQL.update.await([[
        UPDATE rex_diner_employees
        SET total_sales = total_sales + ?, total_commission = total_commission + ?
        WHERE restaurant = ? AND identifier = ?
    ]], { amount, commission, invoice.restaurant, invoice.issuer_identifier })

    local payer = Rex.GetName(source)
    if issuerSource then
        Rex.Notify(issuerSource, 'TPE — Paiement reçu',
            ('%s a payé %s (%s) par carte.'):format(payer, Rex.FormatMoney(amount), invoice.reason), 'success')
    end
    Rex.Notify(source, 'Factures', ('Facture #%s payée.'):format(invoiceId), 'success')
    return true, 'OK'
end

function Rex.CancelInvoice(source, invoiceId)
    invoiceId = tonumber(invoiceId)
    if not invoiceId then return false, 'Facture invalide.' end
    local citizenid = Rex.GetCitizenId(source)
    local invoice = MySQL.single.await('SELECT * FROM rex_diner_invoices WHERE id = ? LIMIT 1', { invoiceId })
    if not invoice or invoice.status ~= 'pending' then return false, 'Facture introuvable.' end

    local allowed = invoice.issuer_identifier == citizenid or invoice.target_identifier == citizenid
    if not allowed then
        local ok = Rex.Authorize(source, 'finances', false)
        if not ok then return false, 'Permission refusée.' end
    end

    MySQL.update.await(
        'UPDATE rex_diner_invoices SET status = ? WHERE id = ? AND status = ?',
        { 'cancelled', invoiceId, 'pending' }
    )
    return true, 'Annulée'
end

function Rex.GetInvoices(restaurantKey, citizenid)
    if citizenid then
        return MySQL.query.await([[
            SELECT * FROM rex_diner_invoices
            WHERE restaurant = ? AND (issuer_identifier = ? OR target_identifier = ?)
            ORDER BY created_at DESC LIMIT 50
        ]], { restaurantKey, citizenid, citizenid }) or {}
    end
    return MySQL.query.await(
        'SELECT * FROM rex_diner_invoices WHERE restaurant = ? ORDER BY created_at DESC LIMIT 50',
        { restaurantKey }
    ) or {}
end
