--[[--------------------------------------------------------------------------
    Utilitaires partagés — locales, debug, tables, départements
---------------------------------------------------------------------------]]

Police = Police or {}

---@param key string
---@param ... any
---@return string
function Police.Locale(key, ...)
    local lang = (Config and Config.Locale) or 'fr'
    local pack = Locales[lang] or Locales.fr or {}
    local str = pack[key] or (Locales.fr and Locales.fr[key]) or key
    if select('#', ...) > 0 then
        local ok, formatted = pcall(string.format, str, ...)
        if ok then return formatted end
    end
    return str
end

---@param ... any
function Police.Debug(...)
    if not Config or not Config.Debug then return end
    print(('[qbx_policejob]'), ...)
end

---@param value any
---@return boolean
function Police.IsVector(value)
    local t = type(value)
    return t == 'vector3' or t == 'vector4' or (t == 'table' and value.x and value.y and value.z)
end

---@param coords vector3|vector4|table
---@return vector3
function Police.ToVec3(coords)
    if type(coords) == 'vector3' then return coords end
    if type(coords) == 'vector4' then return vec3(coords.x, coords.y, coords.z) end
    return vec3(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
end

---@param a vector3|table
---@param b vector3|table
---@return number
function Police.Distance(a, b)
    return #(Police.ToVec3(a) - Police.ToVec3(b))
end

---@param plate string|nil
---@return string
function Police.NormalizePlate(plate)
    return (plate or ''):gsub('%s+', ''):upper()
end

---@param raw string|table|nil
---@return table
function Police.DecodeJson(raw)
    if type(raw) == 'table' then return raw end
    if type(raw) ~= 'string' or raw == '' then return {} end
    local ok, data = pcall(json.decode, raw)
    return (ok and type(data) == 'table' and data) or {}
end

---@param tbl table|nil
---@return integer
function Police.TableCount(tbl)
    if type(tbl) ~= 'table' then return 0 end
    local n = 0
    for _ in pairs(tbl) do n += 1 end
    return n
end

---@param list any[]|nil
---@param value any
---@return boolean
function Police.ListHas(list, value)
    if type(list) ~= 'table' then return false end
    for i = 1, #list do
        if list[i] == value then return true end
    end
    return false
end

--- Index jobName → departmentId
local jobIndex

---@return table<string, string>
function Police.BuildJobIndex()
    jobIndex = {}
    for deptId, dept in pairs(Config.Departments or {}) do
        if dept.enabled ~= false and dept.job then
            jobIndex[dept.job] = deptId
        end
    end
    return jobIndex
end

---@param jobName string|nil
---@return string|nil departmentId
---@return table|nil department
function Police.GetDepartmentByJob(jobName)
    if not jobName or jobName == '' then return nil, nil end
    if not jobIndex then Police.BuildJobIndex() end
    local deptId = jobIndex[jobName]
    if not deptId then return nil, nil end
    return deptId, Config.Departments[deptId]
end

---@param deptId string
---@return table|nil
function Police.GetDepartment(deptId)
    local dept = Config.Departments and Config.Departments[deptId]
    if not dept or dept.enabled == false then return nil end
    return dept
end

---@return string[]
function Police.GetEnabledJobNames()
    if not jobIndex then Police.BuildJobIndex() end
    local jobs = {}
    for jobName in pairs(jobIndex) do
        jobs[#jobs + 1] = jobName
    end
    return jobs
end

---@param jobName string|nil
---@return boolean
function Police.IsLeoJob(jobName)
    local _, dept = Police.GetDepartmentByJob(jobName)
    return dept ~= nil
end

--- Rebuild index when configs reload
CreateThread(function()
    Police.BuildJobIndex()
end)
