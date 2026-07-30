Database = Database or {}

local ready = false
local cache = {}

local TABLES = {
    shops = 'core_creator_shops',
    blips = 'core_creator_blips',
    farms = 'core_creator_farms',
    jobs = 'core_creator_jobs',
    garages = 'core_creator_garages',
    gangs = 'core_creator_gangs',
    apartments = 'core_creator_apartments',
    robberies = 'core_creator_robberies',
    vehicle_keys = 'core_creator_vehicle_keys',
    logs = 'core_creator_logs',
    owned_vehicles = 'core_creator_owned_vehicles',
}

function Database.Table(moduleName)
    return TABLES[moduleName]
end

function Database.IsReady()
    return ready
end

function Database.WaitReady()
    while not ready do Wait(50) end
end

local function decodeRow(row)
    if not row then return nil end
    row.data = CoreUtils.SafeJsonDecode(row.data) or {}
    row.coords = CoreUtils.SafeJsonDecode(row.coords)
    row.active = row.active == 1 or row.active == true
    return row
end

local function encodePayload(data)
    return CoreUtils.SafeJsonEncode(data) or '{}'
end

function Database.Invalidate(moduleName)
    if moduleName then
        cache[moduleName] = nil
    else
        cache = {}
    end
end

function Database.GetAll(moduleName, activeOnly)
    Database.WaitReady()
    local tableName = TABLES[moduleName]
    if not tableName then return {} end

    if cache[moduleName] and not activeOnly then
        return CoreUtils.DeepCopy(cache[moduleName])
    end

    local query = ('SELECT * FROM `%s` ORDER BY id ASC'):format(tableName)
    if activeOnly then
        query = ('SELECT * FROM `%s` WHERE active = 1 ORDER BY id ASC'):format(tableName)
    end

    local rows = MySQL.query.await(query) or {}
    local mapped = {}
    for i = 1, #rows do
        mapped[i] = decodeRow(rows[i])
    end

    if not activeOnly then
        cache[moduleName] = CoreUtils.DeepCopy(mapped)
    end
    return mapped
end

function Database.GetById(moduleName, id)
    Database.WaitReady()
    local tableName = TABLES[moduleName]
    if not tableName then return nil end
    local row = MySQL.single.await(('SELECT * FROM `%s` WHERE id = ? LIMIT 1'):format(tableName), { id })
    return decodeRow(row)
end

function Database.GetByName(moduleName, name)
    Database.WaitReady()
    local tableName = TABLES[moduleName]
    if not tableName then return nil end
    local row = MySQL.single.await(('SELECT * FROM `%s` WHERE name = ? LIMIT 1'):format(tableName), { name })
    return decodeRow(row)
end

function Database.Create(moduleName, payload, author)
    Database.WaitReady()
    local tableName = TABLES[moduleName]
    if not tableName then return nil, 'unknown_module' end

    local coordsJson = payload.coords and encodePayload(payload.coords) or nil
    local dataJson = encodePayload(payload.data or {})

    local id = MySQL.insert.await(
        ('INSERT INTO `%s` (name, label, coords, data, active, created_by, updated_by) VALUES (?, ?, ?, ?, ?, ?, ?)'):format(tableName),
        {
            payload.name,
            payload.label,
            coordsJson,
            dataJson,
            payload.active and 1 or 0,
            author or 'system',
            author or 'system',
        }
    )

    Database.Invalidate(moduleName)
    return id
end

function Database.Update(moduleName, id, payload, author)
    Database.WaitReady()
    local tableName = TABLES[moduleName]
    if not tableName then return false, 'unknown_module' end

    local existing = Database.GetById(moduleName, id)
    if not existing then return false, 'not_found' end

    local name = payload.name or existing.name
    local label = payload.label or existing.label
    local coords = payload.coords ~= nil and payload.coords or existing.coords
    local data = payload.data ~= nil and payload.data or existing.data
    local active = payload.active
    if active == nil then active = existing.active end

    MySQL.update.await(
        ('UPDATE `%s` SET name = ?, label = ?, coords = ?, data = ?, active = ?, updated_by = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?'):format(tableName),
        {
            name,
            label,
            coords and encodePayload(coords) or nil,
            encodePayload(data or {}),
            active and 1 or 0,
            author or 'system',
            id,
        }
    )

    Database.Invalidate(moduleName)
    return true
end

function Database.SetActive(moduleName, id, active, author)
    return Database.Update(moduleName, id, { active = active and true or false }, author)
end

function Database.Delete(moduleName, id)
    Database.WaitReady()
    local tableName = TABLES[moduleName]
    if not tableName then return false, 'unknown_module' end
    MySQL.update.await(('DELETE FROM `%s` WHERE id = ?'):format(tableName), { id })
    Database.Invalidate(moduleName)
    return true
end

function Database.Duplicate(moduleName, id, author)
    local row = Database.GetById(moduleName, id)
    if not row then return nil, 'not_found' end
    local newName = row.name .. '_copy_' .. tostring(math.random(100, 999))
    newName = newName:sub(1, Config.Limits.name)
    return Database.Create(moduleName, {
        name = newName,
        label = (row.label or row.name) .. ' (copy)',
        coords = row.coords,
        data = row.data,
        active = false,
    }, author)
end

function Database.InsertLog(entry)
    if not Config.Logs.database then return end
    Database.WaitReady()
    MySQL.insert.await(
        'INSERT INTO core_creator_logs (action, module, entity_id, actor, actor_name, payload) VALUES (?, ?, ?, ?, ?, ?)',
        {
            entry.action,
            entry.module,
            entry.entity_id,
            entry.actor,
            entry.actor_name,
            encodePayload(entry.payload or {}),
        }
    )
end

CreateThread(function()
    local sqlFile = LoadResourceFile(CoreUtils.ResourceName(), 'sql/core_creator.sql')
    if sqlFile and sqlFile ~= '' then
        -- Strip SQL line comments before splitting statements
        local cleaned = sqlFile:gsub('%-%-[^\n]*', '')
        for statement in cleaned:gmatch('([^;]+);') do
            local trimmed = CoreUtils.Trim(statement)
            if trimmed ~= '' then
                local ok, err = pcall(function()
                    MySQL.query.await(trimmed)
                end)
                if not ok then
                    CoreUtils.Debug('SQL bootstrap warning:', err)
                end
            end
        end
    end
    ready = true
    CoreUtils.Print('Database ready')
    TriggerEvent('core_creator:databaseReady')
end)

exports('GetAll', function(moduleName, activeOnly)
    return Database.GetAll(moduleName, activeOnly)
end)

exports('GetById', function(moduleName, id)
    return Database.GetById(moduleName, id)
end)

exports('GetByName', function(moduleName, name)
    return Database.GetByName(moduleName, name)
end)
