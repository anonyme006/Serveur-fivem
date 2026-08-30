if Config.Modules and Config.Modules.core == false then return end

--[[
    Hooks logs Discord — événements serveur + bridge qbx_ressources
]]

if not Config.Discord or not Config.Discord.enabled then return end

local function log(category, title, description, opts)
    if Core.Discord and Core.Discord.Log then
        Core.Discord.Log(category, title, description, opts)
    end
end

--- Boot
AddEventHandler('onResourceStart', function(res)
    if res == GetCurrentResourceName() then
        SetTimeout(2000, function()
            log('system', '🟢 Serveur / ressource démarrée', ('`%s` est en ligne.'):format(res), {
                color = 'success',
            })
        end)
        return
    end
    log('resources', '▶️ Resource start', ('`%s`'):format(res), { color = 'info' })
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        log('system', '🔴 qbx_ressources stoppé', nil, { color = 'error' })
        return
    end
    log('resources', '⏹️ Resource stop', ('`%s`'):format(res), { color = 'warning' })
end)

--- Connexions
AddEventHandler('playerConnecting', function(name, _setKick, _deferrals)
    local src = source
    log('connect', '🔌 Connexion en cours', ('**%s** tente de se connecter.'):format(name or '?'), {
        color = 'info',
        src = src,
    })
end)

AddEventHandler('playerJoining', function()
    local src = source
    SetTimeout(1500, function()
        if GetPlayerName(src) then
            log('connect', '✅ Joueur arrivé', nil, { color = 'success', src = src })
        end
    end)
end)

local function onCharacterLoaded(src, jobName)
    log('connect', '👤 Personnage chargé', ('Job : `%s`'):format(jobName or '?'), {
        color = 'success',
        src = src,
    })
end

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    local src = player and player.PlayerData and player.PlayerData.source
    local job = player and player.PlayerData and player.PlayerData.job and player.PlayerData.job.name
    if src then onCharacterLoaded(src, job) end
end)

AddEventHandler('qbx_core:server:playerLoggedIn', function(src)
    local player = Core.GetPlayer(src)
    local job = player and player.PlayerData and player.PlayerData.job and player.PlayerData.job.name
    onCharacterLoaded(src, job)
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    local name = GetPlayerName(src) or ('ID %s'):format(src)
    log('connect', '🚪 Déconnexion', ('**%s** a quitté.\nRaison : `%s`'):format(name, reason or 'inconnu'), {
        color = 'warning',
        src = src,
    })
end)

--- Chat
AddEventHandler('chatMessage', function(src, author, message)
    if not message or message == '' then return end
    if message:sub(1, 1) == '/' then return end
    log('chat', '💬 Chat', ('**%s** : %s'):format(author or GetPlayerName(src) or '?', message), {
        color = 'info',
        src = src,
    })
end)

--- Morts (baseevents)
RegisterNetEvent('baseevents:onPlayerDied', function(killerType, deathCoords)
    local src = source
    log('death', '💀 Mort (environnement)', ('Type : `%s`'):format(tostring(killerType)), {
        color = 'error',
        src = src,
        fields = deathCoords and {
            { name = 'Coords', value = ('`%.1f, %.1f, %.1f`'):format(deathCoords[1] or 0, deathCoords[2] or 0, deathCoords[3] or 0), inline = false },
        } or nil,
    })
end)

RegisterNetEvent('baseevents:onPlayerKilled', function(killerId, data)
    local src = source
    local killerName = tonumber(killerId) and GetPlayerName(killerId) or 'inconnu'
    local weapon = data and (data.weaponhash or data.killertype) or '?'
    log('death', '☠️ Kill', ('**%s** a tué **%s**\nArme/type : `%s`'):format(
        killerName,
        GetPlayerName(src) or src,
        tostring(weapon)
    ), {
        color = 'error',
        src = src,
        fields = {
            { name = 'Killer ID', value = tostring(killerId), inline = true },
        },
    })
end)

--- Explosions
AddEventHandler('explosionEvent', function(sender, ev)
    local expType = ev and ev.explosionType or '?'
    log('explosion', '💥 Explosion', ('Type : `%s`'):format(tostring(expType)), {
        color = 'warning',
        src = sender,
        fields = ev and {
            { name = 'Coords', value = ('`%.1f, %.1f, %.1f`'):format(ev.posX or 0, ev.posY or 0, ev.posZ or 0), inline = false },
        } or nil,
    })
end)

--- Events internes qbx_ressources (émis depuis les modules)
AddEventHandler('qbx_ressources:log', function(category, title, description, opts)
    log(category, title, description, opts)
end)
