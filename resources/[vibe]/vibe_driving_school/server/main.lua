lib.callback.register('vibe_driving_school:server:pay', function(source)
    if not exports.vibe_api:DistCheck(source, Config.School, 5.0) then return false end
    if not exports.vibe_api:RemoveMoney(source, 'bank', Config.Price, 'driving-school')
        and not exports.vibe_api:RemoveMoney(source, 'cash', Config.Price, 'driving-school') then
        exports.vibe_api:Notify(source, 'Auto-école', 'Pas assez d\'argent.', 'error')
        return false
    end
    return true
end)

RegisterNetEvent('vibe_driving_school:server:result', function(score)
    local src = source
    score = tonumber(score) or 0
    if score >= Config.PassScore then
        exports.ox_inventory:AddItem(src, Config.LicenseItem, 1)
        local cid = exports.vibe_api:GetCitizenId(src)
        local meta = exports.vibe_api:LoadPlayerMeta(cid)
        meta.permits = meta.permits or {}
        meta.permits.driver = true
        MySQL.insert.await([[
            INSERT INTO vibe_player_meta (citizenid, permits)
            VALUES (?, ?)
            ON DUPLICATE KEY UPDATE permits = VALUES(permits)
        ]], { cid, json.encode(meta.permits) })
        exports.vibe_api:Notify(src, 'Auto-école', ('Réussi (%s/%s) — permis obtenu.'):format(score, #Config.Questions), 'success')
    else
        exports.vibe_api:Notify(src, 'Auto-école', ('Ajourné (%s/%s).'):format(score, #Config.Questions), 'error')
    end
end)
