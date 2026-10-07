Licenses = Licenses or {}

---@param def table|boolean|nil
---@param licenseType string
---@return table
function Licenses.Normalize(def, licenseType)
    local cfg = Config.Licenses[licenseType]
    local maxPoints = (cfg and cfg.maxPoints) or Config.DefaultMaxPoints or 12

    if def == true then
        return { owned = true, points = maxPoints }
    end

    if type(def) == 'table' then
        local owned
        if def.owned ~= nil then
            owned = def.owned == true or def.owned == 1
        elseif type(def.points) == 'number' then
            owned = def.points > 0 or def.valid == true
        else
            owned = def.valid == true
        end

        local points = tonumber(def.points)
        if points == nil then
            points = owned and maxPoints or 0
        end
        points = math.max(0, math.min(maxPoints, math.floor(points)))
        return { owned = owned == true, points = points }
    end

    return { owned = false, points = 0 }
end

---@param licences table|nil
---@return table
function Licenses.NormalizeAll(licences)
    local result = {}
    licences = type(licences) == 'table' and licences or {}
    for name in pairs(Config.Licenses) do
        result[name] = Licenses.Normalize(licences[name], name)
    end
    return result
end

---@param entry table
---@return boolean
function Licenses.IsValid(entry)
    return entry and entry.owned == true and (entry.points or 0) > 0
end

---@param licenseType string
---@return integer
function Licenses.MaxPoints(licenseType)
    local cfg = Config.Licenses[licenseType]
    return (cfg and cfg.maxPoints) or Config.DefaultMaxPoints or 12
end
