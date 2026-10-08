--[[--------------------------------------------------------------------------
    Bridge permis à points — qbx_licenses (+ PATCH_qbx_idcard)
    Ne duplique pas la logique : délègue aux exports de qbx_licenses.
---------------------------------------------------------------------------]]

PoliceLicenses = PoliceLicenses or {}

---@return table|nil
local function licensesConfig()
    return Config.Integrations and Config.Integrations.licenses
end

---@return boolean
function PoliceLicenses.IsAvailable()
    local cfg = licensesConfig()
    if not cfg or cfg.enabled == false then return false end
    local resource = cfg.resource or 'qbx_licenses'
    return GetResourceState(resource) == 'started'
end

---@return string
function PoliceLicenses.ResourceName()
    local cfg = licensesConfig()
    return (cfg and cfg.resource) or 'qbx_licenses'
end

---@param source number
---@return table|nil licences map
function PoliceLicenses.GetLicenses(source)
    if not PoliceLicenses.IsAvailable() then return nil end
    local ok, result = pcall(function()
        return exports[PoliceLicenses.ResourceName()]:GetLicenses(source)
    end)
    if not ok then
        Police.Debug('GetLicenses failed:', result)
        return nil
    end
    return result
end

---@param source number
---@param licenseType string|nil
---@return table summary for UI / player info
function PoliceLicenses.BuildSummary(source, licenseType)
    local licences = PoliceLicenses.GetLicenses(source)
    if not licences then return {} end

    local summary = {}
    for name, entry in pairs(licences) do
        if not licenseType or name == licenseType then
            local owned = type(entry) == 'table' and entry.owned == true or entry == true
            local points = type(entry) == 'table' and (tonumber(entry.points) or 0) or (owned and 12 or 0)
            local valid = owned and points > 0
            summary[name] = {
                owned = owned,
                points = points,
                valid = valid,
                status = valid and 'valid' or (owned and 'suspended' or 'missing'),
            }
        end
    end
    return summary
end

---@param target number
---@param licenseType string
---@param amount number
---@param issuer number
---@param reason string|nil
---@return boolean ok
---@return string|nil message
---@return table|nil entry
function PoliceLicenses.RemovePoints(target, licenseType, amount, issuer, reason)
    if not PoliceLicenses.IsAvailable() then
        return false, 'licenses_unavailable', nil
    end

    amount = PoliceSecurity.SanitizeAmount(amount, 1, 12)
    if not amount then return false, 'invalid_points', nil end
    if type(licenseType) ~= 'string' or licenseType == '' then
        return false, 'invalid_type', nil
    end

    local ok, success, msg, entry = pcall(function()
        return exports[PoliceLicenses.ResourceName()]:RemovePoints(target, licenseType, amount, issuer, reason)
    end)

    if not ok then
        Police.Debug('RemovePoints pcall error:', success)
        return false, 'licenses_error', nil
    end

    return success == true, msg, entry
end

---@param target number
---@param licenseType string
---@param issuer number
---@return boolean, string|nil
function PoliceLicenses.Grant(target, licenseType, issuer)
    if not PoliceLicenses.IsAvailable() then return false, 'licenses_unavailable' end
    local ok, success, msg = pcall(function()
        return exports[PoliceLicenses.ResourceName()]:GrantLicense(target, licenseType, issuer)
    end)
    if not ok then return false, 'licenses_error' end
    return success == true, msg
end

---@param target number
---@param licenseType string
---@param issuer number
---@param reason string|nil
---@return boolean, string|nil
function PoliceLicenses.Revoke(target, licenseType, issuer, reason)
    if not PoliceLicenses.IsAvailable() then return false, 'licenses_unavailable' end
    local ok, success, msg = pcall(function()
        return exports[PoliceLicenses.ResourceName()]:RevokeLicense(target, licenseType, issuer, reason)
    end)
    if not ok then return false, 'licenses_error' end
    return success == true, msg
end

