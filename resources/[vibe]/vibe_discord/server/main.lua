print(('[vibe_discord] Démarré — framework=%s whitelist=%s'):format(
    Framework,
    Config.WhitelistEnabled and 'on' or 'off'
))

-- Commande IG pour tester le push Discord
RegisterCommand('discordtest', function(src)
    if src ~= 0 then
        if not IsPlayerAceAllowed(src, 'command.discordtest') then
            return
        end
    end
    PushDiscordLog('staff', {
        Action = 'test',
        Message = 'Ping depuis FiveM → Discord OK',
        Staff = src == 0 and 'console' or GetPlayerName(src),
    }, 0x57F287)
    if src == 0 then
        print('[vibe_discord] Log test envoyé')
    else
        TriggerClientEvent('chat:addMessage', src, { args = { 'Discord', 'Log test envoyé' } })
    end
end, true)

-- Export report joueur → Discord
RegisterNetEvent('vibe_discord:server:report', function(targetId, message)
    local src = source
    local reporter = BuildPlayerPayload(src)
    local target = FindPlayerById(targetId)
    exports[GetCurrentResourceName()]:LogReport({
        Reporter = reporter and ('[%s] %s'):format(reporter.id, reporter.name) or tostring(src),
        Cible = target and ('[%s] %s'):format(target.id, target.name) or tostring(targetId or '?'),
        Message = tostring(message or ''):sub(1, 900),
    })
end)
