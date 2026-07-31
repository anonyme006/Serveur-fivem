RegisterCommand('panel', function()
    local allowed = lib.callback.await('vibe_panelv2:server:allowed', false)
    if not allowed then
        exports.vibe_api:Notify('Panel', 'Admin uniquement.', 'error')
        return
    end
    lib.registerContext({
        id = 'vibe_panel',
        title = 'Panel Admin Vibe',
        options = {
            {
                title = 'Revive self',
                onSelect = function()
                    TriggerEvent('vibe_medicextract:client:revive')
                end,
            },
            {
                title = 'Heal self',
                onSelect = function()
                    TriggerEvent('vibe_medicextract:client:heal')
                end,
            },
            {
                title = 'TPM',
                onSelect = function()
                    TriggerServerEvent('vibe_teleport:server:tpm')
                end,
            },
            {
                title = 'Give cash',
                onSelect = function()
                    local input = lib.inputDialog('Cash', {
                        { type = 'number', label = 'Montant', required = true, min = 1 },
                    })
                    if input then TriggerServerEvent('vibe_panelv2:server:giveCash', tonumber(input[1])) end
                end,
            },
            {
                title = 'Annonce serveur',
                onSelect = function()
                    local input = lib.inputDialog('Annonce', {
                        { type = 'input', label = 'Message', required = true },
                    })
                    if input then TriggerServerEvent('vibe_panelv2:server:announce', input[1]) end
                end,
            },
        },
    })
    lib.showContext('vibe_panel')
end, false)
