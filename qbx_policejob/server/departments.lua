--[[--------------------------------------------------------------------------
    Helpers départements côté serveur (PHASE 1–2)
---------------------------------------------------------------------------]]

PoliceDepartments = PoliceDepartments or {}

---@return table[]
function PoliceDepartments.GetEnabled()
    local list = {}
    for id, dept in pairs(Config.Departments or {}) do
        if dept.enabled ~= false then
            list[#list + 1] = {
                id = id,
                label = dept.label,
                shortLabel = dept.shortLabel,
                job = dept.job,
                emergencyNumber = dept.emergencyNumber,
                radioFrequency = dept.radioFrequency,
            }
        end
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

---@param jobName string
---@return boolean
function PoliceDepartments.JobExistsInConfig(jobName)
    return Police.IsLeoJob(jobName)
end

--- Sources en service pour un job (via qbx_core)
---@param jobName string
---@return integer count
---@return integer[] sources
function PoliceDepartments.GetOnDutySources(jobName)
    local count, players = exports.qbx_core:GetDutyCountJob(jobName)
    return count or 0, players or {}
end

--- Tous les LEO en service (tous départements activés)
---@return integer[]
function PoliceDepartments.GetAllOnDutyLeo()
    local sources = {}
    local seen = {}
    for _, dept in pairs(Config.Departments or {}) do
        if dept.enabled ~= false and dept.job then
            local _, players = PoliceDepartments.GetOnDutySources(dept.job)
            for i = 1, #players do
                local src = players[i]
                if not seen[src] then
                    seen[src] = true
                    sources[#sources + 1] = src
                end
            end
        end
    end
    return sources
end

--- Vérifie que les jobs configurés existent dans qbx_core (warning only)
function PoliceDepartments.ValidateAgainstCore()
    local sharedJobs = exports.qbx_core:GetJobs and exports.qbx_core:GetJobs() or nil
    if type(sharedJobs) ~= 'table' then
        -- API alternative : certains builds n'exportent pas GetJobs
        Police.Debug('GetJobs export unavailable — skip job validation')
        return
    end

    for id, dept in pairs(Config.Departments or {}) do
        if dept.enabled ~= false then
            if not sharedJobs[dept.job] then
                print(('[qbx_policejob] WARNING: department "%s" job "%s" missing in qbx_core jobs'):format(id, dept.job))
            end
        end
    end
end

lib.callback.register('qbx_policejob:server:getDepartments', function(source)
    if not PoliceSecurity.IsPlayer(source) then return {} end
    return PoliceDepartments.GetEnabled()
end)

exports('GetEnabledDepartments', PoliceDepartments.GetEnabled)
exports('GetAllOnDutyLeo', PoliceDepartments.GetAllOnDutyLeo)
