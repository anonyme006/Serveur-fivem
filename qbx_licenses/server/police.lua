local function notify(src, description, nType)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Permis',
        description = description,
        type = nType or 'inform',
    })
end

RegisterNetEvent('qbx_licenses:server:removePoints', function(targetId, licenseType, amount, reason)
    local src = source
    targetId = tonumber(targetId)
    amount = tonumber(amount)

    if not targetId or type(licenseType) ~= 'string' or not amount then return end
    if not LicensesCanPolice(src, Config.RemovePointsMinGrade or 0) then
        return notify(src, L('no_perm'), 'error')
    end

    local ok, msg, entry = RemovePoints(targetId, licenseType, amount, src, reason)
    if not ok then
        return notify(src, msg, 'error')
    end

    local label = Config.Licenses[licenseType].label
    local maxPoints = Licenses.MaxPoints(licenseType)
    local after = entry and entry.points or 0

    if entry and not entry.owned then
        notify(src, L('suspended', label), 'warning')
    else
        notify(src, L('points_removed', amount, label, after, maxPoints), 'success')
    end
end)

RegisterNetEvent('qbx_licenses:server:grant', function(targetId, licenseType)
    local src = source
    targetId = tonumber(targetId)
    if not targetId or type(licenseType) ~= 'string' then return end
    if not LicensesCanPolice(src, Config.GrantMinGrade or 0) then
        return notify(src, L('no_perm'), 'error')
    end

    local ok, msg = GrantLicense(targetId, licenseType, src)
    notify(src, ok and L('granted', Config.Licenses[licenseType].label, Licenses.MaxPoints(licenseType)) or msg, ok and 'success' or 'error')
end)

RegisterNetEvent('qbx_licenses:server:revoke', function(targetId, licenseType, reason)
    local src = source
    targetId = tonumber(targetId)
    if not targetId or type(licenseType) ~= 'string' then return end
    if not LicensesCanPolice(src, Config.RevokeMinGrade or 0) then
        return notify(src, L('no_perm'), 'error')
    end

    local ok, msg = RevokeLicense(targetId, licenseType, src, reason)
    notify(src, ok and L('revoked', Config.Licenses[licenseType].label) or msg, ok and 'success' or 'error')
end)

lib.callback.register('qbx_licenses:canManage', function(source)
    return {
        police = LicensesCanPolice(source, Config.RemovePointsMinGrade or 0),
        grant = LicensesCanPolice(source, Config.GrantMinGrade or 0),
        revoke = LicensesCanPolice(source, Config.RevokeMinGrade or 0),
    }
end)
