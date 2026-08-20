--[[
    Pulse Phone — Utilitaires partagés
]]

Pulse = Pulse or {}
Pulse.Utils = {}

---@param ... any
function Pulse.Utils.Debug(...)
    if not Config.Debug then return end
    print(('[pulse-phone] %s'):format(table.concat({ ... }, ' ')))
end

---@param str string
---@param ... any
---@return string
function Pulse.Utils.Locale(str, ...)
    local locale = Locales and Locales[Config.Locale] or Locales and Locales.fr
    local text = locale and locale[str] or str
    if select('#', ...) > 0 then
        return text:format(...)
    end
    return text
end

---@param number string|number
---@return string|nil
function Pulse.Utils.NormalizeNumber(number)
    if number == nil then return nil end
    local n = tostring(number):gsub('%D', '')
    if n == '' then return nil end
    return n
end

---@param number string
---@return boolean
function Pulse.Utils.IsValidNumber(number)
    local n = Pulse.Utils.NormalizeNumber(number)
    if not n then return false end
    local len = Config.PhoneNumber.length
    if Config.PhoneNumber.prefix ~= '' then
        local prefix = Config.PhoneNumber.prefix
        if n:sub(1, #prefix) ~= prefix then return false end
        return #n == (#prefix + len)
    end
    return #n == len
end

---@param ms number
---@return fun(): boolean
function Pulse.Utils.CreateCooldown(ms)
    local last = 0
    return function()
        local now = GetGameTimer and GetGameTimer() or (os.time() * 1000)
        if now - last < ms then
            return false
        end
        last = now
        return true
    end
end

---@param tbl table
---@return table
function Pulse.Utils.DeepCopy(tbl)
    if type(tbl) ~= 'table' then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = Pulse.Utils.DeepCopy(v)
    end
    return copy
end

---@param value any
---@param min number
---@param max number
---@return number
function Pulse.Utils.Clamp(value, min, max)
    value = tonumber(value) or 0
    if value < min then return min end
    if value > max then return max end
    return value
end

-- Alias court pour i18n
function L(str, ...)
    return Pulse.Utils.Locale(str, ...)
end
