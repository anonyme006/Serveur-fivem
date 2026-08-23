---@param player table
---@param licenseType string
---@return boolean
local function hasLicense(player, licenseType)
    local licenses = player.PlayerData.metadata and player.PlayerData.metadata.licences
    if type(licenses) ~= 'table' then return false end
    return licenses[licenseType] == true
end

---@param source number
---@param licenseType string
---@return boolean
local function canManage(source, licenseType)
    local rules = Config.Issuers[licenseType]
    if not rules then return false end
    if exports.rp_core:HasAce(source, 'admin') then return true end
    local player = exports.rp_core:GetPlayer(source)
    if not player then return false end
    local job = player.PlayerData.job
    if not job then return false end
    local minGrade = rules[job.name]
    if minGrade == nil then return false end
    return (job.grade and job.grade.level or 0) >= minGrade
end

---@param targetSource number
---@param licenseType string
---@param state boolean
---@param issuerSource? number
---@return boolean, string
local function setLicense(targetSource, licenseType, state, issuerSource)
    if not Config.Licenses[licenseType] then
        return false, L('invalid')
    end
    local player = exports.rp_core:GetPlayer(targetSource)
    if not player then return false, 'player' end

    local licences = player.PlayerData.metadata.licences or {}
    if state and licences[licenseType] == true then
        return false, L('already')
    end
    if not state and not licences[licenseType] then
        return false, L('missing')
    end

    licences[licenseType] = state and true or nil
    -- normalize false removals
    if not state then licences[licenseType] = false end
    player.Functions.SetMetaData('licences', licences)

    MySQL.insert.await(
        'INSERT INTO rp_license_history (citizenid, license_type, action, issuer_citizenid) VALUES (?, ?, ?, ?)',
        {
            player.PlayerData.citizenid,
            licenseType,
            state and 'grant' or 'revoke',
            issuerSource and (exports.rp_core:GetPlayer(issuerSource) or {}).PlayerData and exports.rp_core:GetPlayer(issuerSource).PlayerData.citizenid or nil,
        }
    )

    if GetResourceState('rp_logs') == 'started' then
        exports.rp_logs:Log('admin', issuerSource or targetSource, state and 'Licence délivrée' or 'Licence retirée', {
            license = licenseType,
            target = player.PlayerData.citizenid,
        })
    end

    local label = Config.Licenses[licenseType].label
    exports.rp_core:Notify(targetSource, state and L('granted', label) or L('revoked', label), state and 'success' or 'error')
    return true, 'ok'
end

exports('HasLicense', function(source, licenseType)
    local player = exports.rp_core:GetPlayer(source)
    if not player then return false end
    return hasLicense(player, licenseType)
end)

exports('GrantLicense', function(targetSource, licenseType, issuerSource)
    return setLicense(targetSource, licenseType, true, issuerSource)
end)

exports('RevokeLicense', function(targetSource, licenseType, issuerSource)
    return setLicense(targetSource, licenseType, false, issuerSource)
end)

exports('GetLicenses', function(source)
    local player = exports.rp_core:GetPlayer(source)
    if not player then return {} end
    return player.PlayerData.metadata.licences or {}
end)

lib.callback.register('rp_licenses:getMine', function(source)
    local player = exports.rp_core:GetPlayer(source)
    if not player then return {} end
    local result = {}
    local licences = player.PlayerData.metadata.licences or {}
    for name, def in pairs(Config.Licenses) do
        result[#result + 1] = {
            name = name,
            label = def.label,
            owned = licences[name] == true,
        }
    end
    return result
end)

RegisterNetEvent('rp_licenses:server:grant', function(targetId, licenseType)
    local src = source
    if not exports.rp_core:RateLimit(src, 'license_grant', 1500) then return end
    targetId = tonumber(targetId)
    if not targetId or type(licenseType) ~= 'string' then return end
    if not canManage(src, licenseType) then
        exports.rp_core:Notify(src, L('no_perm'), 'error')
        return
    end
    local ok, msg = setLicense(targetId, licenseType, true, src)
    exports.rp_core:Notify(src, ok and L('granted', Config.Licenses[licenseType].label) or msg, ok and 'success' or 'error')
end)

RegisterNetEvent('rp_licenses:server:revoke', function(targetId, licenseType)
    local src = source
    if not exports.rp_core:RateLimit(src, 'license_revoke', 1500) then return end
    targetId = tonumber(targetId)
    if not targetId or type(licenseType) ~= 'string' then return end
    if not canManage(src, licenseType) then
        exports.rp_core:Notify(src, L('no_perm'), 'error')
        return
    end
    local ok, msg = setLicense(targetId, licenseType, false, src)
    exports.rp_core:Notify(src, ok and L('revoked', Config.Licenses[licenseType].label) or msg, ok and 'success' or 'error')
end)

MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `rp_license_history` (
          `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
          `citizenid` VARCHAR(50) NOT NULL,
          `license_type` VARCHAR(32) NOT NULL,
          `action` ENUM('grant','revoke') NOT NULL,
          `issuer_citizenid` VARCHAR(50) DEFAULT NULL,
          `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`),
          KEY `idx_license_citizen` (`citizenid`),
          KEY `idx_license_type` (`license_type`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end)

print('[rp_licenses] ready')
