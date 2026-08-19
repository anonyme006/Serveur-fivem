RegisterNetEvent('rex_diner:client:invoicePrompt', function(invoice)
    if not invoice or not invoice.id then return end

    local choice = lib.alertDialog({
        header = ('Facture — %s'):format(invoice.restaurant or 'Restaurant'),
        content = ('**%s** vous facture **%s%s**\n\n%s'):format(
            invoice.issuer or 'Employé',
            invoice.amount or 0,
            Config.Currency or '$',
            invoice.reason or ''
        ),
        centered = true,
        cancel = true,
        labels = { confirm = 'Payer', cancel = 'Refuser' },
    })

    if choice ~= 'confirm' then
        lib.callback.await('rex_diner:cancelInvoice', false, invoice.id)
        Rex.Notify('Factures', 'Facture refusée.', 'inform')
        return
    end

    local method = lib.inputDialog('Paiement facture', {
        {
            type = 'select',
            label = 'Méthode',
            options = {
                { value = 'bank', label = 'Banque / Carte' },
                { value = 'cash', label = 'Espèces' },
            },
            required = true,
            default = 'bank',
        },
    })
    if not method then
        lib.callback.await('rex_diner:cancelInvoice', false, invoice.id)
        return
    end

    local result = lib.callback.await('rex_diner:payInvoice', false, {
        invoiceId = invoice.id,
        paymentMethod = method[1],
    })
    if not result or not result.ok then
        Rex.Notify('Factures', result and result.message or 'Échec.', 'error')
    end
end)

function Rex.OpenBillingDialog()
    if not Config.EnableBilling then return end
    local players = lib.callback.await('rex_diner:getNearbyPlayers', false) or {}
    if #players == 0 then
        Rex.Notify('Factures', 'Aucun joueur proche.', 'error')
        return
    end
    local opts = {}
    for i = 1, #players do
        opts[#opts + 1] = { value = players[i].id, label = ('ID %s — %s'):format(players[i].id, players[i].name) }
    end
    local input = lib.inputDialog('Créer une facture', {
        { type = 'select', label = 'Client', options = opts, required = true },
        { type = 'number', label = 'Montant', required = true, min = 1 },
        { type = 'input', label = 'Raison', required = true },
    })
    if not input then return end
    local result = lib.callback.await('rex_diner:createInvoice', false, {
        targetId = input[1], amount = input[2], reason = input[3],
    })
    if not result or not result.ok then
        Rex.Notify('Factures', result and result.error or 'Échec.', 'error')
    end
end
