--- Événements joueur relayés depuis Qbox pour les ressources rp_*

local function onPlayerLoaded(player)
    local src = player.PlayerData.source
    local pd = player.PlayerData
    TriggerEvent('rp_core:server:playerLoaded', src, {
        citizenid = pd.citizenid,
        license = pd.license,
        name = (pd.charinfo and (pd.charinfo.firstname .. ' ' .. pd.charinfo.lastname)) or GetPlayerName(src),
        job = pd.job,
        gang = pd.gang,
        money = pd.money,
        metadata = pd.metadata,
        charinfo = pd.charinfo,
    })
    if GetResourceState('rp_logs') == 'started' then
        exports.rp_logs:Log('connection', src, 'Connexion personnage', {
            citizenid = pd.citizenid,
        })
    end
end

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    onPlayerLoaded(player)
end)

AddEventHandler('QBCore:Server:OnPlayerUnload', function(src)
    TriggerEvent('rp_core:server:playerUnloaded', src)
    if GetResourceState('rp_logs') == 'started' then
        exports.rp_logs:Log('disconnection', src, 'Déconnexion', {})
    end
end)

AddEventHandler('QBCore:Server:OnJobUpdate', function(src, job)
    TriggerEvent('rp_core:server:jobUpdate', src, job)
end)

AddEventHandler('QBCore:Server:OnMoneyChange', function(src, moneyType, amount, action, reason)
    TriggerEvent('rp_core:server:moneyUpdate', src, moneyType, amount, action, reason)
    if GetResourceState('rp_logs') == 'started' then
        exports.rp_logs:Log('money', src, ('%s %s %s'):format(action, amount, moneyType), {
            reason = reason,
        })
    end
end)

--- Callback identité
lib.callback.register('rp_core:getIdentity', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return nil end
    local c = player.PlayerData.charinfo or {}
    return {
        firstname = c.firstname,
        lastname = c.lastname,
        birthdate = c.birthdate,
        gender = c.gender,
        nationality = c.nationality,
        phone = c.phone,
        citizenid = player.PlayerData.citizenid,
        job = player.PlayerData.job,
        gang = player.PlayerData.gang,
        money = player.PlayerData.money,
    }
end)

print('[rp_core] server ready')
