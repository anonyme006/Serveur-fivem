--[[--------------------------------------------------------------------------
    Couche sécurité serveur — ne jamais faire confiance au client
---------------------------------------------------------------------------]]

PoliceSecurity = PoliceSecurity or {}

local cooldowns = {} -- [source][action] = gameTimer

---@param source number
---@return boolean
function PoliceSecurity.IsPlayer(source)
    return type(source) == 'number' and source > 0 and GetPlayerName(source) ~= nil
end

---@param source number
---@return table|nil Player qbx
function PoliceSecurity.GetPlayer(source)
    if not PoliceSecurity.IsPlayer(source) then return nil end
    return exports.qbx_core:GetPlayer(source)
end

---@param player table
---@return table info
function PoliceSecurity.GetInfo(player)
    local pd = player.PlayerData
    local job = pd.job or {}
    local charinfo = pd.charinfo or {}
    local money = pd.money or {}
    local metadata = pd.metadata or {}
    local gradeLevel = job.grade and (job.grade.level or job.grade) or 0
    local deptId, dept = Police.GetDepartmentByJob(job.name)

    return {
        source = pd.source,
        citizenid = pd.citizenid,
        firstname = charinfo.firstname or '',
        lastname = charinfo.lastname or '',
        phone = charinfo.phone or '',
        job = job.name,
        jobLabel = job.label,
        grade = gradeLevel,
        gradeName = job.grade and job.grade.name or Police.GetGradeLabel(job.name, gradeLevel),
        onduty = job.onduty == true,
        cash = money.cash or 0,
        bank = money.bank or 0,
        licences = metadata.licences or {},
        departmentId = deptId,
        department = dept,
        isLeo = dept ~= nil,
    }
end

---@param source number
---@return table|nil info
function PoliceSecurity.GetPlayerInfo(source)
    local player = PoliceSecurity.GetPlayer(source)
    if not player then return nil end
    return PoliceSecurity.GetInfo(player)
end

---@param source number
---@param requireDuty boolean|nil
---@return table|nil info
---@return string|nil errorKey
function PoliceSecurity.RequireLeo(source, requireDuty)
    local info = PoliceSecurity.GetPlayerInfo(source)
    if not info then return nil, 'err_not_loaded' end
    if not info.isLeo then return nil, 'err_not_leo' end
    if requireDuty ~= false and not info.onduty then
        return nil, 'err_not_onduty'
    end
    return info, nil
end

---@param source number
---@param permission string
---@param requireDuty boolean|nil
---@return table|nil info
---@return string|nil errorKey
function PoliceSecurity.RequirePermission(source, permission, requireDuty)
    local info, err = PoliceSecurity.RequireLeo(source, requireDuty)
    if not info then return nil, err end
    if not Police.HasPermission(info.job, info.grade, permission) then
        return nil, 'err_no_permission'
    end
    return info, nil
end

---@param source number
---@param target number
---@param maxDistance number|nil
---@return boolean
---@return string|nil errorKey
function PoliceSecurity.IsNearPlayer(source, target, maxDistance)
    if not PoliceSecurity.IsPlayer(target) then
        return false, 'err_invalid_target'
    end
    maxDistance = maxDistance or Config.Distances.maxServer
    local pedA = GetPlayerPed(source)
    local pedB = GetPlayerPed(target)
    if pedA == 0 or pedB == 0 then
        return false, 'err_invalid_target'
    end
    local dist = #(GetEntityCoords(pedA) - GetEntityCoords(pedB))
    if dist > maxDistance then
        return false, 'err_too_far'
    end
    return true, nil
end

---@param source number
---@param coords vector3|table
---@param maxDistance number|nil
---@return boolean
function PoliceSecurity.IsNearCoords(source, coords, maxDistance)
    maxDistance = maxDistance or Config.Distances.maxServer
    local ped = GetPlayerPed(source)
    if ped == 0 then return false end
    return Police.Distance(GetEntityCoords(ped), coords) <= maxDistance
end

---@param source number
---@param action string
---@param seconds number
---@return boolean allowed
function PoliceSecurity.ConsumeCooldown(source, action, seconds)
    seconds = seconds or 1
    cooldowns[source] = cooldowns[source] or {}
    local now = GetGameTimer()
    local untilTime = cooldowns[source][action] or 0
    if now < untilTime then
        return false
    end
    cooldowns[source][action] = now + math.floor(seconds * 1000)
    return true
end

---@param amount any
---@param min number|nil
---@param max number|nil
---@return number|nil
function PoliceSecurity.SanitizeAmount(amount, min, max)
    amount = tonumber(amount)
    if not amount then return nil end
    amount = math.floor(amount)
    min = min or 0
    max = max or 100000000
    if amount < min or amount > max then return nil end
    return amount
end

---@param source number
---@param message string
---@param nType string|nil
function PoliceSecurity.Notify(source, message, nType)
    exports.qbx_core:Notify(source, message, nType or 'inform', Config.Notify.duration)
end

---@param source number
---@param localeKey string
---@param nType string|nil
---@param ... any
function PoliceSecurity.NotifyLocale(source, localeKey, nType, ...)
    PoliceSecurity.Notify(source, Police.Locale(localeKey, ...), nType)
end

AddEventHandler('playerDropped', function()
    local src = source
    cooldowns[src] = nil
end)

--- Helper export pour phases suivantes
exports('RequireLeo', PoliceSecurity.RequireLeo)
exports('RequirePermission', PoliceSecurity.RequirePermission)
exports('GetPlayerInfo', PoliceSecurity.GetPlayerInfo)
