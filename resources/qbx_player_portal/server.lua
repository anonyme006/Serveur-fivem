local activePlaySessions = {} -- source -> sessionToken

local function notify(source, message, nType)
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Portail',
        description = message,
        type = nType or 'inform',
    })
end

local function generateCode(length)
    local digits = {}
    for i = 1, length do
        digits[i] = tostring(math.random(0, 9))
    end
    return table.concat(digits)
end

local function hashCode(code)
    return exports.qbx_player_portal:sha256Hex(code)
end

local function startPlaytime(source)
    local player = PortalQbx.getPlayer(source)
    local citizenid = PortalQbx.getCitizenId(player)
    local license = PortalQbx.getLicense(source, player)
    if not citizenid or not license then return end

    local token = exports.qbx_player_portal:randomToken(32)
    activePlaySessions[source] = token
    PortalDB.openPlaytimeSession(citizenid, license, token)
    PortalDB.addActivity(citizenid, 'session', 'Connexion serveur', { source = source })
    PortalSync.pushPlayerState(source, 'player_loaded')
end

local function stopPlaytime(source)
    local token = activePlaySessions[source]
    if token then
        PortalDB.closePlaytimeSession(token)
        activePlaySessions[source] = nil
    end
    PortalSync.pushPlayerState(source, 'player_dropped')
end

RegisterCommand(Config.LinkCommand, function(source, args)
    if source == 0 then return end

    if Config.ApiSecret == '' then
        notify(source, Config.Locale.configMissing, 'error')
        return
    end

    local sub = args[1] and string.lower(args[1]) or 'link'
    if sub ~= 'link' and sub ~= 'code' then
        notify(source, ('Usage: /%s link'):format(Config.LinkCommand), 'inform')
        return
    end

    local player = PortalQbx.getPlayer(source)
    local citizenid = PortalQbx.getCitizenId(player)
    local license = PortalQbx.getLicense(source, player)
    if not citizenid or not license then
        notify(source, Config.Locale.noPlayer, 'error')
        return
    end

    local code = generateCode(Config.LinkCodeLength)
    local expires = os.time() + Config.LinkCodeTtl
    local ok, err = pcall(function()
        PortalDB.createLinkCode(
            hashCode(code),
            citizenid,
            license,
            PortalQbx.getDiscordId(source),
            expires
        )
    end)

    if not ok then
        print(('[qbx_player_portal] link code error: %s'):format(err))
        notify(source, Config.Locale.syncFail, 'error')
        return
    end

    notify(source, Config.Locale.codeCreated:format(code, Config.LinkCodeTtl), 'success')
    notify(source, Config.Locale.alreadyLinkedHint, 'inform')
    TriggerClientEvent('qbx_player_portal:client:showCode', source, code, Config.LinkCodeTtl)
end, false)

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    local src = player and player.PlayerData and player.PlayerData.source
    if src then startPlaytime(src) end
end)

AddEventHandler('qbx_core:server:playerLoaded', function(player)
    local src = player and player.PlayerData and player.PlayerData.source
    if src then startPlaytime(src) end
end)

-- Fallback si l'event Qbox diffère selon version
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    startPlaytime(source)
end)

AddEventHandler('playerDropped', function()
    stopPlaytime(source)
end)

CreateThread(function()
    while true do
        Wait(Config.PlaytimeHeartbeat * 1000)
        for src, token in pairs(activePlaySessions) do
            if GetPlayerPing(src) <= 0 then
                stopPlaytime(src)
            else
                local alive = PortalDB.heartbeatPlaytime(token)
                if not alive then
                    startPlaytime(src)
                end
            end
        end
    end
end)

-- Export lecture seule pour autres ressources serveur
exports('GetPortalCitizenId', function(source)
    return PortalQbx.getCitizenId(PortalQbx.getPlayer(source))
end)

print('[qbx_player_portal] server started')
