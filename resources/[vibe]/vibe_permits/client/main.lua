RegisterCommand(Config.Command, function()
    local meta = lib.callback.await('vibe_permits:server:mine', false)
    local lines = {}
    if meta and meta.permits then
        for k, v in pairs(meta.permits) do
            if v then lines[#lines+1] = ('• %s'):format(k) end
        end
    end
    lib.alertDialog({
        header = 'Mes permis',
        content = #lines > 0 and table.concat(lines, '\n') or 'Aucun permis enregistré.',
        centered = true,
    })
end, false)

RegisterCommand('montrerpermis', function()
    TriggerServerEvent('vibe_permits:server:showClosest')
end, false)

RegisterNetEvent('vibe_permits:client:show', function(name, permits)
    local lines = {}
    for k, v in pairs(permits or {}) do
        if v then lines[#lines+1] = ('• %s'):format(k) end
    end
    lib.alertDialog({
        header = ('Permis de %s'):format(name),
        content = #lines > 0 and table.concat(lines, '\n') or 'Aucun',
        centered = true,
    })
end)
