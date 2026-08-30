local function httpPost(url, payload, cb)
    PerformHttpRequest(url, function(code, body)
        if cb then cb(code, body) end
    end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json',
        ['X-Bridge-Secret'] = Config.BridgeSecret,
    })
end

function PushDiscordLog(typeName, fields, color)
    if not Config.BotLogUrl or Config.BotLogUrl == '' then return end
    local url = Config.BotLogUrl:gsub('/$', '') .. '/log'
    httpPost(url, {
        type = typeName,
        fields = fields,
        color = color,
    })
end

function PushStaffLog(action, player, body)
    if not Config.Logs.staff then return end
    PushDiscordLog('staff', {
        Action = action,
        Joueur = ('[%s] %s'):format(player.id or '?', player.name or '?'),
        License = player.license or 'n/a',
        Staff = body.staff or '?',
        Raison = body.reason or body.message or body.item or body.job or '—',
        Détails = body.hours and (body.hours .. 'h') or (body.count and ('x' .. body.count)) or '',
    }, 0xFEE75C)
end

AddEventHandler('playerJoining', function()
    if not Config.Logs.connect then return end
    local src = source
    SetTimeout(1500, function()
        local p = BuildPlayerPayload(src)
        if not p then return end
        PushDiscordLog('connect', {
            Joueur = ('[%s] %s'):format(p.id, p.name),
            Personnage = p.character,
            License = p.license or 'n/a',
            Discord = p.discord and ('<@' .. p.discord .. '>') or 'n/a',
            Job = p.job,
        }, 0x57F287)
    end)
end)

AddEventHandler('playerDropped', function(reason)
    if not Config.Logs.disconnect then return end
    local src = source
    local p = BuildPlayerPayload(src) or {
        id = src,
        name = GetPlayerName(src) or '?',
        license = GetPlayerLicense(src),
        discord = GetPlayerDiscord(src),
    }
    PushDiscordLog('disconnect', {
        Joueur = ('[%s] %s'):format(p.id, p.name),
        License = p.license or 'n/a',
        Discord = p.discord and ('<@' .. p.discord .. '>') or 'n/a',
        Raison = reason or 'quit',
    }, 0xED4245)
end)

-- Chat (ressource chat CFX)
AddEventHandler('chatMessage', function(src, name, msg)
    if not Config.Logs.chat then return end
    if type(msg) ~= 'string' or msg == '' then return end
    if msg:sub(1, 1) == '/' then return end
    local p = BuildPlayerPayload(src)
    PushDiscordLog('chat', {
        Joueur = p and ('[%s] %s'):format(p.id, p.name) or name,
        Message = msg,
    }, 0x5865F2)
end)

-- Morts (baseevents)
RegisterNetEvent('baseevents:onPlayerDied', function(killerType, deathCoords)
    if not Config.Logs.death then return end
    local src = source
    local p = BuildPlayerPayload(src)
    PushDiscordLog('death', {
        Victime = p and ('[%s] %s'):format(p.id, p.name) or tostring(src),
        Cause = 'mort (environnement / suicide)',
        Coords = deathCoords and json.encode(deathCoords) or 'n/a',
    }, 0x992D22)
end)

RegisterNetEvent('baseevents:onPlayerKilled', function(killerId, data)
    if not Config.Logs.death then return end
    local src = source
    local victim = BuildPlayerPayload(src)
    local killer = killerId and BuildPlayerPayload(killerId)
    PushDiscordLog('death', {
        Victime = victim and ('[%s] %s'):format(victim.id, victim.name) or tostring(src),
        Tueur = killer and ('[%s] %s'):format(killer.id, killer.name) or tostring(killerId or '?'),
        Arme = data and tostring(data.weaponhash or data.killertype or '?') or '?',
    }, 0x992D22)
end)

-- Export pour autres scripts
exports('PushDiscordLog', PushDiscordLog)
exports('LogEconomy', function(fields)
    PushDiscordLog('economy', fields or {}, 0xF1C40F)
end)
exports('LogReport', function(fields)
    PushDiscordLog('report', fields or {}, 0xE67E22)
end)
