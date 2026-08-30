local function jsonResponse(res, code, obj)
    res.writeHead(code, { ['Content-Type'] = 'application/json' })
    res.send(json.encode(obj))
end

local function auth(req)
    local headers = req.headers or {}
    local secret = headers['x-bridge-secret'] or headers['X-Bridge-Secret']
    return secret and secret == Config.BridgeSecret
end

--- Normalise le chemin : /vibe_discord/status → status
local function pathOf(req)
    local p = (req.path or ''):lower()
    p = p:gsub('^/+', '')
    -- retire le nom de ressource s'il est présent
    local resName = GetCurrentResourceName():lower()
    if p:sub(1, #resName) == resName then
        p = p:sub(#resName + 1):gsub('^/+', '')
    end
    local prefix = (Config.HttpPath or ''):lower():gsub('^/+', '')
    if prefix ~= '' and p:sub(1, #prefix) == prefix then
        p = p:sub(#prefix + 1):gsub('^/+', '')
    end
    return p
end

local function parseBody(raw)
    if not raw or raw == '' then return {} end
    local ok, data = pcall(json.decode, raw)
    if ok and type(data) == 'table' then return data end
    return {}
end

local routes = {}

routes['status'] = function(_, res)
    local players = GetOnlinePlayers()
    jsonResponse(res, 200, {
        ok = true,
        count = #players,
        max = GetConvarInt('sv_maxclients', 48),
        uptime = FormatUptime(),
        framework = Framework,
        players = players,
    })
end

routes['players'] = function(_, res)
    jsonResponse(res, 200, { ok = true, players = GetOnlinePlayers() })
end

routes['kick'] = function(body, res)
    local result, err = ActionKick(body)
    if not result then return jsonResponse(res, 400, { error = err }) end
    jsonResponse(res, 200, result)
end

routes['ban'] = function(body, res)
    local result, err = ActionBan(body)
    if not result then return jsonResponse(res, 400, { error = err }) end
    jsonResponse(res, 200, result)
end

routes['unban'] = function(body, res)
    local result, err = ActionUnban(body)
    if not result then return jsonResponse(res, 400, { error = err }) end
    jsonResponse(res, 200, result)
end

routes['warn'] = function(body, res)
    local result, err = ActionWarn(body)
    if not result then return jsonResponse(res, 400, { error = err }) end
    jsonResponse(res, 200, result)
end

routes['announce'] = function(body, res)
    local result, err = ActionAnnounce(body)
    if not result then return jsonResponse(res, 400, { error = err }) end
    jsonResponse(res, 200, result)
end

routes['revive'] = function(body, res)
    local result, err = ActionRevive(body)
    if not result then return jsonResponse(res, 400, { error = err }) end
    jsonResponse(res, 200, result)
end

routes['heal'] = function(body, res)
    local result, err = ActionHeal(body)
    if not result then return jsonResponse(res, 400, { error = err }) end
    jsonResponse(res, 200, result)
end

routes['giveitem'] = function(body, res)
    local result, err = ActionGiveItem(body)
    if not result then return jsonResponse(res, 400, { error = err }) end
    jsonResponse(res, 200, result)
end

routes['setjob'] = function(body, res)
    local result, err = ActionSetJob(body)
    if not result then return jsonResponse(res, 400, { error = err }) end
    jsonResponse(res, 200, result)
end

routes['whitelist'] = function(_, res)
    jsonResponse(res, 200, ActionWhitelistList())
end

routes['whitelist/add'] = function(body, res)
    local result, err = ActionWhitelistAdd(body)
    if not result then return jsonResponse(res, 400, { error = err }) end
    jsonResponse(res, 200, result)
end

routes['whitelist/remove'] = function(body, res)
    local result, err = ActionWhitelistRemove(body)
    if not result then return jsonResponse(res, 400, { error = err }) end
    jsonResponse(res, 200, result)
end

local function dispatch(req, res, body)
    if not auth(req) then
        return jsonResponse(res, 401, { error = 'unauthorized' })
    end

    local route = pathOf(req)
    if route == '' or route == 'health' then
        return jsonResponse(res, 200, { ok = true, resource = GetCurrentResourceName() })
    end

    local handler = routes[route]
    if not handler then
        return jsonResponse(res, 404, { error = 'unknown_route', path = route })
    end

    local ok, err = pcall(handler, body or {}, res)
    if not ok then
        print(('[vibe_discord] HTTP error on %s: %s'):format(route, tostring(err)))
        jsonResponse(res, 500, { error = 'internal_error' })
    end
end

SetHttpHandler(function(req, res)
    local method = (req.method or 'GET'):upper()
    if method == 'POST' or method == 'PUT' or method == 'PATCH' then
        req.setDataHandler(function(raw)
            dispatch(req, res, parseBody(raw))
        end)
    else
        dispatch(req, res, {})
    end
end)

print(('[vibe_discord] HTTP bridge → http://IP:30120/%s/status'):format(GetCurrentResourceName()))
