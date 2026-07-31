RegisterNetEvent('vibe_amende:server:fine', function(targetId, amount, reason)
    local src = source
    if not exports.vibe_api:HasPoliceJob(src, true) then return end
    local target = exports.vibe_api:GetPlayer(targetId)
    if not target then
        exports.vibe_api:Notify(src, 'Amende', 'Joueur introuvable.', 'error')
        return
    end
    amount = math.floor(tonumber(amount) or 0)
    if amount < 1 or amount > Config.MaxFine then return end
    reason = tostring(reason or ''):sub(1, 255)

    local paid = exports.vibe_api:RemoveMoney(targetId, 'bank', amount, 'amende')
    if not paid then
        paid = exports.vibe_api:RemoveMoney(targetId, 'cash', amount, 'amende')
    end
    if not paid then
        exports.vibe_api:Notify(src, 'Amende', 'Le joueur n\'a pas les fonds.', 'error')
        return
    end

    MySQL.insert.await(
        'INSERT INTO vibe_invoices (from_citizenid, to_citizenid, amount, reason, paid) VALUES (?, ?, ?, ?, 1)',
        { exports.vibe_api:GetCitizenId(src), exports.vibe_api:GetCitizenId(targetId), amount, ('AMENDE: %s'):format(reason) }
    )

    local officer = exports.vibe_api:GetCharName(src)
    exports.vibe_api:Notify(targetId, 'Amende', ('$%s — %s\nOfficier: %s'):format(amount, reason, officer), 'error')
    exports.vibe_api:Notify(src, 'Amende', 'Amende appliquée.', 'success')
    TriggerEvent('vibe_dispatch:server:log', 'amende', {
        officer = officer,
        target = exports.vibe_api:GetCharName(targetId),
        amount = amount,
        reason = reason,
    })
end)
