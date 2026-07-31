RegisterNetEvent('vibe_factures:server:create', function(targetId, amount, reason)
    local src = source
    local from = exports.vibe_api:GetPlayer(src)
    local to = exports.vibe_api:GetPlayer(targetId)
    if not from or not to then
        exports.vibe_api:Notify(src, 'Facture', 'Joueur introuvable.', 'error')
        return
    end
    amount = math.floor(tonumber(amount) or 0)
    if amount < 1 or amount > Config.MaxAmount then return end
    reason = tostring(reason or ''):sub(1, 255)

    MySQL.insert.await(
        'INSERT INTO vibe_invoices (from_citizenid, to_citizenid, amount, reason) VALUES (?, ?, ?, ?)',
        { from.PlayerData.citizenid, to.PlayerData.citizenid, amount, reason }
    )

    TriggerClientEvent('vibe_factures:client:notifyNew', targetId, amount, reason, exports.vibe_api:GetCharName(src))
    exports.vibe_api:Notify(src, 'Facture', 'Facture envoyee.', 'success')
end)

lib.callback.register('vibe_factures:server:list', function(source)
    local cid = exports.vibe_api:GetCitizenId(source)
    return MySQL.query.await('SELECT id, amount, reason FROM vibe_invoices WHERE to_citizenid = ? AND paid = 0 ORDER BY id DESC LIMIT 25', { cid }) or {}
end)

RegisterNetEvent('vibe_factures:server:pay', function(id)
    local src = source
    local cid = exports.vibe_api:GetCitizenId(src)
    local row = MySQL.single.await('SELECT * FROM vibe_invoices WHERE id = ? AND to_citizenid = ? AND paid = 0', { id, cid })
    if not row then return end
    if not exports.vibe_api:RemoveMoney(src, 'bank', row.amount, 'facture') and not exports.vibe_api:RemoveMoney(src, 'cash', row.amount, 'facture') then
        exports.vibe_api:Notify(src, 'Facture', 'Fonds insuffisants.', 'error')
        return
    end
    MySQL.update.await('UPDATE vibe_invoices SET paid = 1 WHERE id = ?', { id })
    -- payer le createur s il est en ligne
    for _, pid in pairs(GetPlayers()) do
        pid = tonumber(pid)
        if exports.vibe_api:GetCitizenId(pid) == row.from_citizenid then
            exports.vibe_api:AddMoney(pid, 'bank', row.amount, 'facture-paid')
            exports.vibe_api:Notify(pid, 'Facture', ('Facture #%s payee.'):format(id), 'success')
            break
        end
    end
    exports.vibe_api:Notify(src, 'Facture', 'Facture payee.', 'success')
end)
