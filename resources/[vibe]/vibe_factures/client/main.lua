RegisterCommand(Config.Command, function()
    local input = lib.inputDialog('Nouvelle facture', {
        { type = 'number', label = 'ID serveur du destinataire', required = true, min = 1 },
        { type = 'number', label = 'Montant', required = true, min = 1, max = Config.MaxAmount },
        { type = 'input', label = 'Motif', required = true },
    })
    if not input then return end
    TriggerServerEvent('vibe_factures:server:create', tonumber(input[1]), tonumber(input[2]), input[3])
end, false)

RegisterNetEvent('vibe_factures:client:notifyNew', function(amount, reason, fromName)
    lib.notify({
        title = 'Nouvelle facture',
        description = ('%s — $%s\n%s'):format(fromName or 'Inconnu', amount, reason),
        type = 'inform',
        duration = 8000,
    })
end)
