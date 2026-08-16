ShopCreator = ShopCreator or {}

---@param action string
---@param data table|nil
function ShopCreator.Log(action, data)
    if not Config.Logging or not Config.Logging.enabled then return end
    data = data or {}

    local payload = {
        action = action,
        resource = ShopCreator.Resource,
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        data = data,
    }

    if Config.Logging.console or Config.Debug then
        print(('[qbx_shopcreator] %s %s'):format(action, json.encode(data)))
    end

    local webhook = Config.Logging.webhook
    if type(webhook) == 'string' and webhook ~= '' then
        PerformHttpRequest(webhook, function() end, 'POST', json.encode({
            username = 'qbx_shopcreator',
            embeds = {{
                title = action,
                description = ('```json\n%s\n```'):format(json.encode(data):sub(1, 1800)),
                color = 0x7C3AED,
            }},
        }), { ['Content-Type'] = 'application/json' })
    end

    -- Extension point for external log bridges
    TriggerEvent('qbx_shopcreator:server:log', payload)
end