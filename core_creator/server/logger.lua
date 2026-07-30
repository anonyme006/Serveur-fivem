Logger = Logger or {}

local function pickWebhook(moduleName)
    local hooks = Config.Logs.webhooks or {}
    if moduleName and hooks[moduleName] and hooks[moduleName] ~= '' then
        return hooks[moduleName]
    end
    if hooks.admin and hooks.admin ~= '' then
        return hooks.admin
    end
    return nil
end

local function sendDiscord(webhook, title, description, fields, color)
    if not Config.Logs.discord or not webhook or webhook == '' then return end
    PerformHttpRequest(webhook, function() end, 'POST', json.encode({
        username = 'Core Creator',
        embeds = {{
            title = title,
            description = description,
            color = color or 5793266,
            fields = fields or {},
            footer = { text = 'core_creator' },
            timestamp = CoreUtils.ISODate(),
        }},
    }), { ['Content-Type'] = 'application/json' })
end

function Logger.Log(src, action, moduleName, entityId, payload)
    local actor = 'console'
    local actorName = 'console'
    if src and src > 0 then
        actor = Bridge.GetIdentifier(src) or tostring(src)
        actorName = Bridge.GetName(src) or GetPlayerName(src) or actor
    end

    local entry = {
        action = action,
        module = moduleName,
        entity_id = entityId,
        actor = actor,
        actor_name = actorName,
        payload = payload or {},
    }

    if Config.Logs.console then
        CoreUtils.Print(('LOG %s module=%s id=%s by=%s'):format(action, tostring(moduleName), tostring(entityId), actorName))
    end

    Database.InsertLog(entry)

    sendDiscord(
        pickWebhook(moduleName),
        ('[%s] %s'):format(string.upper(tostring(moduleName or 'core')), action),
        ('Actor: **%s**'):format(actorName),
        {
            { name = 'Entity', value = tostring(entityId or '-'), inline = true },
            { name = 'Identifier', value = actor, inline = true },
        },
        action:find('delete') and 15158332 or (action:find('create') and 5763719 or 5793266)
    )
end

exports('Log', function(src, action, moduleName, entityId, payload)
    Logger.Log(src, action, moduleName, entityId, payload)
end)
