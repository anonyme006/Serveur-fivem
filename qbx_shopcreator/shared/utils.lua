ShopCreator = ShopCreator or {}

---@param value any
---@return boolean
function ShopCreator.IsPositiveInt(value)
    local n = tonumber(value)
    return n ~= nil and n == math.floor(n) and n > 0
end

---@param value any
---@return boolean
function ShopCreator.IsNonNegInt(value)
    local n = tonumber(value)
    return n ~= nil and n == math.floor(n) and n >= 0
end

---@param value any
---@param min number
---@param max number
---@return number|nil
function ShopCreator.ClampInt(value, min, max)
    local n = tonumber(value)
    if not n then return nil end
    n = math.floor(n)
    if n < min or n > max then return nil end
    return n
end

---@param str any
---@param maxLen? number
---@return string|nil
function ShopCreator.SanitizeString(str, maxLen)
    if type(str) ~= 'string' then return nil end
    str = str:gsub('[%z\1-\8\11\12\14-\31]', '')
    str = str:match('^%s*(.-)%s*$') or ''
    if str == '' then return nil end
    maxLen = maxLen or 128
    if #str > maxLen then
        str = str:sub(1, maxLen)
    end
    return str
end

---@param item any
---@return string|nil
function ShopCreator.SanitizeItemName(item)
    if type(item) ~= 'string' then return nil end
    item = item:lower():match('^%s*(.-)%s*$') or ''
    if item == '' or not item:match('^[%w_]+$') then return nil end
    if #item > 64 then return nil end
    return item
end

---@param openHour number
---@param closeHour number
---@param hour number
---@param minute number
---@return boolean
function ShopCreator.IsWithinHours(openHour, closeHour, hour, minute)
    openHour = tonumber(openHour) or 0
    closeHour = tonumber(closeHour) or 0
    hour = tonumber(hour) or 0
    minute = tonumber(minute) or 0

    local now = hour * 60 + minute
    local openMin = math.floor(openHour) * 60 + math.floor((openHour % 1) * 60)
    local closeMin = math.floor(closeHour) * 60 + math.floor((closeHour % 1) * 60)

    -- Support whole-hour integers stored as 0-23
    if openHour == math.floor(openHour) then openMin = openHour * 60 end
    if closeHour == math.floor(closeHour) then closeMin = closeHour * 60 end

    if openMin == closeMin then
        return true -- 24h
    end

    if openMin < closeMin then
        return now >= openMin and now < closeMin
    end

    -- Crosses midnight e.g. 22:00 -> 06:00
    return now >= openMin or now < closeMin
end

---@param hours string|number HH:MM or hour number
---@return number hourFloat
function ShopCreator.ParseHour(hours)
    if type(hours) == 'number' then
        return hours
    end
    if type(hours) ~= 'string' then
        return 0
    end
    local h, m = hours:match('^(%d%d?):(%d%d)$')
    if not h then
        return tonumber(hours) or 0
    end
    return tonumber(h) + (tonumber(m) or 0) / 60
end

---@param shop table
---@param hour? number
---@param minute? number
---@return boolean
function ShopCreator.IsShopOpen(shop, hour, minute)
    if not shop or shop.enabled == false or shop.enabled == 0 then
        return false
    end

    if shop.manual_status ~= nil then
        if shop.manual_status == true or shop.manual_status == 1 or shop.manual_status == 'open' then
            -- fall through to schedule if auto hours also enabled
        elseif shop.manual_status == false or shop.manual_status == 0 or shop.manual_status == 'closed' then
            if not shop.auto_hours then
                return false
            end
        end
    end

    if shop.is_open == false or shop.is_open == 0 then
        return false
    end

    if shop.auto_hours then
        hour = hour or tonumber(os.date('%H'))
        minute = minute or tonumber(os.date('%M'))
        return ShopCreator.IsWithinHours(shop.open_hour or 8, shop.close_hour or 22, hour, minute)
    end

    return shop.is_open == true or shop.is_open == 1
end

---@param coords table|{x:number,y:number,z:number}
---@param other table|{x:number,y:number,z:number}
---@return number
function ShopCreator.Distance(coords, other)
    local dx = (coords.x or coords[1]) - (other.x or other[1])
    local dy = (coords.y or coords[2]) - (other.y or other[2])
    local dz = (coords.z or coords[3]) - (other.z or other[3])
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

---@param permissions table|string|nil
---@return table
function ShopCreator.NormalizePermissions(permissions)
    local base = {}
    for k, v in pairs(ShopCreator.DefaultPermissions) do
        base[k] = v
    end

    if type(permissions) == 'string' and permissions ~= '' then
        local ok, decoded = pcall(json.decode, permissions)
        if ok and type(decoded) == 'table' then
            permissions = decoded
        else
            permissions = {}
        end
    end

    if type(permissions) == 'table' then
        for k in pairs(ShopCreator.DefaultPermissions) do
            if permissions[k] ~= nil then
                base[k] = permissions[k] and true or false
            end
        end
    end

    return base
end

---@param tbl table
---@return table
function ShopCreator.DeepCopy(tbl)
    if type(tbl) ~= 'table' then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = type(v) == 'table' and ShopCreator.DeepCopy(v) or v
    end
    return copy
end

---@param label string
---@return string
function ShopCreator.Slugify(label)
    label = tostring(label or 'shop'):lower()
    label = label:gsub('[^%w]+', '_'):gsub('^_+', ''):gsub('_+$', '')
    if label == '' then label = 'shop' end
    return label:sub(1, 40)
end