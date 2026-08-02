RegisterCommand('amende', function()
    if not exports.rr_api:IsPolice(true) then
        exports.rr_api:Notify('Amende', 'Réservé aux FDO en service.', 'error')
        return
    end
    local input = lib.inputDialog('Amende', {
        { type = 'number', label = 'ID joueur', required = true, min = 1 },
        { type = 'number', label = 'Montant', required = true, min = 1, max = Config.MaxFine },
        { type = 'input', label = 'Motif', required = true },
    })
    if not input then return end
    TriggerServerEvent('rr_amende:server:fine', tonumber(input[1]), tonumber(input[2]), input[3])
end, false)

exports('OpenFineMenu', function(targetId)
    local input = lib.inputDialog('Amende', {
        { type = 'number', label = 'Montant', required = true, min = 1, max = Config.MaxFine },
        { type = 'input', label = 'Motif', required = true },
    })
    if not input then return end
    TriggerServerEvent('rr_amende:server:fine', targetId, tonumber(input[1]), input[2])
end)
