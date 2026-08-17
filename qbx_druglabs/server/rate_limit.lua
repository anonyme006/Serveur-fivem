RateLimit = {}

local buckets = {}

---@param source number
---@param key string
---@param max number
---@param window number seconds
---@return boolean allowed
function RateLimit.Allow(source, key, max, window)
    source = tonumber(source)
    if not source then return false end
    max = max or 5
    window = window or 10

    local now = os.time()
    local bucketKey = ('%s:%s'):format(source, key)
    local bucket = buckets[bucketKey]

    if not bucket or now >= bucket.resetAt then
        buckets[bucketKey] = { count = 1, resetAt = now + window }
        return true
    end

    if bucket.count >= max then
        return false
    end

    bucket.count += 1
    return true
end

---@param source number
---@param category string
---@return boolean
function RateLimit.Check(source, category)
    local cfg = Config.RateLimit[category]
    if not cfg then return true end
    local ok = RateLimit.Allow(source, category, cfg.max, cfg.window)
    if not ok then
        DrugLabs.Debug('Rate limited', source, category)
        LogAction('rate_limit', { actor = Bridge.GetCitizenId(source), category = category, source = source })
    end
    return ok
end

AddEventHandler('playerDropped', function()
    local src = source
    for key in pairs(buckets) do
        if key:find(('^%s:'):format(src)) then
            buckets[key] = nil
        end
    end
end)
