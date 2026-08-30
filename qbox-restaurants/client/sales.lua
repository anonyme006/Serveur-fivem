--- Paiement direct hors tablette (optionnel)
function Rest.OpenNearbyPayment(cart, discount)
    local players = lib.callback.await('qbox_restaurants:getNearbyPlayers', false) or {}
    if #players == 0 then
        Rest.Notify('Caisse', 'Aucun client à proximité.', 'error')
        return
    end

    local options = {}
    for i = 1, #players do
        local p = players[i]
        options[#options + 1] = {
            title = ('ID %s — %s'):format(p.id, p.name),
            description = ('%.1fm'):format(p.distance or 0),
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
                local result = lib.callback.await('qbox_restaurants:processSale', false, {
                    targetId = p.id,
                    cart = cart,
                    paymentMethod = method[1],
                    discount = discount or 0,
                })
                if not result or not result.ok then
                    Rest.Notify('Caisse', result and result.error or 'Refusé.', 'error')
                end
            end,
        }
    end

    lib.registerContext({ id = 'qbox_restaurants_pay', title = 'CLIENT', options = options })
    lib.showContext('qbox_restaurants_pay')
end
