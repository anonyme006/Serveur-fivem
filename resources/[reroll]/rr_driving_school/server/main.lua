lib.callback.register('rr_driving_school:server:pay', function(source)
    if not exports.rr_api:DistCheck(source, Config.School, 5.0) then return false end
    if not exports.rr_api:RemoveMoney(source, 'bank', Config.Price, 'driving-school')
        and not exports.rr_api:RemoveMoney(source, 'cash', Config.Price, 'driving-school') then
        exports.rr_api:Notify(source, 'Auto-école', 'Pas assez d\'argent.', 'error')
        return false
    end
    return true
end)

RegisterNetEvent('rr_driving_school:server:result', function(score)
    local src = source
    score = tonumber(score) or 0
    if score >= Config.PassScore then
        exports.ox_inventory:AddItem(src, Config.LicenseItem, 1)
        local cid = exports.rr_api:GetCitizenId(src)
        local meta = exports.rr_api:LoadPlayerMeta(cid)
        meta.permits = meta.permits or {}
        meta.permits.driver = true
        MySQL.insert.await([[
            INSERT INTO rr_player_meta (citizenid, permits)
            VALUES (?, ?)
            ON DUPLICATE KEY UPDATE permits = VALUES(permits)
        ]], { cid, json.encode(meta.permits) })
        exports.rr_api:Notify(src, 'Auto-école', ('Réussi (%s/%s) — permis obtenu.'):format(score, #Config.Questions), 'success')
    else
        exports.rr_api:Notify(src, 'Auto-école', ('Ajourné (%s/%s).'):format(score, #Config.Questions), 'error')
    end
end)
