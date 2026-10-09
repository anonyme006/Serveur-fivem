SkyDS = SkyDS or {}

local RESOURCE = GetCurrentResourceName()

function SkyDS.Debug(...)
    if not Config.Debug then return end
    print(('[%s]'):format(RESOURCE), ...)
end

---@param key string
---@param ... any
---@return string
function SkyDS.L(key, ...)
    local locale = Locales and (Locales[Config.Locale] or Locales.en) or {}
    local str = locale[key] or (Locales and Locales.en and Locales.en[key]) or key
    if select('#', ...) > 0 then
        local ok, formatted = pcall(string.format, str, ...)
        if ok then return formatted end
    end
    return str
end

L = SkyDS.L

---@param categoryId string
---@return table|nil
function SkyDS.GetCategory(categoryId)
    return Config.Categories and Config.Categories[categoryId] or nil
end

---@return table[]
function SkyDS.GetEnabledCategories()
    local list = {}
    for id, cat in pairs(Config.Categories or {}) do
        if cat.enabled then
            list[#list + 1] = {
                id = id,
                label = cat.label,
                short = cat.short,
                icon = cat.icon,
                description = cat.description,
                theoryPrice = cat.theoryPrice,
                practicalPrice = cat.practicalPrice,
                color = cat.color,
                vehicleType = cat.vehicleType,
                maxPoints = cat.maxPoints or Config.Points.defaultMax,
                requires = cat.requires,
            }
        end
    end
    table.sort(list, function(a, b) return a.label < b.label end)
    return list
end

---@param schoolId string
---@return table|nil
function SkyDS.GetSchool(schoolId)
    for _, school in ipairs(Config.Schools or {}) do
        if school.id == schoolId then return school end
    end
    return nil
end

---@param school table
---@param categoryId string
---@return boolean
function SkyDS.SchoolOffers(school, categoryId)
    if not school or not school.categories then return false end
    for _, id in ipairs(school.categories) do
        if id == categoryId then return true end
    end
    return false
end

---@param value any
---@param min number
---@param max number
---@return number
function SkyDS.Clamp(value, min, max)
    value = tonumber(value) or 0
    if value < min then return min end
    if value > max then return max end
    return value
end

---@param list any[]
---@return any[]
function SkyDS.Shuffle(list)
    local t = {}
    for i = 1, #list do t[i] = list[i] end
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

function SkyDS.Now()
    if os and os.time then return os.time() end
    return math.floor((GetGameTimer and GetGameTimer() or 0) / 1000)
end

--- Client-safe timestamp (GetGameTimer is ms since start)
function SkyDS.GameNow()
    return GetGameTimer and GetGameTimer() or 0
end

---@param a vector3|vector4|table
---@param b vector3|vector4|table
---@return number
function SkyDS.Dist(a, b)
    local ax, ay, az = a.x or a[1], a.y or a[2], a.z or a[3]
    local bx, by, bz = b.x or b[1], b.y or b[2], b.z or b[3]
    local dx, dy, dz = ax - bx, ay - by, az - bz
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

---@param status string
---@param points number
---@param maxPoints number
---@return string
function SkyDS.LicenseStatus(status, points, maxPoints)
    if status == 'revoked' then return 'revoked' end
    if status == 'suspended' or (points or 0) <= (Config.Points.suspendAt or 0) then
        return 'suspended'
    end
    if status == 'valid' or (points or 0) > (Config.Points.suspendAt or 0) then
        return 'valid'
    end
    return status or 'unknown'
end

---@param categoryId string
---@return integer
function SkyDS.MaxPoints(categoryId)
    local cat = SkyDS.GetCategory(categoryId)
    return (cat and cat.maxPoints) or (Config.Points and Config.Points.defaultMax) or 12
end
