RegisterCommand(Config.Command, function()
    local input = lib.inputDialog('Nouvelle facture', {
        { type = 'number', label = 'ID serveur du destinataire', required = true, min = 1 },
        { type = 'number', label = 'Montant', required = true, min = 1, max = Config.MaxAmount },
        { type = 'input', label = 'Motif', required = true },
    })
    if not input then return end
    TriggerServerEvent('vibe_factures:server:create', tonumber(input[1]), tonumber(input[2]), input[3])
end, false)

RegisterCommand('mesfactures', function()
    local list = lib.callback.await('vibe_factures:server:list', false)
    if not list or #list == 0 then
        exports.vibe_api:Notify('Factures', 'Aucune facture en attente.', 'inform')
        return
    end
    local options = {}
    for _, f in ipairs(list) do
        options[#options+1] = {
            title = ('#%s — $%s'):format(f.id, f.amount),
            description = f.reason,
            onSelect = function()
                TriggerServerEvent('vibe_factures:server:pay', f.id)
            end,
        }
    end
    lib.registerContext({ id = 'vibe_factures_list', title = 'Factures a payer', options = options })
    lib.showContext('vibe_factures_list')
end, false)

RegisterNetEvent('vibe_factures:client:notifyNew', function(amount, reason, fromName)
    lib.notify({
        title = 'Nouvelle facture',
        description = ('%s — $%s\n%s\n/mesfactures pour payer'):format(fromName or 'Inconnu', amount, reason),
        type = 'inform',
        duration = 9000,
    })
end)
