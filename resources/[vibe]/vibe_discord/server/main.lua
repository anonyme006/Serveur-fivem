local function send(webhook, title, description, color)
    if not webhook or webhook == '' then return end
    PerformHttpRequest(webhook, function() end, 'POST', json.encode({
        username = Config.ServerName,
        embeds = {{
            title = title,
            description = description,
            color = color or 5793266,
            footer = { text = os.date('%Y-%m-%d %H:%M:%S') },
        }},
    }), { ['Content-Type'] = 'application/json' })
end

exports('Log', function(channel, title, description, color)
    local url = Config.Webhooks[channel or 'default'] or Config.Webhooks.default
    send(url, title, description, color)
end)

AddEventHandler('vibe_dispatch:server:log', function(kind, data)
    exports.vibe_discord:Log('police', 'Dispatch / ' .. tostring(kind), json.encode(data or {}), 15158332)
end)
