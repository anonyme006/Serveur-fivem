CoreUtils = CoreUtils or {}

local RESOURCE = GetCurrentResourceName and GetCurrentResourceName() or 'core_creator'

function CoreUtils.ResourceName()
    return RESOURCE
end

function CoreUtils.Debug(...)
    if not Config or not Config.Debug then return end
    local parts = { '[core_creator:debug]' }
    for i = 1, select('#', ...) do
        parts[#parts + 1] = tostring(select(i, ...))
    end
    print(table.concat(parts, ' '))
end

function CoreUtils.Print(...)
    local parts = { '[core_creator]' }
    for i = 1, select('#', ...) do
        parts[#parts + 1] = tostring(select(i, ...))
    end
    print(table.concat(parts, ' '))
end

function CoreUtils.IsServer()
    return IsDuplicityVersion and IsDuplicityVersion()
end

function CoreUtils.DeepCopy(value)
    if type(value) ~= 'table' then return value end
    local copy = {}
    for k, v in pairs(value) do
        copy[CoreUtils.DeepCopy(k)] = CoreUtils.DeepCopy(v)
    end
    return copy
end

function CoreUtils.Merge(a, b)
    local out = CoreUtils.DeepCopy(a or {})
    for k, v in pairs(b or {}) do
        if type(v) == 'table' and type(out[k]) == 'table' then
            out[k] = CoreUtils.Merge(out[k], v)
        else
            out[k] = CoreUtils.DeepCopy(v)
        end
    end
    return out
end

function CoreUtils.Trim(str)
    if type(str) ~= 'string' then return '' end
    return (str:gsub('^%s+', ''):gsub('%s+$', ''))
end

function CoreUtils.Clamp(n, minv, maxv)
    n = tonumber(n) or 0
    if minv and n < minv then return minv end
    if maxv and n > maxv then return maxv end
    return n
end

function CoreUtils.Round(n, decimals)
    local m = 10 ^ (decimals or 0)
    return math.floor((tonumber(n) or 0) * m + 0.5) / m
end

function CoreUtils.VecToTable(v)
    if type(v) ~= 'vector3' and type(v) ~= 'vector4' and type(v) ~= 'table' then
        return nil
    end
    return {
        x = CoreUtils.Round(v.x or v[1] or 0, 4),
        y = CoreUtils.Round(v.y or v[2] or 0, 4),
        z = CoreUtils.Round(v.z or v[3] or 0, 4),
        w = v.w or v[4],
    }
end

function CoreUtils.TableToVec3(t)
    if type(t) ~= 'table' then return nil end
    return vector3(tonumber(t.x) or 0.0, tonumber(t.y) or 0.0, tonumber(t.z) or 0.0)
end

function CoreUtils.Distance(a, b)
    if not a or not b then return 999999.0 end
    local ax, ay, az = a.x or a[1], a.y or a[2], a.z or a[3]
    local bx, by, bz = b.x or b[1], b.y or b[2], b.z or b[3]
    local dx, dy, dz = (ax - bx), (ay - by), (az - bz)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function CoreUtils.Now()
    return os.time()
end

function CoreUtils.ISODate(ts)
    ts = ts or os.time()
    return os.date('!%Y-%m-%dT%H:%M:%SZ', ts)
end

function CoreUtils.SafeJsonEncode(value)
    local ok, encoded = pcall(json.encode, value)
    if not ok then return nil, encoded end
    return encoded
end

function CoreUtils.SafeJsonDecode(str)
    if type(str) == 'table' then return str end
    if type(str) ~= 'string' or str == '' then return nil end
    local ok, decoded = pcall(json.decode, str)
    if not ok then return nil end
    return decoded
end

function CoreUtils.Slugify(str)
    str = CoreUtils.Trim(tostring(str or '')):lower()
    str = str:gsub('[^%w%s%-_]', '')
    str = str:gsub('%s+', '_')
    str = str:gsub('_+', '_')
    return str:sub(1, Config.Limits.name)
end

function CoreUtils.GenerateUid(prefix)
    prefix = prefix or 'cc'
    local rnd = math.random(100000, 999999)
    return ('%s_%s_%s'):format(prefix, tostring(os.time()), tostring(rnd))
end

function CoreUtils.TableCount(t)
    local n = 0
    for _ in pairs(t or {}) do n = n + 1 end
    return n
end

function CoreUtils.Includes(list, value)
    for i = 1, #(list or {}) do
        if list[i] == value then return true end
    end
    return false
end

function CoreUtils.ResourceStarted(name)
    return GetResourceState(name) == 'started'
end

function CoreUtils.FirstStarted(list)
    for i = 1, #(list or {}) do
        if CoreUtils.ResourceStarted(list[i]) then
            return list[i]
        end
    end
    return nil
end

function CoreUtils.NotifyClient(src, message, nType, duration)
    if CoreUtils.IsServer() then
        TriggerClientEvent('core_creator:notify', src, message, nType or 'inform', duration or 5000)
    else
        TriggerEvent('core_creator:notify', message, nType or 'inform', duration or 5000)
    end
end

math.randomseed(GetGameTimer and GetGameTimer() or (os.time() % 100000))
