ServerValidator = ServerValidator or {}

function ServerValidator.AssertAdmin(src, moduleName)
    if not Permissions.Guard(src, moduleName) then
        return false
    end
    if not Permissions.CheckCooldown(src, 'admin:' .. (moduleName or 'all'), Config.Cooldowns.adminMutate) then
        Bridge.Notify(src, _('error.cooldown'), 'error')
        return false
    end
    return true
end

function ServerValidator.PlayerNearCoords(src, coords, maxDist)
    maxDist = maxDist or Config.Distances.interaction
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local pcoords = GetEntityCoords(ped)
    local dist = CoreUtils.Distance(pcoords, coords)
    return dist <= (maxDist + 1.5), dist
end

function ServerValidator.SanitizeImport(moduleName, payload)
    local ok, data = Validator.ValidateEntity(moduleName, payload, false)
    if not ok then return false, data end
    return true, data
end
