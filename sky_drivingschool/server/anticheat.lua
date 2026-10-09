SkyDS = SkyDS or {}
SkyDS.AntiCheat = SkyDS.AntiCheat or {}

local buckets = {} -- [src] = { last = ms, windowStart = ms, count = n }

local function nowMs()
    return GetGameTimer()
end

---@param src number
---@param eventName string
---@return boolean allowed
function SkyDS.AntiCheat.Allow(src, eventName)
    local cfg = Config.AntiCheat or {}
    local cooldown = cfg.eventCooldownMs or 750
    local maxPerMin = cfg.maxEventsPerMinute or 60
    local t = nowMs()
    local b = buckets[src]
    if not b then
        buckets[src] = { last = t, windowStart = t, count = 1 }
        return true
    end
    if (t - b.last) < cooldown then
        SkyDS.AntiCheat.Flag(src, 'rate_cooldown', { event = eventName })
        return false
    end
    if (t - b.windowStart) > 60000 then
        b.windowStart = t
        b.count = 0
    end
    b.count = b.count + 1
    b.last = t
    if b.count > maxPerMin then
        SkyDS.AntiCheat.Flag(src, 'rate_limit', { event = eventName, count = b.count })
        return false
    end
    return true
end

---@param src number
---@param reason string
---@param details table|nil
function SkyDS.AntiCheat.Flag(src, reason, details)
    if not (Config.AntiCheat and Config.AntiCheat.logSuspicious) then return end
    local citizenid = SkyDS.Bridge.GetCitizenId(src)
    SkyDS.Debug(('AC flag src=%s cid=%s reason=%s'):format(src, citizenid or '?', reason))
    if SkyDS.DB and SkyDS.DB.Log then
        SkyDS.DB.Log(citizenid, citizenid, 'suspicious_' .. reason, details)
    end
end

AddEventHandler('playerDropped', function()
    buckets[source] = nil
end)

--- Validate that reported practical data is plausible
---@param exam table
---@param payload table
---@return boolean, string|nil
function SkyDS.AntiCheat.ValidatePracticalPayload(exam, payload)
    if type(payload) ~= 'table' then return false, 'invalid_payload' end
    if not exam or exam.type ~= 'practical' then return false, 'no_exam' end

    local score = tonumber(payload.score)
    if score ~= nil and (score < 0 or score > 100) then
        return false, 'score_range'
    end

    local errors = payload.errors
    if errors ~= nil and type(errors) ~= 'table' then
        return false, 'errors_type'
    end

    if errors and #errors > 40 then
        return false, 'too_many_errors'
    end

    local elapsed = os.time() - (exam.startedAt or os.time())
    if elapsed < 8 and payload.passed == true then
        return false, 'too_fast_pass'
    end

    local maxTime = (Config.PracticalScoring and Config.PracticalScoring.timeLimitSeconds or 600) + 120
    if elapsed > maxTime + 300 then
        return false, 'stale_exam'
    end

    return true, nil
end
