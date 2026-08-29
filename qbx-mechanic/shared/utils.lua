Utils = {}

local RESOURCE = 'qbx-mechanic'

---@param ... string|number|boolean
function Utils.Debug(...)
    if not Config or not Config.Debug then return end
    local parts = { ... }
    for i = 1, #parts do
        parts[i] = tostring(parts[i])
    end
    print(('[%s] %s'):format(Config.ResourceName or RESOURCE, table.concat(parts, ' ')))
end

function Utils.Clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

function Utils.Round(value, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(value * mult + 0.5) / mult
end

function Utils.Percent(value, max)
    max = max or 1000.0
    if max <= 0 then return 0 end
    return Utils.Clamp(Utils.Round((value / max) * 100, 0), 0, 100)
end

function Utils.NormalizePlate(plate)
    if not plate then return nil end
    return (tostring(plate):gsub('%s+', ''):upper())
end

function Utils.FormatMoney(amount)
    amount = tonumber(amount) or 0
    local symbol = (Config and Config.CurrencySymbol) or '$'
    local formatted = tostring(math.floor(amount))
    while true do
        local replaced
        formatted, replaced = formatted:gsub('^(-?%d+)(%d%d%d)', '%1 %2')
        if replaced == 0 then break end
    end
    return formatted .. symbol
end

function Utils.DeepCopy(original)
    if type(original) ~= 'table' then return original end
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = Utils.DeepCopy(value)
    end
    return copy
end

function Utils.DecodeJson(value, fallback)
    if type(value) == 'table' then return value end
    if type(value) ~= 'string' or value == '' then
        return fallback or {}
    end
    local ok, decoded = pcall(json.decode, value)
    if ok and type(decoded) == 'table' then
        return decoded
    end
    return fallback or {}
end

function Utils.EncodeJson(value)
    return json.encode(value or {})
end

---@param grade number
---@param permission string
---@return boolean
function Utils.HasPermission(grade, permission)
    if not Config or not Config.Permissions then return false end
    local required = Config.Permissions[permission]
    if required == nil then return false end
    return (tonumber(grade) or 0) >= required
end

---@param mechanicId string
---@return table|nil
function Utils.GetMechanic(mechanicId)
    if not Config or not Config.Mechanics then return nil end
    return Config.Mechanics[mechanicId]
end

---@param mechanicId string
---@param grade number
---@return boolean
function Utils.IsBossGrade(mechanicId, grade)
    local mechanic = Utils.GetMechanic(mechanicId)
    if not mechanic or not mechanic.bossGrades then return false end
    return mechanic.bossGrades[tonumber(grade) or 0] == true
end

---@param source number|nil
---@param message string
---@param nType string|nil
---@param duration number|nil
function Utils.Notify(source, message, nType, duration)
    local title = Config and Config.Job and Config.Job.label or 'Mécanicien'
    local payload = {
        title = title,
        description = message,
        type = nType or 'inform',
        duration = duration or 5000,
    }

    if IsDuplicityVersion() then
        if not source then return end
        TriggerClientEvent('ox_lib:notify', source, payload)
    else
        lib.notify(payload)
    end
end

-- =============================================================================
-- FRAMEWORK QBOX (shared helpers — server vérifie, client UX uniquement)
-- =============================================================================

Framework = {}

function Framework.GetResourceName()
    return (Config and Config.Framework and Config.Framework.resource) or 'qbx_core'
end

if IsDuplicityVersion() then
    ---@param source number
    ---@return table|nil player
    function Framework.GetPlayer(source)
        local ok, player = pcall(function()
            return exports[Framework.GetResourceName()]:GetPlayer(source)
        end)
        if not ok then
            Utils.Debug('GetPlayer export failed:', player)
            return nil
        end
        return player
    end

    ---@param source number
    ---@return table|nil jobData
    function Framework.GetJob(source)
        local player = Framework.GetPlayer(source)
        if not player or not player.PlayerData or not player.PlayerData.job then
            return nil
        end
        return player.PlayerData.job
    end

    ---@param source number
    ---@param jobName string|nil
    ---@param minGrade number|nil
    ---@return boolean
    function Framework.HasMechanicJob(source, jobName, minGrade)
        local job = Framework.GetJob(source)
        if not job then return false end

        local expectedJob = jobName or (Config.Job and Config.Job.name) or 'mechanic'
        if job.name ~= expectedJob then return false end

        if Config.RequireOnDuty and job.onduty == false then
            return false
        end

        if minGrade then
            local grade = job.grade and job.grade.level or 0
            if grade < minGrade then return false end
        end

        return true
    end

    ---@param source number
    ---@param filter string|table
    ---@return boolean
    function Framework.HasGroup(source, filter)
        local ok, result = pcall(function()
            return exports[Framework.GetResourceName()]:HasGroup(source, filter)
        end)
        return ok and result == true
    end

    ---@param source number
    ---@return string|nil citizenid
    function Framework.GetCitizenId(source)
        local player = Framework.GetPlayer(source)
        if not player or not player.PlayerData then return nil end
        return player.PlayerData.citizenid
    end

    ---@param source number
    ---@return string
    function Framework.GetPlayerName(source)
        local player = Framework.GetPlayer(source)
        if not player or not player.PlayerData then return 'Inconnu' end
        return player.PlayerData.charinfo
            and ('%s %s'):format(
                player.PlayerData.charinfo.firstname or '',
                player.PlayerData.charinfo.lastname or ''
            )
            or player.PlayerData.name
            or 'Inconnu'
    end
else
    ---@return table
    function Framework.GetPlayerData()
        return QBX and QBX.PlayerData or {}
    end

    ---@return table|nil job
    function Framework.GetJob()
        local data = Framework.GetPlayerData()
        return data.job
    end

    ---@param jobName string|nil
    ---@param minGrade number|nil
    ---@return boolean
    function Framework.IsMechanic(jobName, minGrade)
        local job = Framework.GetJob()
        if not job then return false end

        local expectedJob = jobName or (Config.Job and Config.Job.name) or 'mechanic'
        if job.name ~= expectedJob then return false end

        if Config.RequireOnDuty and job.onduty == false then
            return false
        end

        if minGrade then
            local grade = job.grade and job.grade.level or 0
            if grade < minGrade then return false end
        end

        return true
    end

    ---@return number
    function Framework.GetGrade()
        local job = Framework.GetJob()
        if not job or not job.grade then return 0 end
        return job.grade.level or 0
    end
end
