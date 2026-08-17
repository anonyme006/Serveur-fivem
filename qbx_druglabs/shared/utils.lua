DrugLabs = DrugLabs or {}

function DrugLabs.Debug(...)
    if not Config.Debug then return end
    print(('[qbx_druglabs] %s'):format(table.concat({ ... }, ' ')))
end

---@param value any
---@return boolean
function DrugLabs.IsValidId(value)
    return type(value) == 'number' and value == math.floor(value) and value > 0
end

---@param value any
---@return boolean
function DrugLabs.IsNonEmptyString(value)
    return type(value) == 'string' and value:match('%S') ~= nil
end

---@param quantity any
---@return boolean
function DrugLabs.IsPositiveInt(quantity)
    return type(quantity) == 'number' and quantity == math.floor(quantity) and quantity > 0
end

---@param tbl table|nil
---@return table
function DrugLabs.DeepCopy(tbl)
    if type(tbl) ~= 'table' then return {} end
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = type(v) == 'table' and DrugLabs.DeepCopy(v) or v
    end
    return copy
end

---@param coords vector3|vector4|table
---@return table
function DrugLabs.SerializeCoords(coords)
    if not coords then return {} end
    return {
        x = coords.x + 0.0,
        y = coords.y + 0.0,
        z = coords.z + 0.0,
        w = coords.w or coords.heading or 0.0,
    }
end

---@param data table|string|nil
---@return vector4|nil
function DrugLabs.ToVec4(data)
    if type(data) == 'string' then
        data = json.decode(data)
    end
    if type(data) ~= 'table' or not data.x then return nil end
    return vec4(data.x + 0.0, data.y + 0.0, data.z + 0.0, (data.w or data.heading or 0.0) + 0.0)
end

---@param data table|string|nil
---@return vector3|nil
function DrugLabs.ToVec3(data)
    if type(data) == 'string' then
        data = json.decode(data)
    end
    if type(data) ~= 'table' or not data.x then return nil end
    return vec3(data.x + 0.0, data.y + 0.0, data.z + 0.0)
end

---@param openHour number
---@param closeHour number
---@param hour number|nil
---@return boolean
function DrugLabs.IsWithinHours(openHour, closeHour, hour)
    hour = hour or GetClockHours()
    if openHour == closeHour then return true end
    if openHour < closeHour then
        return hour >= openHour and hour < closeHour
    end
    return hour >= openHour or hour < closeHour
end

---@param quality number|nil
---@return number
function DrugLabs.ClampQuality(quality)
    quality = tonumber(quality) or Config.Quality.default
    return math.max(Config.Quality.min, math.min(Config.Quality.max, math.floor(quality + 0.5)))
end

---@param prefix string
---@return string
function DrugLabs.GenerateBatchCode(prefix)
    prefix = (prefix or 'LAB'):upper():gsub('%W', '')
    local chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
    local out = {}
    for i = 1, 6 do
        local idx = math.random(1, #chars)
        out[i] = chars:sub(idx, idx)
    end
    return ('%s-%s'):format(prefix:sub(1, 4), table.concat(out))
end

---@param labType string
---@return table|nil
function DrugLabs.GetLabType(labType)
    return Config.LabTypes[labType]
end

---@param labType string
---@param recipeId string
---@return table|nil
function DrugLabs.GetRecipe(labType, recipeId)
    local recipes = Config.Recipes[labType]
    if not recipes then return nil end
    for i = 1, #recipes do
        if recipes[i].id == recipeId then
            return recipes[i]
        end
    end
    return nil
end

---@param labType string
---@param stationKey string
---@return table[]
function DrugLabs.GetRecipesForStation(labType, stationKey)
    local recipes = Config.Recipes[labType] or {}
    local result = {}
    for i = 1, #recipes do
        local recipe = recipes[i]
        if recipe.station == stationKey or stationKey:find(recipe.station, 1, true) then
            result[#result + 1] = recipe
        end
    end
    return result
end

---@param permissions table|nil
---@param permission string
---@return boolean
function DrugLabs.HasPermissionFlag(permissions, permission)
    if type(permissions) ~= 'table' then return false end
    return permissions[permission] == true
end

---@param seconds number
---@return string
function DrugLabs.FormatDuration(seconds)
    seconds = math.max(0, math.floor(seconds or 0))
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    if days > 0 then
        return ('%dd %dh'):format(days, hours)
    end
    local minutes = math.floor((seconds % 3600) / 60)
    if hours > 0 then
        return ('%dh %dm'):format(hours, minutes)
    end
    return ('%dm'):format(minutes)
end
