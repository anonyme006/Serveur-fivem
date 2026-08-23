RP = RP or {}
RP.Utils = {}

---@param msg string
function RP.Utils.Debug(msg)
    if Config and Config.Debug then
        print(('[rp_core] %s'):format(msg))
    end
end

---@param value any
---@return boolean
function RP.Utils.IsString(value)
    return type(value) == 'string' and value ~= ''
end

---@param value any
---@return boolean
function RP.Utils.IsPositiveNumber(value)
    return type(value) == 'number' and value > 0 and value == value -- not NaN
end

---@param amount any
---@return integer|nil
function RP.Utils.SanitizeMoney(amount)
    local n = tonumber(amount)
    if not n or n ~= n or n < 0 then return nil end
    if n > 1000000000 then return nil end
    return math.floor(n)
end

---@param source number
---@param coords vector3
---@param maxDist number
---@return boolean
function RP.Utils.IsNearCoords(source, coords, maxDist)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false end
    local pcoords = GetEntityCoords(ped)
    return #(pcoords - coords) <= (maxDist or 5.0)
end

---@param tbl table
---@return table
function RP.Utils.DeepCopy(tbl)
    if type(tbl) ~= 'table' then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = RP.Utils.DeepCopy(v)
    end
    return copy
end
