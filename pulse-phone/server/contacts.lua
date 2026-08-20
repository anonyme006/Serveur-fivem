--[[
    Pulse Phone — Contacts (fondation)
]]

Pulse = Pulse or {}
Pulse.Contacts = {}

lib.callback.register('pulse-phone:server:getContacts', function(source)
    local citizenid = Pulse.Server.GetCitizenId(source)
    if not citizenid then return {} end
    return MySQL.query.await(
        'SELECT * FROM phone_contacts WHERE owner_citizenid = ? ORDER BY favorite DESC, firstname ASC, lastname ASC',
        { citizenid }
    ) or {}
end)

lib.callback.register('pulse-phone:server:saveContact', function(source, data)
    local citizenid = Pulse.Server.GetCitizenId(source)
    if not citizenid or type(data) ~= 'table' then
        return { ok = false, error = 'invalid' }
    end

    local number = Pulse.Utils.NormalizeNumber(data.number)
    if not number or type(data.firstname) ~= 'string' or data.firstname == '' then
        return { ok = false, error = 'invalid' }
    end

    local firstname = data.firstname:sub(1, 50)
    local lastname = type(data.lastname) == 'string' and data.lastname:sub(1, 50) or ''
    local company = type(data.company) == 'string' and data.company:sub(1, 80) or nil
    local avatar = type(data.avatar) == 'string' and data.avatar:sub(1, 255) or nil
    local favorite = data.favorite and 1 or 0

    if data.id then
        local owned = MySQL.scalar.await(
            'SELECT 1 FROM phone_contacts WHERE id = ? AND owner_citizenid = ?',
            { data.id, citizenid }
        )
        if not owned then return { ok = false, error = 'forbidden' } end
        MySQL.update.await([[
            UPDATE phone_contacts
            SET firstname = ?, lastname = ?, number = ?, avatar = ?, company = ?, favorite = ?
            WHERE id = ? AND owner_citizenid = ?
        ]], { firstname, lastname, number, avatar, company, favorite, data.id, citizenid })
        return { ok = true, id = data.id }
    end

    local id = MySQL.insert.await([[
        INSERT INTO phone_contacts (owner_citizenid, firstname, lastname, number, avatar, company, favorite)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], { citizenid, firstname, lastname, number, avatar, company, favorite })

    return { ok = true, id = id }
end)

lib.callback.register('pulse-phone:server:deleteContact', function(source, contactId)
    local citizenid = Pulse.Server.GetCitizenId(source)
    if not citizenid or type(contactId) ~= 'number' then
        return { ok = false }
    end
    MySQL.update.await(
        'DELETE FROM phone_contacts WHERE id = ? AND owner_citizenid = ?',
        { contactId, citizenid }
    )
    return { ok = true }
end)
