Duty = Duty or {}

local DEFAULT_ON = { sprite = 1, color = 2, scale = 0.70 }
local DEFAULT_OFF = { sprite = 1, color = 1, scale = 0.65 }

---@param jobName string|nil
---@return table|nil
function Duty.GetJobConfig(jobName)
    if not jobName or jobName == '' or jobName == 'unemployed' then return nil end
    local cfg = Config.Jobs[jobName]
    if not cfg or cfg.enabled == false then return nil end
    return cfg
end

---@param jobName string|nil
---@return boolean
function Duty.IsJobEnabled(jobName)
    return Duty.GetJobConfig(jobName) ~= nil
end

---@param jobName string|nil
---@return boolean
function Duty.JobHasDuty(jobName)
    local cfg = Duty.GetJobConfig(jobName)
    return cfg ~= nil and cfg.duty ~= false
end

---@param jobName string|nil
---@return boolean
function Duty.JobHasBlips(jobName)
    local cfg = Duty.GetJobConfig(jobName)
    return cfg ~= nil and cfg.blips ~= false
end

---@param jobName string|nil
---@param onDuty boolean
---@return table
function Duty.GetBlipStyle(jobName, onDuty)
    local cfg = Duty.GetJobConfig(jobName)
    local base = onDuty and DEFAULT_ON or DEFAULT_OFF
    if not cfg then return base end
    local style = onDuty and (cfg.onDuty or {}) or (cfg.offDuty or {})
    return {
        sprite = style.sprite or base.sprite,
        color = style.color or base.color,
        scale = style.scale or base.scale,
    }
end

---@param jobName string|nil
---@return string
function Duty.GetJobLabel(jobName)
    local cfg = Duty.GetJobConfig(jobName)
    return (cfg and cfg.label) or (jobName or 'Inconnu')
end

---@param jobName string|nil
---@return boolean
function Duty.ShowOffDuty(jobName)
    local cfg = Duty.GetJobConfig(jobName)
    if not cfg then return false end
    if cfg.showOffDuty == nil then return true end
    return cfg.showOffDuty == true
end

---@param jobName string|nil
---@return boolean
function Duty.ShowPlayerName(jobName)
    if Config.Blips and Config.Blips.showPlayerName == false then return false end
    local cfg = Duty.GetJobConfig(jobName)
    if cfg and cfg.showPlayerName ~= nil then
        return cfg.showPlayerName == true
    end
    return Config.Blips.showPlayerName ~= false
end

---@param viewerJob string|nil
---@param targetJob string|nil
---@param targetOnDuty boolean
---@return boolean
function Duty.CanViewerSeeJob(viewerJob, targetJob, targetOnDuty)
    if not Duty.JobHasBlips(targetJob) then return false end
    if not targetOnDuty and not Duty.ShowOffDuty(targetJob) then return false end

    local rules = Config.Visibility and Config.Visibility[targetJob]
    if not rules then
        return viewerJob == targetJob
    end
    return rules[viewerJob] == true
end

---@param name string
---@param jobName string
---@param onDuty boolean
---@return string
function Duty.FormatBlipName(name, jobName, onDuty)
    local label = Duty.GetJobLabel(jobName)
    if not Duty.ShowPlayerName(jobName) then
        return label
    end
    local status = onDuty and 'En service' or 'Hors service'
    return ('%s | %s | %s'):format(name or '?', label, status)
end
