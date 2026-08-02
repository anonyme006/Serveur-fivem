RegisterCommand('panel', function()
    local allowed = lib.callback.await('rr_panelv2:server:allowed', false)
    if not allowed then
        exports.rr_api:Notify('Panel', 'Admin uniquement.', 'error')
        return
    end
    lib.registerContext({
        id = 'rr_panel',
        title = 'Panel Admin Reroll',
        options = {
            {
                title = 'Revive self',
                onSelect = function()
                    TriggerEvent('rr_medicextract:client:revive')
                end,
            },
            {
                title = 'Heal self',
                onSelect = function()
                    TriggerEvent('rr_medicextract:client:heal')
                end,
            },
            {
                title = 'TPM',
                onSelect = function()
                    TriggerServerEvent('rr_teleport:server:tpm')
                end,
            },
            {
                title = 'Give cash',
                onSelect = function()
                    local input = lib.inputDialog('Cash', {
                        { type = 'number', label = 'Montant', required = true, min = 1 },
                    })
                    if input then TriggerServerEvent('rr_panelv2:server:giveCash', tonumber(input[1])) end
                end,
            },
            {
                title = 'Annonce serveur',
                onSelect = function()
                    local input = lib.inputDialog('Annonce', {
                        { type = 'input', label = 'Message', required = true },
                    })
                    if input then TriggerServerEvent('rr_panelv2:server:announce', input[1]) end
                end,
            },
        },
    })
    lib.showContext('rr_panel')
end, false)
