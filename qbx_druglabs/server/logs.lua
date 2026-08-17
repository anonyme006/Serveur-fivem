Logs = Logs or {}

---@param action string
---@param data table|nil
function LogAction(action, data)
    if not Config.Logs.enabled then return end
    data = data or {}

    local payload = {
        action = action,
        labId = data.labId,
        actor = data.actor,
        data = data,
        time = os.time(),
    }

    if Config.Logs.console then
        print(('[qbx_druglabs:log] %s %s'):format(action, json.encode(data)))
    end

    if Config.Logs.database then
        MySQL.insert(
            'INSERT INTO drug_lab_logs (lab_id, actor, action, data) VALUES (?, ?, ?, ?)',
            { data.labId, data.actor, action, json.encode(data) }
        )
    end

    local webhook = Config.Logs.discordWebhook
    if type(webhook) == 'string' and webhook ~= '' then
        PerformHttpRequest(webhook, function() end, 'POST', json.encode({
            username = 'qbx_druglabs',
            embeds = {{
                title = action,
                description = ('```json\n%s\n```'):format(json.encode(data)),
                color = 10181046,
                footer = { text = os.date('%Y-%m-%d %H:%M:%S') },
            }},
        }), { ['Content-Type'] = 'application/json' })
    end

    Logs.last = payload
end
