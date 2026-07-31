Gruppe6Points = {}

local function rowToPoint(row)
    return {
        id = row.id,
        type = row.point_type,
        label = row.label,
        coords = vec3(row.x, row.y, row.z),
        enabled = row.enabled == 1,
    }
end

function Gruppe6Points.Load()
    local rows = MySQL.query.await('SELECT * FROM vibe_gruppe6_points ORDER BY id ASC') or {}
    local list = {}
    for i = 1, #rows do
        list[#list + 1] = rowToPoint(rows[i])
    end
    return list
end

function Gruppe6Points.SeedDefaults()
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM vibe_gruppe6_points') or 0
    if count > 0 then return end

    for _, point in ipairs(Config.DefaultPoints) do
        MySQL.insert.await([[
            INSERT INTO vibe_gruppe6_points (point_type, label, x, y, z, enabled)
            VALUES (?, ?, ?, ?, ?, 1)
        ]], { point.type, point.label, point.coords.x, point.coords.y, point.coords.z })
    end
end

function Gruppe6Points.GetEnabled()
    local rows = MySQL.query.await('SELECT * FROM vibe_gruppe6_points WHERE enabled = 1 ORDER BY id ASC') or {}
    local list = {}
    for i = 1, #rows do
        list[#list + 1] = rowToPoint(rows[i])
    end
    return list
end

function Gruppe6Points.GetById(id)
    local row = MySQL.single.await('SELECT * FROM vibe_gruppe6_points WHERE id = ?', { id })
    if not row then return nil end
    return rowToPoint(row)
end

function Gruppe6Points.Add(pointType, label, coords)
    local id = MySQL.insert.await([[
        INSERT INTO vibe_gruppe6_points (point_type, label, x, y, z, enabled)
        VALUES (?, ?, ?, ?, ?, 1)
    ]], { pointType, label, coords.x, coords.y, coords.z })
    return Gruppe6Points.GetById(id)
end

function Gruppe6Points.Delete(id)
    return MySQL.update.await('DELETE FROM vibe_gruppe6_points WHERE id = ?', { id }) > 0
end

function Gruppe6Points.Toggle(id, enabled)
    return MySQL.update.await('UPDATE vibe_gruppe6_points SET enabled = ? WHERE id = ?', { enabled and 1 or 0, id }) > 0
end

function Gruppe6Points.IsValidType(pointType)
    return Config.PayByType[pointType] ~= nil
end
