RegisterNetEvent('vibe_factures:server:create', function(targetId, amount, reason)
    local src = source
    local from = exports.qbx_core:GetPlayer(src)
    local to = exports.qbx_core:GetPlayer(targetId)
    if not from or not to then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Facture', description = 'Joueur introuvable.', type = 'error' })
        return
    end
    amount = math.floor(tonumber(amount) or 0)
    if amount < 1 or amount > Config.MaxAmount then return end
    reason = tostring(reason or ''):sub(1, 255)

    MySQL.insert.await(
        'INSERT INTO vibe_invoices (from_citizenid, to_citizenid, amount, reason) VALUES (?, ?, ?, ?)',
        { from.PlayerData.citizenid, to.PlayerData.citizenid, amount, reason }
    )

    local name = from.PlayerData.charinfo and (from.PlayerData.charinfo.firstname .. ' ' .. from.PlayerData.charinfo.lastname) or 'Joueur'
    TriggerClientEvent('vibe_factures:client:notifyNew', targetId, amount, reason, name)
    TriggerClientEvent('ox_lib:notify', src, { title = 'Facture', description = 'Facture envoyée.', type = 'success' })
end)
