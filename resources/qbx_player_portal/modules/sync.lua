PortalSync = PortalSync or {}

local function dbg(msg)
    if Config.Debug then
        print(('[qbx_player_portal:sync] %s'):format(msg))
    end
end

local function hmacSignature(timestamp, nonce, body)
    local payload = table.concat({ timestamp, nonce, body }, '.')
    return exports.qbx_player_portal:hmacSha256Hex(Config.ApiSecret, payload)
end

function PortalSync.post(path, payload, citizenid)
    if Config.ApiSecret == nil or Config.ApiSecret == '' then
        PortalDB.logSyncError('sync', citizenid, 'CONFIG', Config.Locale.configMissing, nil)
        return false, 'config'
    end

    local body = json.encode(payload or {})
    local timestamp = tostring(os.time())
    local nonce = ('%s-%s'):format(timestamp, math.random(100000, 999999))
    local signature = hmacSignature(timestamp, nonce, body)
    local url = ('%s%s'):format(Config.ApiBaseUrl:gsub('/$', ''), path)

    local p = promise.new()
    PerformHttpRequest(url, function(status, responseText)
        if status and status >= 200 and status < 300 then
            p:resolve({ ok = true, status = status, body = responseText })
        else
            PortalDB.logSyncError('sync', citizenid, 'HTTP_' .. tostring(status), responseText or 'empty', payload)
            p:resolve({ ok = false, status = status, body = responseText })
        end
    end, 'POST', body, {
        ['Content-Type'] = 'application/json',
        ['X-Portal-Timestamp'] = timestamp,
        ['X-Portal-Nonce'] = nonce,
        ['X-Portal-Signature'] = signature,
    })

    local result = Citizen.Await(p)
    dbg(('POST %s -> %s'):format(path, result.ok and 'ok' or 'fail'))
    return result.ok, result
end

function PortalSync.pushPlayerState(source, eventName)
    local player = PortalQbx.getPlayer(source)
    local snap = PortalQbx.getCharacterSnapshot(player)
    if not snap then return false end

    return PortalSync.post('/api/fivem/sync', {
        event = eventName,
        player = snap,
        serverId = source,
        at = os.time(),
    }, snap.citizenid)
end
