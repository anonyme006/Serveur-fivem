lib.callback.register('rp_menu:getOverview', function(source)
    local player = exports.rp_core:GetPlayer(source)
    if not player then return nil end
    local pd = player.PlayerData
    local c = pd.charinfo or {}
    return {
        name = ('%s %s'):format(c.firstname or '?', c.lastname or '?'),
        birthdate = c.birthdate,
        nationality = c.nationality,
        gender = c.gender,
        phone = c.phone,
        citizenid = pd.citizenid,
        job = pd.job,
        gang = pd.gang,
        cash = pd.money and pd.money.cash or 0,
        bank = pd.money and pd.money.bank or 0,
    }
end)

RegisterNetEvent('rp_menu:server:logout', function()
    local src = source
    if not exports.rp_core:RateLimit(src, 'logout', 5000) then return end
    -- Utilise le logout multichar Qbox si disponible
    if exports.qbx_core.Logout then
        exports.qbx_core:Logout(src)
    else
        DropPlayer(src, 'Déconnexion personnage')
    end
end)