--- Appliqué après une amende (PHASE 7) si autoRemoveOnFine
---@param officerSrc number
---@param targetSrc number
---@param fineDef table
---@param reason string|nil
---@return boolean applied
---@return table|nil result { points, licenseType, ok, message }
function PoliceLicenses.ApplyFinePoints(officerSrc, targetSrc, fineDef, reason)
    local cfg = licensesConfig()
    if not cfg or cfg.autoRemoveOnFine == false then return false, nil end
    if not fineDef then return false, nil end

    local points = tonumber(fineDef.licensePoints) or 0
    if points <= 0 then return false, nil end

    local licenseType = fineDef.licenseType or cfg.defaultLicenseType or 'driver'
    local ok, msg, entry = PoliceLicenses.RemovePoints(
        targetSrc,
        licenseType,
        points,
        officerSrc,
        reason or fineDef.label or 'Amende police'
    )

    local officer = PoliceSecurity.GetPlayerInfo(officerSrc)
    local target = PoliceSecurity.GetPlayerInfo(targetSrc)
    if officer and officer.citizenid then
        PoliceDB.LogIncident({
            department = officer.departmentId or 'police',
            officer_citizenid = officer.citizenid,
            target_citizenid = target and target.citizenid or nil,
            type = 'license_points',
            payload = {
                licenseType = licenseType,
                points = points,
                ok = ok,
                message = msg,
                after = entry and entry.points or nil,
                reason = reason or fineDef.label,
            },
        })
    end

    return ok, {
        ok = ok,
        message = msg,
        points = points,
        licenseType = licenseType,
        entry = entry,
    }
end

--- Enrichit un snapshot joueur avec les permis (si activé)
---@param info table
---@param targetSrc number
---@return table
function PoliceLicenses.AttachToPlayerInfo(info, targetSrc)
    local cfg = licensesConfig()
    if not cfg or cfg.showInPlayerInfo == false then return info end
    if not PoliceLicenses.IsAvailable() then
        info.licenses = nil
        info.licensesAvailable = false
        return info
    end

    info.licensesAvailable = true
    info.licenses = PoliceLicenses.BuildSummary(targetSrc)
    local driver = info.licenses.driver
    if driver then
        info.driverLicense = driver
    end
    return info
end

lib.callback.register('qbx_policejob:server:getLicenses', function(source, target)
    local leo, err = PoliceSecurity.RequirePermission(source, 'licenses', true)
    if not leo then
        PoliceSecurity.NotifyLocale(source, err or 'err_no_permission', 'error')
        return nil
    end

    target = tonumber(target) or source
    if target ~= source then
        local near, nearErr = PoliceSecurity.IsNearPlayer(source, target, Config.Distances.maxServer)
        if not near then
            PoliceSecurity.NotifyLocale(source, nearErr or 'err_too_far', 'error')
            return nil
        end
    end

    if not PoliceLicenses.IsAvailable() then
        PoliceSecurity.NotifyLocale(source, 'licenses_unavailable', 'error')
        return nil
    end

    return {
        target = target,
        licenses = PoliceLicenses.BuildSummary(target),
        available = true,
    }
end)

lib.callback.register('qbx_policejob:server:licensesAvailable', function()
    return PoliceLicenses.IsAvailable()
end)

RegisterNetEvent('qbx_policejob:server:removeLicensePoints', function(targetId, licenseType, amount, reason)
    local src = source
    if not PoliceSecurity.ConsumeCooldown(src, 'license_points', Config.Cooldowns.search or 5) then
        return PoliceSecurity.NotifyLocale(src, 'err_cooldown', 'error')
    end

    local leo, err = PoliceSecurity.RequirePermission(src, 'licenses', true)
    if not leo then
        return PoliceSecurity.NotifyLocale(src, err or 'err_no_permission', 'error')
    end

    targetId = tonumber(targetId)
    if not targetId then return end

    local near, nearErr = PoliceSecurity.IsNearPlayer(src, targetId, Config.Distances.maxServer)
    if not near then
        return PoliceSecurity.NotifyLocale(src, nearErr or 'err_too_far', 'error')
    end

    local ok, msg = PoliceLicenses.RemovePoints(targetId, licenseType, amount, src, reason)
    if ok then
        PoliceSecurity.NotifyLocale(src, 'licenses_points_removed', 'success', amount, licenseType)
        PoliceDB.LogIncident({
            department = leo.departmentId or 'police',
            officer_citizenid = leo.citizenid,
            target_citizenid = (PoliceSecurity.GetPlayerInfo(targetId) or {}).citizenid,
            type = 'license_points',
            payload = { licenseType = licenseType, points = amount, reason = reason },
        })
    else
        PoliceSecurity.Notify(src, msg or Police.Locale('licenses_error'), 'error')
    end
end)

--- Hook pour PHASE 7 (amendes) — event interne serveur uniquement
AddEventHandler('qbx_policejob:server:fineIssued', function(officerSrc, targetSrc, fineDef, reason)
    if type(officerSrc) ~= 'number' or type(targetSrc) ~= 'number' then return end
    PoliceLicenses.ApplyFinePoints(officerSrc, targetSrc, fineDef, reason)
end)

exports('LicensesAvailable', PoliceLicenses.IsAvailable)
exports('GetTargetLicenses', PoliceLicenses.BuildSummary)
exports('RemoveLicensePoints', PoliceLicenses.RemovePoints)
exports('ApplyFineLicensePoints', PoliceLicenses.ApplyFinePoints)
