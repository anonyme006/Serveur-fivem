Validator = Validator or {}

local function fail(msg)
    return false, msg
end

function Validator.IsString(value, minLen, maxLen)
    if type(value) ~= 'string' then return fail('expected_string') end
    local len = #value
    if minLen and len < minLen then return fail('string_too_short') end
    if maxLen and len > maxLen then return fail('string_too_long') end
    return true
end

function Validator.IsNumber(value, minv, maxv)
    local n = tonumber(value)
    if n == nil then return fail('expected_number') end
    if minv and n < minv then return fail('number_too_small') end
    if maxv and n > maxv then return fail('number_too_large') end
    return true, n
end

function Validator.IsBoolean(value)
    if type(value) == 'boolean' then return true, value end
    if value == 1 or value == '1' or value == 'true' then return true, true end
    if value == 0 or value == '0' or value == 'false' then return true, false end
    return fail('expected_boolean')
end

function Validator.IsCoords(value)
    if type(value) ~= 'table' then return fail('expected_coords') end
    local okx, x = Validator.IsNumber(value.x, -10000, 10000)
    local oky, y = Validator.IsNumber(value.y, -10000, 10000)
    local okz, z = Validator.IsNumber(value.z, -1000, 2000)
    if not (okx and oky and okz) then return fail('invalid_coords') end
    local w = value.w or value.heading
    if w ~= nil then
        local okw, nw = Validator.IsNumber(w, -360, 360)
        if not okw then return fail('invalid_heading') end
        return true, { x = x, y = y, z = z, w = nw }
    end
    return true, { x = x, y = y, z = z }
end

function Validator.IsArray(value, maxLen)
    if type(value) ~= 'table' then return fail('expected_array') end
    local count = #value
    if maxLen and count > maxLen then return fail('array_too_large') end
    return true, value
end

function Validator.IsEnum(value, allowed)
    for i = 1, #(allowed or {}) do
        if allowed[i] == value then return true, value end
    end
    return fail('invalid_enum')
end

function Validator.SanitizeName(name)
    name = CoreUtils.Slugify(name)
    if name == '' then return fail('invalid_name') end
    if #name > Config.Limits.name then return fail('name_too_long') end
    return true, name
end

function Validator.SanitizeLabel(label)
    if type(label) ~= 'string' then return fail('invalid_label') end
    label = CoreUtils.Trim(label)
    if label == '' then return fail('invalid_label') end
    if #label > Config.Limits.label then return fail('label_too_long') end
    return true, label
end

function Validator.JsonSizeOk(value)
    local encoded = CoreUtils.SafeJsonEncode(value)
    if not encoded then return fail('invalid_json') end
    if #encoded > Config.Limits.jsonPayload then return fail('payload_too_large') end
    return true, encoded
end

--- Generic entity payload validation for CRUD modules
function Validator.ValidateEntity(moduleName, data, isUpdate)
    if type(data) ~= 'table' then return fail('invalid_payload') end

    local out = {}
    if isUpdate then
        local okId, id = Validator.IsNumber(data.id, 1)
        if not okId then return fail('invalid_id') end
        out.id = id
    end

    local okName, name = Validator.SanitizeName(data.name or data.internal_name or '')
    if not okName then return fail(name) end
    out.name = name

    local okLabel, label = Validator.SanitizeLabel(data.label or data.name or name)
    if not okLabel then return fail(label) end
    out.label = label

    local okActive, active = Validator.IsBoolean(data.active ~= nil and data.active or true)
    if not okActive then return fail(active) end
    out.active = active and 1 or 0

    if data.coords ~= nil then
        local okc, coords = Validator.IsCoords(data.coords)
        if not okc then return fail(coords) end
        out.coords = coords
    end

    if data.data ~= nil then
        if type(data.data) ~= 'table' then return fail('invalid_data') end
        local oks, _ = Validator.JsonSizeOk(data.data)
        if not oks then return fail(_) end
        out.data = data.data
    else
        out.data = {}
    end

    out.module = moduleName
    return true, out
end
