Taxi = Taxi or {}

---@param message string
---@param ... any
function Taxi.Debug(message, ...)
    if not Config.Debug.enabled then return end

    local formatted = message
    if select('#', ...) > 0 then
        formatted = string.format(message, ...)
    end

    print(('[qbx-taxi] %s'):format(formatted))
end

---@return string
function Taxi.GetResourceName()
    return GetCurrentResourceName()
end

---@param resourceName string
---@return boolean
function Taxi.IsResourceStarted(resourceName)
    return GetResourceState(resourceName) == 'started'
end

---@return boolean
function Taxi.IsQboxReady()
    return Taxi.IsResourceStarted('qbx_core')
end

---@return boolean
function Taxi.IsOxLibReady()
    return Taxi.IsResourceStarted('ox_lib')
end

---@return boolean
function Taxi.IsDutySystemReady()
    return Taxi.IsResourceStarted(Config.Duty.resource)
end

---@param grade number|nil
---@return table|nil
function Taxi.GetGradeConfig(grade)
    if grade == nil then return nil end
    return Config.Grades[grade]
end

---@param grade number|nil
---@return string
function Taxi.GetGradeLabel(grade)
    local gradeConfig = Taxi.GetGradeConfig(grade)
    return gradeConfig and gradeConfig.label or ('Grade %s'):format(tostring(grade))
end

---@param grade number|nil
---@return boolean
function Taxi.IsBossGrade(grade)
    local gradeConfig = Taxi.GetGradeConfig(grade)
    return gradeConfig and gradeConfig.isBoss == true or false
end

---@param grade number|nil
---@param permission string
---@return boolean
function Taxi.GradeHasPermission(grade, permission)
    local gradeConfig = Taxi.GetGradeConfig(grade)
    if not gradeConfig or not gradeConfig.permissions then return false end
    return gradeConfig.permissions[permission] == true
end

---@param amount number
---@return string
function Taxi.FormatMoney(amount)
    local symbol = Config.Economy.currencySymbol or '$'
    return ('%s%s'):format(symbol, math.floor(amount + 0.5))
end

---@param seconds number
---@return string
function Taxi.FormatDuration(seconds)
    seconds = math.max(0, math.floor(seconds))
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60

    if hours > 0 then
        return ('%dh %02dm'):format(hours, minutes)
    end

    if minutes > 0 then
        return ('%dm %02ds'):format(minutes, secs)
    end

    return ('%ds'):format(secs)
end

---@param meters number
---@return string
function Taxi.FormatDistance(meters)
    if Config.Units.distance == 'mi' then
        return ('%.2f mi'):format(meters / 1609.34)
    end

    return ('%.2f km'):format(meters / 1000.0)
end

---@param coords vector3|vector4|table
---@return vector3
function Taxi.ToVector3(coords)
    if type(coords) == 'vector3' then
        return coords
    end

    if type(coords) == 'vector4' then
        return vec3(coords.x, coords.y, coords.z)
    end

    return vec3(coords.x, coords.y, coords.z)
end

---@param coords vector3|vector4|table
---@return vector4
function Taxi.ToVector4(coords)
    if type(coords) == 'vector4' then
        return coords
    end

    if type(coords) == 'vector3' then
        return vec4(coords.x, coords.y, coords.z, 0.0)
    end

    return vec4(coords.x, coords.y, coords.z, coords.w or coords.h or 0.0)
end

---@param first vector3
---@param second vector3
---@return number
function Taxi.GetDistance(first, second)
    return #(Taxi.ToVector3(first) - Taxi.ToVector3(second))
end

---@param first vector3
---@param second vector3
---@return number
function Taxi.GetDistanceFlat(first, second)
    local a = Taxi.ToVector3(first)
    local b = Taxi.ToVector3(second)
    return #(vec3(a.x, a.y, 0.0) - vec3(b.x, b.y, 0.0))
end

---@param value any
---@return boolean
function Taxi.IsTable(value)
    return type(value) == 'table'
end

---@param value any
---@return boolean
function Taxi.IsNumber(value)
    return type(value) == 'number' and value == value
end

---@param value any
---@return boolean
function Taxi.IsString(value)
    return type(value) == 'string' and value ~= ''
end

---@param tableValue table
---@param key any
---@return boolean
function Taxi.TableHasKey(tableValue, key)
    return Taxi.IsTable(tableValue) and tableValue[key] ~= nil
end

---@return table
function Taxi.GetPublicConfig()
    return {
        company = {
            name = Config.Company.name,
            shortName = Config.Company.shortName,
            job = Config.Company.job,
            headquarters = Config.Company.headquarters,
            logo = Config.Company.logo,
            slogan = Config.Company.slogan,
            stateOwned = Config.CompanyStateOwned,
        },
        colors = Config.Colors,
        notifications = Config.Notifications,
        fares = Config.Fares,
        units = Config.Units,
        debug = Config.Debug.enabled,
    }
end

local function validateConfig()
    assert(Config.Company.job == 'taxi', '[qbx-taxi] Config.Company.job doit être "taxi"')
    assert(Config.Grades[0], '[qbx-taxi] Config.Grades[0] est requis')

    local commissionTotal = Config.Commissions.ride.company + Config.Commissions.ride.driver
    assert(commissionTotal == 100, '[qbx-taxi] Les commissions ride doivent totaliser 100%')

    Taxi.Debug('Configuration chargée (%s)', Config.Company.name)
end

validateConfig()
