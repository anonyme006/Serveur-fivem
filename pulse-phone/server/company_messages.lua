--[[
    Pulse Phone — Messages entreprises
]]

Pulse = Pulse or {}
Pulse.CompanyMessages = {}

local msgCooldown = {}

local function getOnlineEmployees(jobName, minGrade)
    local list = {}
    local players = exports.qbx_core:GetQBPlayers()
    if not players then return list end
    for src, player in pairs(players) do
        local job = player.PlayerData and player.PlayerData.job
        if job and job.name == jobName and job.onduty then
            local grade = job.grade and job.grade.level or 0
            if grade >= (minGrade or 0) then
                list[#list + 1] = src
            end
        end
    end
    return list
end

lib.callback.register('pulse-phone:server:getCompanyThreads', function(source)
    local citizenid = Pulse.Server.GetCitizenId(source)
    if not citizenid then return {} end

    local ctx = Pulse.Companies.GetPlayerCompanyContext(source)
    local threads = {}

    -- Threads du joueur (citoyen → entreprises)
    local playerThreads = MySQL.query.await([[
        SELECT m.company_id,
               MAX(m.id) AS last_id,
               SUM(CASE WHEN m.sender_type = 'company' AND m.is_read = 0 THEN 1 ELSE 0 END) AS unread
        FROM phone_company_messages m
        WHERE m.citizenid = ?
        GROUP BY m.company_id
        ORDER BY last_id DESC
        LIMIT 50
    ]], { citizenid }) or {}

    for _, t in ipairs(playerThreads) do
        local company = Config.Companies[t.company_id]
        local last = MySQL.single.await('SELECT body, created_at, sender_type FROM phone_company_messages WHERE id = ?', { t.last_id })
        threads[#threads + 1] = {
            companyId = t.company_id,
            label = company and company.label or t.company_id,
            icon = company and company.icon or 'CO',
            iconColor = company and company.iconColor or '#0D9488',
            lastMessage = last and last.body or '',
            lastAt = last and last.created_at or nil,
            unread = tonumber(t.unread) or 0,
            citizenid = citizenid,
            asEmployee = false,
        }
    end

    -- Boîte entreprise (employé on duty / membre)
    if ctx and ctx.isEmployee then
        local companyThreads = MySQL.query.await([[
            SELECT m.citizenid,
                   MAX(m.id) AS last_id,
                   SUM(CASE WHEN m.sender_type = 'player' AND m.is_read = 0 THEN 1 ELSE 0 END) AS unread
            FROM phone_company_messages m
            WHERE m.company_id = ?
            GROUP BY m.citizenid
            ORDER BY last_id DESC
            LIMIT 50
        ]], { ctx.companyId }) or {}

        for _, t in ipairs(companyThreads) do
            local last = MySQL.single.await(
                'SELECT body, created_at, sender_name FROM phone_company_messages WHERE id = ?',
                { t.last_id }
            )
            threads[#threads + 1] = {
                companyId = ctx.companyId,
                label = last and last.sender_name or t.citizenid,
                icon = 'MSG',
                iconColor = '#0D9488',
                lastMessage = last and last.body or '',
                lastAt = last and last.created_at or nil,
                unread = tonumber(t.unread) or 0,
                citizenid = t.citizenid,
                asEmployee = true,
            }
        end
    end

    return threads
end)

lib.callback.register('pulse-phone:server:getCompanyChat', function(source, data)
    local citizenid = Pulse.Server.GetCitizenId(source)
    if not citizenid or type(data) ~= 'table' then return { ok = false } end

    local companyId = data.companyId
    local company = Config.Companies[companyId]
    if not company then return { ok = false, error = 'unknown' } end

    local threadCitizen = data.citizenid or citizenid
    local ctx = Pulse.Companies.GetPlayerCompanyContext(source)
    local asEmployee = ctx and ctx.companyId == companyId

    if asEmployee then
        -- employé lit un thread client
        if type(threadCitizen) ~= 'string' then return { ok = false } end
    else
        -- citoyen ne lit que ses messages
        threadCitizen = citizenid
    end

    local messages = MySQL.query.await([[
        SELECT id, sender_type, sender_name, body, created_at, is_read
        FROM phone_company_messages
        WHERE company_id = ? AND citizenid = ?
        ORDER BY id ASC
        LIMIT 200
    ]], { companyId, threadCitizen }) or {}

    -- Marquer lus
    if asEmployee then
        MySQL.update.await(
            'UPDATE phone_company_messages SET is_read = 1 WHERE company_id = ? AND citizenid = ? AND sender_type = ? AND is_read = 0',
            { companyId, threadCitizen, 'player' }
        )
    else
        MySQL.update.await(
            'UPDATE phone_company_messages SET is_read = 1 WHERE company_id = ? AND citizenid = ? AND sender_type = ? AND is_read = 0',
            { companyId, threadCitizen, 'company' }
        )
    end

    return {
        ok = true,
        companyId = companyId,
        label = company.label,
        icon = company.icon or 'CO',
        iconColor = company.iconColor or '#0D9488',
        citizenid = threadCitizen,
        asEmployee = asEmployee and true or false,
        messages = messages,
    }
end)

lib.callback.register('pulse-phone:server:sendCompanyMessage', function(source, data)
    local citizenid = Pulse.Server.GetCitizenId(source)
    if not citizenid or type(data) ~= 'table' then return { ok = false } end

    local now = os.time()
    local cd = (Config.Cooldowns.sendCompanyMessage or Config.Cooldowns.sendMessage or 800) / 1000
    if msgCooldown[source] and now - msgCooldown[source] < cd then
        return { ok = false, error = 'cooldown' }
    end
    msgCooldown[source] = now

    local companyId = data.companyId
    local company = Config.Companies[companyId]
    if not company then return { ok = false, error = 'unknown' } end

    local body = type(data.body) == 'string' and data.body:gsub('^%s+', ''):gsub('%s+$', '') or ''
    if body == '' or #body > 1000 then return { ok = false, error = 'invalid' } end

    local ctx = Pulse.Companies.GetPlayerCompanyContext(source)
    local asEmployee = ctx and ctx.companyId == companyId
    local user = Pulse.Database.GetUser(citizenid)
    local senderName = Pulse.Players.GetFullName(source)

    local threadCitizen = citizenid
    local senderType = 'player'

    if asEmployee then
        if type(data.citizenid) ~= 'string' then return { ok = false, error = 'invalid' } end
        threadCitizen = data.citizenid
        senderType = 'company'
        senderName = company.label
    end

    local id = MySQL.insert.await([[
        INSERT INTO phone_company_messages
            (company_id, citizenid, sender_type, sender_name, sender_number, body, is_read)
        VALUES (?, ?, ?, ?, ?, ?, 0)
    ]], {
        companyId,
        threadCitizen,
        senderType,
        senderName,
        user and user.phone_number or nil,
        body,
    })

    if senderType == 'player' then
        for _, empSrc in ipairs(getOnlineEmployees(company.job, company.minGrade)) do
            TriggerClientEvent('pulse-phone:client:notify', empSrc, {
                type = 'company_message',
                title = company.label,
                body = ('%s: %s'):format(senderName, body:sub(1, 60)),
                sound = 'company',
                payload = { companyId = companyId, citizenid = threadCitizen },
            })
            TriggerClientEvent('pulse-phone:client:companyMessage', empSrc, {
                id = id,
                companyId = companyId,
                citizenid = threadCitizen,
                body = body,
                senderName = senderName,
            })
        end
    else
        local clientSrc = nil
        local players = exports.qbx_core:GetQBPlayers()
        if players then
            for src, player in pairs(players) do
                if player.PlayerData.citizenid == threadCitizen then
                    clientSrc = src
                    break
                end
            end
        end
        if clientSrc then
            TriggerClientEvent('pulse-phone:client:notify', clientSrc, {
                type = 'company_message',
                title = company.label,
                body = body:sub(1, 80),
                sound = 'sms',
                payload = { companyId = companyId },
            })
            TriggerClientEvent('pulse-phone:client:companyMessage', clientSrc, {
                id = id,
                companyId = companyId,
                body = body,
                senderName = company.label,
            })
        end
    end

    return {
        ok = true,
        message = {
            id = id,
            sender_type = senderType,
            sender_name = senderName,
            body = body,
            created_at = os.date('%Y-%m-%d %H:%M:%S'),
        },
    }
end)
