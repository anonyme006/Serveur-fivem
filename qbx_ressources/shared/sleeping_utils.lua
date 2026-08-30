--[[
    Utilitaires partagés — qbx_ressources
]]

SleepBodies = SleepBodies or {}

function SleepBodies.Debug(msg, ...)
    if not Config.Sleeping.Debug then return end
    local formatted = select('#', ...) > 0 and msg:format(...) or msg
    print(('^3[SleepingBodies]^0 %s'):format(formatted))
end

function SleepBodies.DecodeJson(raw)
    if type(raw) == 'table' then return raw end
    if type(raw) ~= 'string' or raw == '' then return nil end
    local ok, data = pcall(json.decode, raw)
    if ok and type(data) == 'table' then return data end
    return nil
end

function SleepBodies.EncodeJson(tbl)
    if type(tbl) ~= 'table' then return nil end
    local ok, encoded = pcall(json.encode, tbl)
    return ok and encoded or nil
end

---@param row table
---@return table|nil
function SleepBodies.NormalizeBody(row)
    if type(row) ~= 'table' or not row.citizenid then return nil end

    local appearance = row.appearance
    if type(appearance) == 'string' then
        appearance = SleepBodies.DecodeJson(appearance)
    end

    return {
        citizenid = tostring(row.citizenid),
        firstname = row.firstname,
        lastname = row.lastname,
        model = row.model,
        appearance = appearance,
        x = tonumber(row.x) or 0.0,
        y = tonumber(row.y) or 0.0,
        z = tonumber(row.z) or 0.0,
        heading = tonumber(row.heading) or 0.0,
        bucket = tonumber(row.bucket) or 0,
    }
end

function SleepBodies.DisplayName(body)
    local first = body.firstname or ''
    local last = body.lastname or ''
    local name = (first .. ' ' .. last):gsub('^%s+', ''):gsub('%s+$', '')
    if name == '' then name = body.citizenid or 'Inconnu' end
    return name
end
