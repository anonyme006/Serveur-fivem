--- Sales helpers exposed for optional direct use (tablet NUI handles most flows)

function RexDiner.OpenNearbyPayment(cart, discount)
    local players = lib.callback.await('rex_diner:getNearbyPlayers', false) or {}
    if #players == 0 then
        RexDiner.Notify('Caisse', 'Aucun client à proximité.', 'error')
        return
    end

    local options = {}
    for i = 1, #players do
        local p = players[i]
        options[#options + 1] = {
            title = ('ID %s — %s'):format(p.id, p.name),
            description = ('Distance : %.1fm'):format(p.distance or 0),
            icon = 'user',
            onSelect = function()
                local method = lib.inputDialog('Paiement', {
                    {
                        type = 'select',
                        label = 'Méthode',
                        options = {
                            { value = 'cash', label = 'Espèces' },
                            { value = 'bank', label = 'Banque / Carte' },
                        },
                        required = true,
                        default = 'bank',
                    },
                })
                if not method then return end

                local result = lib.callback.await('rex_diner:processSale', false, {
                    targetId = p.id,
                    cart = cart,
                    paymentMethod = method[1],
                    discount = discount or 0,
                })

                if not result or not result.ok then
                    RexDiner.Notify('Caisse', result and result.error or 'Paiement refusé.', 'error')
                    return
                end
                RexDiner.Notify('Caisse', 'Vente enregistrée.', 'success')
            end,
        }
    end

    lib.registerContext({
        id = 'rex_diner_payment_targets',
        title = 'CLIENT',
        options = options,
    })
    lib.showContext('rex_diner_payment_targets')
end
