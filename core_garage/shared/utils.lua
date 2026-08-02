--[[--------------------------------------------------------------------------
    core_garage — utilitaires partagés
---------------------------------------------------------------------------]]

GarageUtils = {}

local function getLocaleTable()
    local lang = Config.Locale or 'fr'
    return Locales[lang] or Locales['fr'] or {}
end

--- Traduction locale
---@param key string
---@param ... any
---@return string
function _(key, ...)
    local loc = getLocaleTable()
    local str = loc[key] or key
    if select('#', ...) > 0 then
        return str:format(...)
    end
    return str
end

--- Normalise une plaque (trim + upper)
---@param plate string
---@return string
function GarageUtils.NormalizePlate(plate)
    if not plate then return '' end
    return (tostring(plate):gsub('%s+', ''):upper())
end

--- Encode / decode JSON safe
---@param data any
---@return string
function GarageUtils.Encode(data)
    return json.encode(data or {})
end

---@param str string|nil
---@return table
function GarageUtils.Decode(str)
    if not str or str == '' then return {} end
    local ok, data = pcall(json.decode, str)
    if ok and type(data) == 'table' then return data end
    return {}
end

--- vec3 / vec4 depuis table ou string JSON
---@param data any
---@return vector3|nil
function GarageUtils.ToVec3(data)
    if not data then return nil end
    if type(data) == 'vector3' then return data end
    if type(data) == 'vector4' then return vec3(data.x, data.y, data.z) end
    if type(data) == 'string' then data = GarageUtils.Decode(data) end
    if type(data) == 'table' and data.x and data.y and data.z then
        return vec3(data.x + 0.0, data.y + 0.0, data.z + 0.0)
    end
    return nil
end

---@param data any
---@return vector4|nil
function GarageUtils.ToVec4(data)
    if not data then return nil end
    if type(data) == 'vector4' then return data end
    if type(data) == 'string' then data = GarageUtils.Decode(data) end
    if type(data) == 'table' and data.x and data.y and data.z then
        return vec4(data.x + 0.0, data.y + 0.0, data.z + 0.0, (data.w or data.heading or 0.0) + 0.0)
    end
    return nil
end

---@param v vector3|vector4|table
---@return table
function GarageUtils.CoordsToTable(v)
    if not v then return { x = 0.0, y = 0.0, z = 0.0 } end
    return {
        x = v.x + 0.0,
        y = v.y + 0.0,
        z = v.z + 0.0,
        w = v.w and (v.w + 0.0) or nil,
    }
end

--- Distance 2D/3D
---@param a vector3
---@param b vector3
---@return number
function GarageUtils.Dist(a, b)
    if not a or not b then return 9999.0 end
    return #(vec3(a.x, a.y, a.z) - vec3(b.x, b.y, b.z))
end

--- Statut véhicule pour NUI
---@param row table
---@return string stored|out|impound
function GarageUtils.GetStatus(row)
    if row.impound == 1 or row.impound == true then return 'impound' end
    if row.stored == 1 or row.stored == true then return 'stored' end
    return 'out'
end

--- Pourcentage santé (0-1000 → 0-100)
---@param value number
---@return number
function GarageUtils.HealthPercent(value)
    value = tonumber(value) or 1000.0
    return math.floor(math.max(0, math.min(100, (value / 1000.0) * 100)) + 0.5)
end

--- Format km
---@param mileage number
---@return string
function GarageUtils.FormatMileage(mileage)
    local km = math.floor((tonumber(mileage) or 0.0) + 0.5)
    local formatted = tostring(km):reverse():gsub('(%d%d%d)', '%1 '):reverse():gsub('^ ', '')
    return _('nui_km', formatted)
end

--- Label catégorie
---@param cat string|nil
---@return string
function GarageUtils.CategoryLabel(cat)
    if not cat or cat == '' then return Config.Categories.other or 'Autre' end
    return Config.Categories[cat] or cat
end

--- Merge tables (shallow)
---@param base table
---@param override table|nil
---@return table
function GarageUtils.Merge(base, override)
    local out = {}
    for k, v in pairs(base or {}) do out[k] = v end
    for k, v in pairs(override or {}) do out[k] = v end
    return out
end

--- Debug print
---@param ... any
function GarageUtils.Debug(...)
    if not Config.Debug then return end
    print('^3[core_garage]^7', ...)
end

--- Types de garage valides
GarageUtils.ValidTypes = {
    public = true,
    personal = true,
    company = true,
    job = true,
    impound = true,
    boat = true,
    plane = true,
    helicopter = true,
}
