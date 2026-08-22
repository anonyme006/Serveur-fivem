local ESX = exports['es_extended']:getSharedObject()

local TABLE = Config.TableName or 'sd_company_announcements'

local VALID_TYPES = {}
local VALID_PRIORITIES = {}
local VALID_STATUSES = {}

for _, entry in ipairs(Config.Types or {}) do
    VALID_TYPES[entry.value] = true
end

for _, entry in ipairs(Config.Priorities or {}) do
    VALID_PRIORITIES[entry.value] = true
end

for _, entry in ipairs(Config.Statuses or {}) do
    VALID_STATUSES[entry.value] = true
end

local function debugPrint(...)
    if Config.Debug then
        print('[sd-company-announcements]', ...)
    end
end

--- Build a safe lookup of config options for the NUI (no secrets).
local function getPublicMeta()
    return {
        types      = Config.Types,
        priorities = Config.Priorities,
        statuses   = Config.Statuses,
        limits     = Config.Limits,
    }
end

local function ensureTable()
    MySQL.query.await(([[
        CREATE TABLE IF NOT EXISTS `%s` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `company` VARCHAR(50) NOT NULL,
            `title` VARCHAR(150) NOT NULL,
            `content` TEXT NOT NULL,
            `type` VARCHAR(50) NOT NULL DEFAULT 'information',
            `priority` VARCHAR(50) NOT NULL DEFAULT 'normal',
            `status` VARCHAR(50) NOT NULL DEFAULT 'draft',
            `author_identifier` VARCHAR(100) NOT NULL,
            `author_name` VARCHAR(100) DEFAULT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            INDEX `idx_company` (`company`),
            INDEX `idx_status` (`status`),
            INDEX `idx_company_created` (`company`, `created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]):format(TABLE))
end

local function getPlayer(source)
    return ESX.GetPlayerFromId(source)
end

local function getIdentifier(xPlayer)
    if not xPlayer then return nil end
    if xPlayer.getIdentifier then
        return xPlayer.getIdentifier()
    end
    return xPlayer.identifier
end

local function getPlayerName(xPlayer)
    if not xPlayer then return 'Inconnu' end
    if xPlayer.getName then
        return xPlayer.getName()
    end
    return xPlayer.name or 'Inconnu'
end

local function getJob(xPlayer)
    if not xPlayer or not xPlayer.job then return nil end
    return xPlayer.job
end

--- Resolve permissions for a job + grade. Never trusts client input.
---@return table|nil perms, string|nil company, string|nil err
local function resolveAccess(xPlayer)
    local job = getJob(xPlayer)
    if not job or not job.name then
        return nil, nil, 'no_job'
    end

    local companyCfg = Config.Companies[job.name]
    if not companyCfg or companyCfg.enabled == false then
        return nil, nil, 'company_disabled'
    end

    local grade = tonumber(job.grade) or 0
    local gradePerms = companyCfg.grades and companyCfg.grades[grade]

    if not gradePerms then
        if Config.AllowUnknownGrades then
            gradePerms = Config.FallbackPermissions or Config.DefaultPermissions
        else
            return nil, nil, 'grade_denied'
        end
    end

    local perms = {
        create  = gradePerms.create == true,
        edit    = gradePerms.edit == true,
        delete  = gradePerms.delete == true,
        publish = gradePerms.publish == true,
        view    = true,
    }

    return perms, job.name, nil
end

local function trim(value, maxLen)
    if type(value) ~= 'string' then return nil end
    value = value:gsub('^%s+', ''):gsub('%s+$', '')
    if value == '' then return nil end
    if maxLen and #value > maxLen then
        value = value:sub(1, maxLen)
    end
    return value
end

local function sanitizePayload(data)
    if type(data) ~= 'table' then return nil, 'invalid_payload' end

    local title = trim(data.title, Config.Limits.TitleMax)
    local content = trim(data.content, Config.Limits.ContentMax)
    local annType = type(data.type) == 'string' and data.type or 'information'
    local priority = type(data.priority) == 'string' and data.priority or 'normal'
    local status = type(data.status) == 'string' and data.status or 'draft'

    if not title then return nil, 'title_required' end
    if not content then return nil, 'content_required' end
    if not VALID_TYPES[annType] then return nil, 'invalid_type' end
    if not VALID_PRIORITIES[priority] then return nil, 'invalid_priority' end
    if not VALID_STATUSES[status] then return nil, 'invalid_status' end

    return {
        title = title,
        content = content,
        type = annType,
        priority = priority,
        status = status,
    }
end

--- Fetch one announcement and verify it belongs to the player's company.
local function getOwnedAnnouncement(id, company)
    id = tonumber(id)
    if not id or id < 1 then return nil end

    local row = MySQL.single.await(
        ('SELECT * FROM `%s` WHERE `id` = ? AND `company` = ? LIMIT 1'):format(TABLE),
        { id, company }
    )
    return row
end

local function canEditAnnouncement(perms, announcement, identifier)
    if not perms or not announcement then return false end
    if perms.edit then return true end
    -- Author can always edit their own draft/published posts if they have create
    if perms.create and announcement.author_identifier == identifier then
        return true
    end
    return false
end

local function formatAnnouncement(row)
    if not row then return nil end
    return {
        id = row.id,
        company = row.company,
        title = row.title,
        content = row.content,
        type = row.type,
        priority = row.priority,
        status = row.status,
        authorIdentifier = row.author_identifier,
        authorName = row.author_name,
        createdAt = row.created_at,
        updatedAt = row.updated_at,
    }
end

--- Send an ox_lib notification to one player (client event, works with ox_lib).
local function notifyOx(source, description, nType, title)
    local cfg = Config.Notifications
    if not cfg or not cfg.Enabled then return end
    if not cfg.OxLib or cfg.OxLib.Enabled == false then return end
    if not source then return end

    TriggerClientEvent('ox_lib:notify', source, {
        title       = title or cfg.Title or 'Annonces',
        description = description,
        type        = nType or 'inform',
        position    = cfg.OxLib.Position or 'top-right',
        duration    = cfg.OxLib.Duration or 5000,
    })
end

local function priorityLabelOf(priority)
    for _, entry in ipairs(Config.Priorities or {}) do
        if entry.value == priority then
            return entry.label:lower()
        end
    end
    return priority
end

--- Notify company members when an announcement is published.
--- Always ox_lib (if enabled); SD-Phone banner only for configured priorities.
local function notifyCompanyMembers(company, priority, title, excludeSource)
    if not Config.Notifications or not Config.Notifications.Enabled then return end

    local priorityLabel = priorityLabelOf(priority)
    local body = (Config.Notifications.Body or 'Une nouvelle annonce %s a été publiée par votre entreprise.')
        :format(priorityLabel)

    local phonePriorities = Config.Notifications.PhonePriorities or Config.Notifications.Priorities or {}
    local sendPhone = phonePriorities[priority] == true and GetResourceState('sd-phone') == 'started'
    local notifyCoworkers = Config.Notifications.NotifyCoworkers ~= false

    local xPlayers = ESX.GetExtendedPlayers('job', company)
    for _, xPlayer in pairs(xPlayers) do
        local src = xPlayer.source

        if notifyCoworkers and src ~= excludeSource then
            notifyOx(src, body, priority == 'urgent' and 'error' or 'inform', Config.Notifications.Title)
        end

        if sendPhone then
            pcall(function()
                exports['sd-phone']:notify(src, {
                    app   = Config.App.Identifier,
                    title = Config.Notifications.Title or 'Nouvelle annonce',
                    body  = body,
                    time  = 'now',
                    appId = Config.App.Identifier,
                })
            end)
        end

        TriggerClientEvent('sd-company-announcements:client:refresh', src, {
            reason = 'published',
            title = title,
        })
    end
end

local function runRetentionCleanup()
    local days = tonumber(Config.RetentionDays) or 0
    if days <= 0 then return end

    MySQL.update.await(
        ('DELETE FROM `%s` WHERE `status` = ? AND `updated_at` < (NOW() - INTERVAL ? DAY)'):format(TABLE),
        { 'archived', days }
    )
end

----------------------------------------------------------------
-- Boot
----------------------------------------------------------------

MySQL.ready(function()
    ensureTable()
    runRetentionCleanup()
    debugPrint('table ready:', TABLE)
end)

----------------------------------------------------------------
-- ESX server callbacks (sécurité + CRUD)
----------------------------------------------------------------

local function registerCallback(name, handler)
    ESX.RegisterServerCallback(name, function(source, cb, ...)
        local ok, result = pcall(handler, source, ...)
        if not ok then
            print(('[sd-company-announcements] callback %s error: %s'):format(name, result))
            cb({ ok = false, error = 'server_error' })
            return
        end
        cb(result)
    end)
end

registerCallback('sd-company-announcements:getBootstrap', function(source)
    local xPlayer = getPlayer(source)
    if not xPlayer then
        return { ok = false, error = 'no_player' }
    end

    local perms, company, err = resolveAccess(xPlayer)
    if not perms then
        return { ok = false, error = err or 'denied' }
    end

    local companyCfg = Config.Companies[company]
    local identifier = getIdentifier(xPlayer)

    return {
        ok = true,
        company = company,
        companyLabel = (companyCfg and companyCfg.label) or company,
        playerName = getPlayerName(xPlayer),
        identifier = identifier,
        permissions = perms,
        meta = getPublicMeta(),
    }
end)

registerCallback('sd-company-announcements:getAnnouncements', function(source, search)
    local xPlayer = getPlayer(source)
    if not xPlayer then
        return { ok = false, error = 'no_player' }
    end

    local perms, company, err = resolveAccess(xPlayer)
    if not perms then
        return { ok = false, error = err or 'denied' }
    end

    local rows
    search = trim(tostring(search or ''), 100)

    if search and search ~= '' then
        local like = '%' .. search:gsub('[%%_]', '') .. '%'
        rows = MySQL.query.await(
            ('SELECT * FROM `%s` WHERE `company` = ? AND (`title` LIKE ? OR `content` LIKE ?) ORDER BY `created_at` DESC LIMIT 200')
                :format(TABLE),
            { company, like, like }
        )
    else
        rows = MySQL.query.await(
            ('SELECT * FROM `%s` WHERE `company` = ? ORDER BY `created_at` DESC LIMIT 200'):format(TABLE),
            { company }
        )
    end

    local list = {}
    for i = 1, #(rows or {}) do
        list[#list + 1] = formatAnnouncement(rows[i])
    end

    return {
        ok = true,
        announcements = list,
        permissions = perms,
        company = company,
    }
end)

registerCallback('sd-company-announcements:getAnnouncement', function(source, id)
    local xPlayer = getPlayer(source)
    if not xPlayer then
        return { ok = false, error = 'no_player' }
    end

    local perms, company, err = resolveAccess(xPlayer)
    if not perms then
        return { ok = false, error = err or 'denied' }
    end

    local row = getOwnedAnnouncement(id, company)
    if not row then
        return { ok = false, error = 'not_found' }
    end

    local identifier = getIdentifier(xPlayer)
    return {
        ok = true,
        announcement = formatAnnouncement(row),
        permissions = perms,
        canEdit = canEditAnnouncement(perms, row, identifier),
        canDelete = perms.delete == true,
        canPublish = perms.publish == true,
    }
end)

registerCallback('sd-company-announcements:createAnnouncement', function(source, data)
    local xPlayer = getPlayer(source)
    if not xPlayer then
        return { ok = false, error = 'no_player' }
    end

    local perms, company, err = resolveAccess(xPlayer)
    if not perms then
        return { ok = false, error = err or 'denied' }
    end
    if not perms.create then
        return { ok = false, error = 'no_permission' }
    end

    local payload, perr = sanitizePayload(data)
    if not payload then
        return { ok = false, error = perr }
    end

    -- Publishing requires publish permission; otherwise force draft
    if payload.status == 'published' or payload.status == 'archived' then
        if not perms.publish then
            payload.status = 'draft'
        end
    end

    local identifier = getIdentifier(xPlayer)
    local authorName = getPlayerName(xPlayer)

    local insertId = MySQL.insert.await(
        ('INSERT INTO `%s` (`company`, `title`, `content`, `type`, `priority`, `status`, `author_identifier`, `author_name`) VALUES (?, ?, ?, ?, ?, ?, ?, ?)')
            :format(TABLE),
        {
            company,
            payload.title,
            payload.content,
            payload.type,
            payload.priority,
            payload.status,
            identifier,
            authorName,
        }
    )

    if not insertId then
        return { ok = false, error = 'db_error' }
    end

    local row = getOwnedAnnouncement(insertId, company)
    local msgs = (Config.Notifications and Config.Notifications.Messages) or {}

    if payload.status == 'published' then
        notifyOx(source, msgs.published or 'Annonce publiée.', 'success')
        notifyCompanyMembers(company, payload.priority, payload.title, source)
    else
        notifyOx(source, msgs.saved or 'Annonce enregistrée.', 'success')
    end

    return {
        ok = true,
        announcement = formatAnnouncement(row),
    }
end)

registerCallback('sd-company-announcements:updateAnnouncement', function(source, id, data)
    local xPlayer = getPlayer(source)
    if not xPlayer then
        return { ok = false, error = 'no_player' }
    end

    local perms, company, err = resolveAccess(xPlayer)
    if not perms then
        return { ok = false, error = err or 'denied' }
    end

    local row = getOwnedAnnouncement(id, company)
    if not row then
        return { ok = false, error = 'not_found' }
    end

    local identifier = getIdentifier(xPlayer)
    if not canEditAnnouncement(perms, row, identifier) then
        return { ok = false, error = 'no_permission' }
    end

    local payload, perr = sanitizePayload(data)
    if not payload then
        return { ok = false, error = perr }
    end

    local previousStatus = row.status
    local newStatus = payload.status

    -- Status transitions that require publish permission
    if newStatus ~= previousStatus then
        if (newStatus == 'published' or newStatus == 'archived' or previousStatus == 'published') and not perms.publish then
            -- Keep previous status if they cannot publish/archive
            if not (previousStatus == 'draft' and newStatus == 'draft') then
                newStatus = previousStatus
            end
        end
    end

    MySQL.update.await(
        ('UPDATE `%s` SET `title` = ?, `content` = ?, `type` = ?, `priority` = ?, `status` = ? WHERE `id` = ? AND `company` = ?')
            :format(TABLE),
        {
            payload.title,
            payload.content,
            payload.type,
            payload.priority,
            newStatus,
            row.id,
            company,
        }
    )

    local updated = getOwnedAnnouncement(row.id, company)
    local msgs = (Config.Notifications and Config.Notifications.Messages) or {}
    local phonePriorities = (Config.Notifications and (Config.Notifications.PhonePriorities or Config.Notifications.Priorities)) or {}

    if previousStatus ~= 'published' and newStatus == 'published' then
        notifyOx(source, msgs.published or 'Annonce publiée.', 'success')
        notifyCompanyMembers(company, payload.priority, payload.title, source)
    elseif newStatus == 'published' and payload.priority ~= row.priority and phonePriorities[payload.priority] then
        notifyOx(source, msgs.saved or 'Annonce enregistrée.', 'success')
        notifyCompanyMembers(company, payload.priority, payload.title, source)
    elseif newStatus == 'archived' and previousStatus ~= 'archived' then
        notifyOx(source, msgs.archived or 'Annonce archivée.', 'inform')
    else
        notifyOx(source, msgs.saved or 'Annonce enregistrée.', 'success')
    end

    return {
        ok = true,
        announcement = formatAnnouncement(updated),
    }
end)

registerCallback('sd-company-announcements:deleteAnnouncement', function(source, id)
    local xPlayer = getPlayer(source)
    if not xPlayer then
        return { ok = false, error = 'no_player' }
    end

    local perms, company, err = resolveAccess(xPlayer)
    if not perms then
        return { ok = false, error = err or 'denied' }
    end
    if not perms.delete then
        return { ok = false, error = 'no_permission' }
    end

    local row = getOwnedAnnouncement(id, company)
    if not row then
        return { ok = false, error = 'not_found' }
    end

    MySQL.update.await(
        ('DELETE FROM `%s` WHERE `id` = ? AND `company` = ?'):format(TABLE),
        { row.id, company }
    )

    local msgs = (Config.Notifications and Config.Notifications.Messages) or {}
    notifyOx(source, msgs.deleted or 'Annonce supprimée.', 'success')

    return { ok = true, id = row.id }
end)

registerCallback('sd-company-announcements:publishAnnouncement', function(source, id)
    local xPlayer = getPlayer(source)
    if not xPlayer then
        return { ok = false, error = 'no_player' }
    end

    local perms, company, err = resolveAccess(xPlayer)
    if not perms then
        return { ok = false, error = err or 'denied' }
    end
    if not perms.publish then
        return { ok = false, error = 'no_permission' }
    end

    local row = getOwnedAnnouncement(id, company)
    if not row then
        return { ok = false, error = 'not_found' }
    end

    MySQL.update.await(
        ('UPDATE `%s` SET `status` = ? WHERE `id` = ? AND `company` = ?'):format(TABLE),
        { 'published', row.id, company }
    )

    local updated = getOwnedAnnouncement(row.id, company)
    local msgs = (Config.Notifications and Config.Notifications.Messages) or {}
    notifyOx(source, msgs.published or 'Annonce publiée.', 'success')
    notifyCompanyMembers(company, updated.priority, updated.title, source)

    return { ok = true, announcement = formatAnnouncement(updated) }
end)

registerCallback('sd-company-announcements:archiveAnnouncement', function(source, id)
    local xPlayer = getPlayer(source)
    if not xPlayer then
        return { ok = false, error = 'no_player' }
    end

    local perms, company, err = resolveAccess(xPlayer)
    if not perms then
        return { ok = false, error = err or 'denied' }
    end
    if not perms.publish then
        return { ok = false, error = 'no_permission' }
    end

    local row = getOwnedAnnouncement(id, company)
    if not row then
        return { ok = false, error = 'not_found' }
    end

    MySQL.update.await(
        ('UPDATE `%s` SET `status` = ? WHERE `id` = ? AND `company` = ?'):format(TABLE),
        { 'archived', row.id, company }
    )

    local updated = getOwnedAnnouncement(row.id, company)
    local msgs = (Config.Notifications and Config.Notifications.Messages) or {}
    notifyOx(source, msgs.archived or 'Annonce archivée.', 'inform')

    return { ok = true, announcement = formatAnnouncement(updated) }
end)

--- Cosmetic gate for sd-phone `requires.check` (server export).
--- Returns true when the player belongs to an enabled company.
exports('canSeeApp', function(source)
    local xPlayer = getPlayer(source)
    if not xPlayer then return false end
    local perms = resolveAccess(xPlayer)
    return perms ~= nil
end)

--- Build job gate table for addCustomApp (minimum grade 0 for each enabled company)
exports('getJobGate', function()
    local gate = {}
    for name, cfg in pairs(Config.Companies or {}) do
        if cfg.enabled ~= false then
            gate[name] = 0
        end
    end
    return gate
end)