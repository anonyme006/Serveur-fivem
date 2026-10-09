--[[--------------------------------------------------------------------------
    Permissions par département / grade
    Les checks sensibles restent serveur (server/security.lua).
---------------------------------------------------------------------------]]

Police = Police or {}

---@param permissions string[]|nil
---@param permission string
---@return boolean
local function hasPermissionFlag(permissions, permission)
    if type(permissions) ~= 'table' then return false end
    for i = 1, #permissions do
        local flag = permissions[i]
        if flag == '*' or flag == permission then
            return true
        end
    end
    return false
end

---@param jobName string|nil
---@param gradeLevel number|nil
---@return table|nil gradeConfig
function Police.GetGradeConfig(jobName, gradeLevel)
    local _, dept = Police.GetDepartmentByJob(jobName)
    if not dept or not dept.grades then return nil end
    gradeLevel = tonumber(gradeLevel) or 0
    return dept.grades[gradeLevel]
end

---@param jobName string|nil
---@param gradeLevel number|nil
---@param permission string
---@return boolean
function Police.HasPermission(jobName, gradeLevel, permission)
    if not permission or permission == '' then return false end
    local grade = Police.GetGradeConfig(jobName, gradeLevel)
    if not grade then return false end
    return hasPermissionFlag(grade.permissions, permission)
end

---@param jobName string|nil
---@param gradeLevel number|nil
---@return string
function Police.GetGradeLabel(jobName, gradeLevel)
    local grade = Police.GetGradeConfig(jobName, gradeLevel)
    if grade and grade.label then return grade.label end
    if grade and grade.name then return grade.name end
    return tostring(gradeLevel or 0)
end

---@param jobName string|nil
---@return string
function Police.GetDepartmentLabel(jobName)
    local _, dept = Police.GetDepartmentByJob(jobName)
    return (dept and (dept.shortLabel or dept.label)) or (jobName or 'N/A')
end

--- Snapshot client léger (ne jamais faire confiance pour l'auth serveur)
---@param playerData table|nil
---@return table
function Police.BuildClientSnapshot(playerData)
    playerData = playerData or {}
    local job = playerData.job or {}
    local charinfo = playerData.charinfo or {}
    local money = playerData.money or {}
    local metadata = playerData.metadata or {}
    local gradeLevel = job.grade and (job.grade.level or job.grade) or 0

    return {
        citizenid = playerData.citizenid,
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
        departmentId = select(1, Police.GetDepartmentByJob(job.name)),
        isLeo = Police.IsLeoJob(job.name),
    }
end
