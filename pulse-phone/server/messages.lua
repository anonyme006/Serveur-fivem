--[[
    Pulse Phone — Messages (fondation)
]]

Pulse = Pulse or {}
Pulse.Messages = {}

local function conversationId(a, b)
    if a < b then return a .. ':' .. b end
    return b .. ':' .. a
end

lib.callback.register('pulse-phone:server:getConversations', function(source)
    local citizenid = Pulse.Server.GetCitizenId(source)
    if not citizenid then return {} end
    local user = Pulse.Database.GetUser(citizenid)
    if not user then return {} end

    return MySQL.query.await([[
        SELECT m.*
        FROM phone_messages m
        INNER JOIN (
            SELECT conversation_id, MAX(id) AS max_id
            FROM phone_messages
            WHERE sender_number = ? OR receiver_number = ?
            GROUP BY conversation_id
        ) last ON last.max_id = m.id
        ORDER BY m.id DESC
        LIMIT 100
    ]], { user.phone_number, user.phone_number }) or {}
end)

lib.callback.register('pulse-phone:server:sendMessage', function(source, data)
    local citizenid = Pulse.Server.GetCitizenId(source)
    if not citizenid or type(data) ~= 'table' then
        return { ok = false }
    end

    local user = Pulse.Database.GetUser(citizenid)
    if not user then return { ok = false } end

    local to = Pulse.Utils.NormalizeNumber(data.to)
    local body = type(data.body) == 'string' and data.body:sub(1, 1000) or ''
    if not to or body == '' then return { ok = false, error = 'invalid' } end

    local conv = conversationId(user.phone_number, to)
    local attachments = nil
    if type(data.attachments) == 'table' then
        attachments = json.encode(data.attachments)
    end

    local id = MySQL.insert.await([[
        INSERT INTO phone_messages (conversation_id, sender_citizenid, sender_number, receiver_number, body, attachments)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], { conv, citizenid, user.phone_number, to, body, attachments })

    local targetSrc = Pulse.Players.GetSourceByNumber(to)
    if targetSrc then
        TriggerClientEvent('pulse-phone:client:notify', targetSrc, {
            type = 'message',
            title = L('new_message'),
            body = body:sub(1, 80),
            sound = 'sms',
            payload = { conversationId = conv, from = user.phone_number },
        })
        TriggerClientEvent('pulse-phone:client:messageNew', targetSrc, {
            id = id,
            conversationId = conv,
            from = user.phone_number,
            body = body,
        })
    end

    return { ok = true, id = id, conversationId = conv }
end)
