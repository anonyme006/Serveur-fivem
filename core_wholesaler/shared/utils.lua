--[[
    Shared utilities — core_wholesaler
]]

Wholesaler = Wholesaler or {}

--- Translate a locale key
---@param key string
---@param ... any
---@return string
function _(key, ...)
    local lang = Config.Locale or 'fr'
    local str = (Locales[lang] and Locales[lang][key]) or (Locales['en'] and Locales['en'][key]) or key
    if select('#', ...) > 0 then
        return str:format(...)
    end
    return str
end

--- Round to nearest integer
---@param n number
---@return integer
function Wholesaler.Round(n)
    return math.floor(n + 0.5)
end

--- Calculate taxes on a subtotal (HT)
---@param subtotal number
---@return number tax, number vat, number total
function Wholesaler.CalcTaxes(subtotal)
    local tax, vat = 0, 0
    if Config.Tax.enabled then
        tax = Wholesaler.Round(subtotal * (Config.Tax.companyTax or 0))
        vat = Wholesaler.Round(subtotal * (Config.Tax.vatRate or 0))
    end
    return tax, vat, subtotal + tax + vat
end

--- Find product definition by item name in Config
---@param item string
---@return table|nil product, string|nil category
function Wholesaler.GetProductConfig(item)
    for catId, cat in pairs(Config.Categories) do
        for _, product in ipairs(cat.products) do
            if product.item == item then
                return product, catId
            end
        end
    end
    return nil, nil
end

--- Check if a job can access a category
---@param job string
---@param category string
---@return boolean
function Wholesaler.CanAccessCategory(job, category)
    local allowed = Config.AllowedCompanies[job]
    if not allowed then return false end
    if allowed == '*' then return true end
    for _, cat in ipairs(allowed) do
        if cat == category then return true end
    end
    return false
end

--- Check if job is in a list
---@param job string
---@param list string[]
---@return boolean
function Wholesaler.JobInList(job, list)
    for _, j in ipairs(list) do
        if j == job then return true end
    end
    return false
end

--- Format money
---@param amount number
---@return string
function Wholesaler.FormatMoney(amount)
    local formatted = tostring(Wholesaler.Round(amount))
    local k
    while true do
        formatted, k = formatted:gsub('^(-?%d+)(%d%d%d)', '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

--- Debug print
---@param ... any
function Wholesaler.Debug(...)
    if Config.Debug then
        print('[core_wholesaler]', ...)
    end
end

--- ox_inventory image URL helper
---@param image string|nil
---@param item string
---@return string
function Wholesaler.ItemImage(image, item)
    local name = image or item
    return ('nui://ox_inventory/web/images/%s.png'):format(name)
end

--- Status label from locale
---@param status string
---@return string
function Wholesaler.StatusLabel(status)
    return _('status_' .. status) or status
end
