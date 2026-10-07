--[[
    Bridge optionnel pour qbx_idcard / um-idcard
    Enrichit les données de carte avec les points de permis (live).
]]

---@param src number
---@param data table
---@return table
local function attachLicensePoints(src, data)
    if type(data) ~= 'table' then return data end

    local licences = GetPlayerLicenses(src) or {}
    local points = {}
    for name, def in pairs(Config.Licenses) do
        local entry = licences[name] or { owned = false, points = 0 }
        points[name] = {
            label = def.label,
            points = entry.points or 0,
            maxPoints = Licenses.MaxPoints(name),
            owned = entry.owned == true,
            valid = Licenses.IsValid(entry),
        }
    end

    data.licensePoints = points

    local driver = points.driver
    if driver then
        data.driverPoints = driver.points
        data.driverMaxPoints = driver.maxPoints
        data.driverStatus = driver.valid and 'Valide' or (driver.owned and 'Suspendu' or 'Non détenu')
    end

    return data
end

exports('EnrichCardData', function(src, data)
    return attachLicensePoints(src, data)
end)

print('[qbx_licenses] bridge carte prêt (exports.qbx_licenses:EnrichCardData)')
