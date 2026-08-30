--[[
    Vérification Discord via Bot API
    - identifier discord:XXXX
    - membre de la guilde
    - rôle Citoyen (optionnel)
]]

local cache = {} -- [discordId] = { result = table, expires = os.time() }

local function getBotToken()
    local convar = GetConvar('discord_bot_token', '')
    if convar and convar ~= '' then
        return convar
    end
    return Config.Discord.BotToken or ''
end

local function getDiscordId(src)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:sub(1, 8) == 'discord:' then
            return id:sub(9)
        end
    end
    return nil
end

--- @param status 'ok'|'no_discord'|'not_member'|'no_role'|'error'|'disabled'
local function makeResult(status, extra)
    local r = {
        status = status,
        invite = Config.Discord.Invite,
        citizenRoleName = Config.Discord.CitizenRoleName or 'Citoyen',
        enabled = Config.Discord.Enabled == true,
    }
    if extra then
        for k, v in pairs(extra) do
            r[k] = v
        end
    end
    return r
end

local function httpGet(url, headers)
    local p = promise.new()
    PerformHttpRequest(url, function(code, body, _headers)
        p:resolve({ code = code or 0, body = body or '' })
    end, 'GET', '', headers or {})
    return Citizen.Await(p)
end

local function verifyDiscord(src)
    if not Config.Discord.Enabled then
        return makeResult('disabled')
    end

    if Config.Debug and Config.Debug.ForceSuccess then
        return makeResult('ok', { forced = true })
    end

    local discordId = getDiscordId(src)
    if not discordId then
        return makeResult('no_discord')
    end

    local now = os.time()
    local cached = cache[discordId]
    if cached and cached.expires > now then
        return cached.result
    end

    local token = getBotToken()
    local guildId = Config.Discord.GuildId
    if not token or token == '' or not guildId or guildId == '' or guildId == 'ID_DU_SERVEUR_DISCORD' then
        return makeResult('error', {
            message = 'Configuration Discord incomplète (BotToken / GuildId).',
        })
    end

    local url = ('https://discord.com/api/v10/guilds/%s/members/%s'):format(guildId, discordId)
    local res = httpGet(url, {
        ['Authorization'] = 'Bot ' .. token,
        ['Content-Type'] = 'application/json',
    })

    if res.code == 404 then
        local result = makeResult('not_member')
        cache[discordId] = { result = result, expires = now + (Config.Discord.CacheDuration or 300) }
        return result
    end

    if res.code ~= 200 then
        return makeResult('error', {
            message = ('API Discord HTTP %s'):format(tostring(res.code)),
            httpCode = res.code,
        })
    end

    local ok, member = pcall(json.decode, res.body)
    if not ok or type(member) ~= 'table' then
        return makeResult('error', { message = 'Réponse Discord invalide.' })
    end

    if Config.Discord.RequireCitizenRole then
        local roleId = tostring(Config.Discord.CitizenRoleId or '')
        local roles = member.roles or {}
        local hasRole = false
        for i = 1, #roles do
            if tostring(roles[i]) == roleId then
                hasRole = true
                break
            end
        end
        if not hasRole then
            local result = makeResult('no_role')
            cache[discordId] = { result = result, expires = now + (Config.Discord.CacheDuration or 300) }
            return result
        end
    end

    local result = makeResult('ok', {
        username = member.user and (member.user.global_name or member.user.username) or nil,
    })
    cache[discordId] = { result = result, expires = now + (Config.Discord.CacheDuration or 300) }
    return result
end

--- Récupère les personnages (qbx_core si présent, sinon liste vide)
local function getCharacters(src)
    local chars = {}

    if GetResourceState('qbx_core') == 'started' then
        local ok, result = pcall(function()
            -- API interne qbx : GetPlayer / characters selon version
            if exports.qbx_core.GetCharacters then
                return exports.qbx_core:GetCharacters(src)
            end
            return nil
        end)
        if ok and type(result) == 'table' then
            for i, char in ipairs(result) do
                local info = char.charinfo or char
                chars[#chars + 1] = {
                    id = char.citizenid or char.id or tostring(i),
                    firstname = info.firstname or 'Inconnu',
                    lastname = info.lastname or '',
                    cid = char.cid or i,
                    job = (char.job and char.job.label) or 'Sans emploi',
                    cash = (char.money and char.money.cash) or 0,
                    bank = (char.money and char.money.bank) or 0,
                }
            end
        end
    end

    return chars
end

RegisterNetEvent('rr_discord_gate:server:verify', function()
    local src = source
    local result = verifyDiscord(src)
    TriggerClientEvent('rr_discord_gate:client:verifyResult', src, result)
end)

RegisterNetEvent('rr_discord_gate:server:recheck', function()
    local src = source
    local discordId = getDiscordId(src)
    if discordId then
        cache[discordId] = nil
    end
    local result = verifyDiscord(src)
    TriggerClientEvent('rr_discord_gate:client:verifyResult', src, result)
end)

RegisterNetEvent('rr_discord_gate:server:getCharacters', function()
    local src = source
    local chars = getCharacters(src)
    TriggerClientEvent('rr_discord_gate:client:characters', src, {
        characters = chars,
        maxCharacters = Config.Flow.MaxCharacters or 4,
        invite = Config.Discord.Invite,
        discordEnabled = Config.Discord.Enabled == true,
    })
end)

RegisterNetEvent('rr_discord_gate:server:selectCharacter', function(citizenid)
    local src = source
    if type(citizenid) ~= 'string' and type(citizenid) ~= 'number' then return end
    -- Hook pour frameworks : à brancher sur qbx_core / esx_multicharacter
    TriggerEvent('rr_discord_gate:server:characterSelected', src, tostring(citizenid))
    TriggerClientEvent('rr_discord_gate:client:characterSelected', src, tostring(citizenid))
end)

RegisterNetEvent('rr_discord_gate:server:createCharacter', function()
    local src = source
    TriggerEvent('rr_discord_gate:server:createRequested', src)
    TriggerClientEvent('rr_discord_gate:client:createRequested', src)
end)

--- Export pour d'autres resources
exports('VerifyPlayer', function(src)
    return verifyDiscord(src)
end)

exports('GetInvite', function()
    return Config.Discord.Invite
end)

exports('InvalidateCache', function(discordId)
    if discordId then
        cache[tostring(discordId)] = nil
    else
        cache = {}
    end
end)

AddEventHandler('playerDropped', function()
    -- pas de nettoyage obligatoire ; cache par discordId
end)
