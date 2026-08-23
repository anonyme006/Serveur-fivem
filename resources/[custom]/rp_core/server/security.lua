RP = RP or {}

--- Rate-limit simple anti double-call / spam events
local buckets = {}

---@param source number
---@param key string
---@param cooldownMs number
---@return boolean allowed
function RP.RateLimit(source, key, cooldownMs)
    cooldownMs = cooldownMs or 1000
    local now = GetGameTimer()
    local id = ('%s:%s'):format(source, key)
    local last = buckets[id]
    if last and (now - last) < cooldownMs then
        return false
    end
    buckets[id] = now
    return true
end

AddEventHandler('playerDropped', function()
    local src = source
    for k in pairs(buckets) do
        if k:find('^' .. src .. ':') then
            buckets[k] = nil
        end
    end
end)

--- Permission ACE helper
---@param source number
---@param ace string
---@return boolean
function RP.HasAce(source, ace)
    return IsPlayerAceAllowed(source --[[@as string]], ace) == true
end

--- Valide un joueur Qbox online
---@param source number
---@return table|nil player
function RP.GetPlayer(source)
    if type(source) ~= 'number' or source < 1 then return nil end
    return exports.qbx_core:GetPlayer(source)
end

--- Vérifie job + grade minimum
---@param source number
---@param jobName string
---@param minGrade? number
---@param requireDuty? boolean
---@return boolean
function RP.HasJob(source, jobName, minGrade, requireDuty)
    local player = RP.GetPlayer(source)
    if not player then return false end
    local job = player.PlayerData.job
    if not job or job.name ~= jobName then return false end
    if minGrade and (job.grade and job.grade.level or 0) < minGrade then return false end
    if requireDuty and not job.onduty then return false end
    return true
end

exports('RateLimit', RP.RateLimit)
exports('HasAce', RP.HasAce)
exports('GetPlayer', RP.GetPlayer)
exports('HasJob', RP.HasJob)
