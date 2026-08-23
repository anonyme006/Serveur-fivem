RegisterNetEvent('rp_billing:client:newInvoice', function(data)
    if lib and lib.notify then
        lib.notify({
            title = 'Facture',
            description = ('#%s — %s$ : %s'):format(data.invoice_id, data.amount, data.reason),
            type = 'inform',
            duration = 8000,
        })
    end
end)

RegisterCommand('factures', function()
    local invoices = lib.callback.await('rp_billing:getMine', false)
    if not invoices or #invoices == 0 then
        lib.notify({ description = 'Aucune facture.', type = 'inform' })
        return
    end
    local options = {}
    for _, inv in ipairs(invoices) do
        options[#options + 1] = {
            title = ('#%s — %s$ [%s]'):format(inv.invoice_id, inv.amount, inv.status),
            description = inv.reason,
            disabled = inv.status ~= 'pending',
            onSelect = function()
                if inv.status ~= 'pending' then return end
                local choice = lib.alertDialog({
                    header = 'Facture ' .. inv.invoice_id,
                    content = ('Montant : %s$\n%s\nPayer ou refuser ?'):format(inv.amount, inv.reason),
                    centered = true,
                    cancel = true,
                    labels = { confirm = 'Payer', cancel = 'Refuser' },
                })
                if choice == 'confirm' then
                    TriggerServerEvent('rp_billing:server:pay', inv.invoice_id)
                elseif choice == 'cancel' then
                    TriggerServerEvent('rp_billing:server:refuse', inv.invoice_id)
                end
            end,
        }
    end
    lib.registerContext({ id = 'rp_billing_list', title = 'Mes factures', options = options })
    lib.showContext('rp_billing_list')
end, false)
