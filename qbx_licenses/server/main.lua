local function getPlayer(src)
    return exports.qbx_core:GetPlayer(src)
end

local function notify(src, description, nType)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Permis',
        description = description,
        type = nType or 'inform',
    })
end

---@param player table
---@return table
local function readLicences(player)
    return Licenses.NormalizeAll(player.PlayerData.metadata and player.PlayerData.metadata.licences)
end

---@param player table
---@param licences table
local function writeLicences(player, licences)
    player.Functions.SetMetaData('licences', licences)
end

---@param src number
---@return boolean
local function isAdmin(src)
    return IsPlayerAceAllowed(src, Config.AdminAce or 'qbx_licenses.admin')
        or IsPlayerAceAllowed(src, 'admin')
        or IsPlayerAceAllowed(src, 'command')
end

---@param player table
---@return boolean, integer|nil job grade
local function getPoliceGrade(player)
    local job = player.PlayerData.job
    if not job or not job.name then return false, nil end

    local minGrade = Config.PoliceJobs[job.name]
    if minGrade == nil then return false, nil end

    if Config.RequireOnDuty and job.onduty == false then
        return false, nil
    end

    local grade = job.grade and (job.grade.level or job.grade) or 0
    if type(grade) == 'table' then grade = grade.level or 0 end
    grade = tonumber(grade) or 0

    if grade < minGrade then return false, nil end
    return true, grade
end

---@param src number
---@param minGrade number
---@return boolean
function LicensesCanPolice(src, minGrade)
    if isAdmin(src) then return true end
    local player = getPlayer(src)
    if not player then return false end
    local ok, grade = getPoliceGrade(player)
    if not ok then return false end
    return grade >= (minGrade or 0)
end

---@param src number
---@param itemName string|nil
---@param licenseType string
---@param entry table
local function syncItemMetadata(src, itemName, licenseType, entry)
    if not Config.SyncItemMetadata or not itemName then return end
    if GetResourceState('ox_inventory') ~= 'started' then return end

    local items = exports.ox_inventory:Search(src, 'slots', itemName)
    if not items then return end

    for _, item in pairs(items) do
        if item and item.slot then
            local meta = item.metadata or {}
            meta.licenseType = licenseType
            meta.points = entry.points or 0
            meta.maxPoints = Licenses.MaxPoints(licenseType)
            meta.owned = entry.owned == true
            meta.status = Licenses.IsValid(entry) and 'Valide'
                or (entry.owned and 'Suspendu' or 'Invalide')
            meta.description = ('%s — %s/%s pts'):format(
                Config.Licenses[licenseType].label,
                entry.points or 0,
                Licenses.MaxPoints(licenseType)
            )
            exports.ox_inventory:SetMetadata(src, item.slot, meta)
        end
    end
end

---@param src number
---@param licences table
local function syncAllItems(src, licences)
    for name, def in pairs(Config.Licenses) do
        syncItemMetadata(src, def.item, name, licences[name] or { owned = false, points = 0 })
    end
end

---@param citizenid string
---@param licenseType string
---@param action string
---@param pointsBefore number|nil
---@param pointsAfter number|nil
---@param amount number|nil
---@param issuerCitizenid string|nil
---@param reason string|nil
local function logHistory(citizenid, licenseType, action, pointsBefore, pointsAfter, amount, issuerCitizenid, reason)
    MySQL.insert.await(
        [[INSERT INTO qbx_license_history
          (citizenid, license_type, action, points_before, points_after, amount, issuer_citizenid, reason)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?)]],
        {
            citizenid,
            licenseType,
            action,
            pointsBefore,
            pointsAfter,
            amount,
            issuerCitizenid,
            reason,
        }
    )
end

---@param targetSrc number
---@param licenseType string
---@param issuerSrc number|nil
---@return boolean, string
function GrantLicense(targetSrc, licenseType, issuerSrc)
    if not Config.Licenses[licenseType] then return false, L('invalid_type') end

    local player = getPlayer(targetSrc)
    if not player then return false, L('no_player') end

    local licences = readLicences(player)
    local entry = licences[licenseType]
    if entry.owned and Licenses.IsValid(entry) then
        return false, L('already_owned')
    end

    local maxPoints = Licenses.MaxPoints(licenseType)
    local before = entry.points
    licences[licenseType] = { owned = true, points = maxPoints }
    writeLicences(player, licences)
    syncItemMetadata(targetSrc, Config.Licenses[licenseType].item, licenseType, licences[licenseType])

    local issuerCid = nil
    if issuerSrc then
        local issuer = getPlayer(issuerSrc)
        issuerCid = issuer and issuer.PlayerData.citizenid or nil
    end

    logHistory(player.PlayerData.citizenid, licenseType, 'grant', before, maxPoints, maxPoints, issuerCid, nil)

    notify(targetSrc, L('granted', Config.Licenses[licenseType].label, maxPoints), 'success')
    return true, 'ok'
end

---@param targetSrc number
---@param licenseType string
---@param issuerSrc number|nil
---@param reason string|nil
---@return boolean, string
function RevokeLicense(targetSrc, licenseType, issuerSrc, reason)
    if not Config.Licenses[licenseType] then return false, L('invalid_type') end

    local player = getPlayer(targetSrc)
    if not player then return false, L('no_player') end

    local licences = readLicences(player)
    local entry = licences[licenseType]
    if not entry.owned then
        return false, L('not_owned')
    end

    local before = entry.points
    licences[licenseType] = { owned = false, points = 0 }
    writeLicences(player, licences)
    syncItemMetadata(targetSrc, Config.Licenses[licenseType].item, licenseType, licences[licenseType])

    local issuerCid = nil
    if issuerSrc then
        local issuer = getPlayer(issuerSrc)
        issuerCid = issuer and issuer.PlayerData.citizenid or nil
    end

    logHistory(player.PlayerData.citizenid, licenseType, 'revoke', before, 0, before, issuerCid, reason)

    notify(targetSrc, L('revoked', Config.Licenses[licenseType].label), 'error')
    return true, 'ok'
end

---@param targetSrc number
---@param licenseType string
---@param amount number
---@param issuerSrc number|nil
---@param reason string|nil
---@return boolean, string, table|nil
function RemovePoints(targetSrc, licenseType, amount, issuerSrc, reason)
    if not Config.Licenses[licenseType] then return false, L('invalid_type') end

    amount = math.floor(tonumber(amount) or 0)
    if amount < 1 then return false, L('invalid_points') end

    local player = getPlayer(targetSrc)
    if not player then return false, L('no_player') end

    local licences = readLicences(player)
    local entry = licences[licenseType]
    if not entry.owned then
        return false, L('not_owned')
    end

    local maxPoints = Licenses.MaxPoints(licenseType)
    local before = entry.points
    local after = math.max(0, before - amount)
    licences[licenseType] = { owned = true, points = after }

    local suspended = false
    if after <= 0 and Config.RevokeAtZero then
        licences[licenseType] = { owned = false, points = 0 }
        suspended = true
    end

    writeLicences(player, licences)
    syncItemMetadata(targetSrc, Config.Licenses[licenseType].item, licenseType, licences[licenseType])

    local issuerCid = nil
    if issuerSrc then
        local issuer = getPlayer(issuerSrc)
        issuerCid = issuer and issuer.PlayerData.citizenid or nil
    end

    logHistory(
        player.PlayerData.citizenid,
        licenseType,
        suspended and 'suspend' or 'remove_points',
        before,
        licences[licenseType].points,
        amount,
        issuerCid,
        reason
    )

    local label = Config.Licenses[licenseType].label
    if Config.NotifyTarget then
        if suspended then
            notify(targetSrc, L('suspended_self', label), 'error')
        else
            notify(targetSrc, L('points_removed_self', amount, label, after, maxPoints), 'error')
        end
    end

    -- Rafraîchir la carte ouverte chez les observateurs proches
    TriggerClientEvent('qbx_licenses:client:pointsUpdated', -1, targetSrc, licenseType, licences[licenseType])

    return true, 'ok', licences[licenseType]
end

---@param targetSrc number
---@param licenseType string
---@param points number
---@param issuerSrc number|nil
---@return boolean, string
function SetPoints(targetSrc, licenseType, points, issuerSrc)
    if not Config.Licenses[licenseType] then return false, L('invalid_type') end

    local player = getPlayer(targetSrc)
    if not player then return false, L('no_player') end

    local maxPoints = Licenses.MaxPoints(licenseType)
    points = math.max(0, math.min(maxPoints, math.floor(tonumber(points) or 0)))

    local licences = readLicences(player)
    local before = licences[licenseType].points
    local owned = points > 0 or licences[licenseType].owned

    if Config.RevokeAtZero and points <= 0 then
        owned = false
    elseif points > 0 then
        owned = true
    end

    licences[licenseType] = { owned = owned, points = owned and points or 0 }
    writeLicences(player, licences)
    syncItemMetadata(targetSrc, Config.Licenses[licenseType].item, licenseType, licences[licenseType])

    local issuerCid = nil
    if issuerSrc then
        local issuer = getPlayer(issuerSrc)
        issuerCid = issuer and issuer.PlayerData.citizenid or nil
    end

    logHistory(player.PlayerData.citizenid, licenseType, 'set_points', before, licences[licenseType].points, points, issuerCid, nil)
    notify(targetSrc, L('points_set', Config.Licenses[licenseType].label, licences[licenseType].points, maxPoints), 'inform')
    TriggerClientEvent('qbx_licenses:client:pointsUpdated', -1, targetSrc, licenseType, licences[licenseType])
    return true, 'ok'
end

---@param src number
---@return table
function GetPlayerLicenses(src)
    local player = getPlayer(src)
    if not player then return {} end
    return readLicences(player)
end

---@param src number
---@param licenseType string
---@return boolean
function HasValidLicense(src, licenseType)
    local player = getPlayer(src)
    if not player then return false end
    local licences = readLicences(player)
    return Licenses.IsValid(licences[licenseType])
end

-- Exports
exports('GrantLicense', GrantLicense)
exports('RevokeLicense', RevokeLicense)
exports('RemovePoints', RemovePoints)
exports('SetPoints', SetPoints)
exports('GetLicenses', GetPlayerLicenses)
exports('HasLicense', HasValidLicense)
exports('HasValidLicense', HasValidLicense)
exports('CanPolice', LicensesCanPolice)

lib.callback.register('qbx_licenses:getMine', function(source)
    local licences = GetPlayerLicenses(source)
    local list = {}
    for name, def in pairs(Config.Licenses) do
        local entry = licences[name] or { owned = false, points = 0 }
        list[#list + 1] = {
            name = name,
            label = def.label,
            short = def.short,
            icon = def.icon,
            color = def.cardColor,
            owned = entry.owned == true,
            points = entry.points or 0,
            maxPoints = Licenses.MaxPoints(name),
            valid = Licenses.IsValid(entry),
        }
    end
    table.sort(list, function(a, b) return a.label < b.label end)
    return list
end)

lib.callback.register('qbx_licenses:getTarget', function(source, targetId)
    if not LicensesCanPolice(source, Config.RemovePointsMinGrade or 0) then
        return nil
    end
    targetId = tonumber(targetId)
    if not targetId then return nil end

    local licences = GetPlayerLicenses(targetId)
    local target = getPlayer(targetId)
    local list = {}
    for name, def in pairs(Config.Licenses) do
        local entry = licences[name] or { owned = false, points = 0 }
        list[#list + 1] = {
            name = name,
            label = def.label,
            short = def.short,
            icon = def.icon,
            owned = entry.owned == true,
            points = entry.points or 0,
            maxPoints = Licenses.MaxPoints(name),
            valid = Licenses.IsValid(entry),
        }
    end
    table.sort(list, function(a, b) return a.label < b.label end)

    return {
        serverId = targetId,
        name = target and (target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname) or ('#' .. targetId),
        citizenid = target and target.PlayerData.citizenid or nil,
        licenses = list,
    }
end)

lib.callback.register('qbx_licenses:getCardData', function(source, targetId)
    targetId = tonumber(targetId) or source
    local player = getPlayer(targetId)
    if not player then return nil end

    local charinfo = player.PlayerData.charinfo or {}
    local licences = GetPlayerLicenses(targetId)
    local list = {}
    for name, def in pairs(Config.Licenses) do
        local entry = licences[name] or { owned = false, points = 0 }
        list[#list + 1] = {
            name = name,
            label = def.label,
            short = def.short,
            color = def.cardColor,
            owned = entry.owned == true,
            points = entry.points or 0,
            maxPoints = Licenses.MaxPoints(name),
            valid = Licenses.IsValid(entry),
            status = Licenses.IsValid(entry) and 'Valide'
                or (entry.owned and 'Suspendu' or 'Non détenu'),
        }
    end
    table.sort(list, function(a, b) return a.label < b.label end)

    return {
        firstname = charinfo.firstname or '',
        lastname = charinfo.lastname or '',
        birthdate = charinfo.birthdate or '',
        sex = (charinfo.gender == 0 or charinfo.gender == 'm') and 'H' or 'F',
        nationality = charinfo.nationality or 'USA',
        citizenid = player.PlayerData.citizenid,
        licenses = list,
    }
end)

-- Commands
local function registerCommands()
    local cmds = Config.Commands or {}

    if cmds.mylicenses then
        lib.addCommand(cmds.mylicenses, {
            help = 'Afficher / ouvrir ta carte de permis',
        }, function(source)
            TriggerClientEvent('qbx_licenses:client:showCard', source, source)
        end)
    end

    if cmds.grant then
        lib.addCommand(cmds.grant, {
            help = 'Délivrer un permis (police)',
            params = {
                { name = 'id', type = 'playerId', help = 'ID joueur' },
                { name = 'type', type = 'string', help = 'driver|motorcycle|boat|aircraft' },
            },
        }, function(source, args)
            if not LicensesCanPolice(source, Config.GrantMinGrade or 0) then
                return notify(source, L('no_perm'), 'error')
            end
            local ok, msg = GrantLicense(args.id, args.type, source)
            notify(source, ok and L('granted', Config.Licenses[args.type].label, Licenses.MaxPoints(args.type)) or msg, ok and 'success' or 'error')
        end)
    end

    if cmds.revoke then
        lib.addCommand(cmds.revoke, {
            help = 'Révoquer un permis (police)',
            params = {
                { name = 'id', type = 'playerId', help = 'ID joueur' },
                { name = 'type', type = 'string', help = 'driver|motorcycle|boat|aircraft' },
            },
        }, function(source, args)
            if not LicensesCanPolice(source, Config.RevokeMinGrade or 0) then
                return notify(source, L('no_perm'), 'error')
            end
            local ok, msg = RevokeLicense(args.id, args.type, source)
            notify(source, ok and L('revoked', Config.Licenses[args.type].label) or msg, ok and 'success' or 'error')
        end)
    end

    if cmds.setpoints then
        lib.addCommand(cmds.setpoints, {
            help = 'Définir les points d\'un permis (admin/police)',
            params = {
                { name = 'id', type = 'playerId', help = 'ID joueur' },
                { name = 'type', type = 'string', help = 'driver|motorcycle|boat|aircraft' },
                { name = 'points', type = 'number', help = 'Points' },
            },
        }, function(source, args)
            if not LicensesCanPolice(source, Config.RemovePointsMinGrade or 0) then
                return notify(source, L('no_perm'), 'error')
            end
            local ok, msg = SetPoints(args.id, args.type, args.points, source)
            notify(source, ok and L('points_set', Config.Licenses[args.type].label, args.points, Licenses.MaxPoints(args.type)) or msg, ok and 'success' or 'error')
        end)
    end
end

-- Migrate boolean licences → points on load
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    local player = getPlayer(src)
    if not player then return end
    local raw = player.PlayerData.metadata and player.PlayerData.metadata.licences
    local normalised = Licenses.NormalizeAll(raw)
    writeLicences(player, normalised)
    syncAllItems(src, normalised)
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    if not player or not player.PlayerData then return end
    local src = player.PlayerData.source
    local normalised = Licenses.NormalizeAll(player.PlayerData.metadata and player.PlayerData.metadata.licences)
    writeLicences(player, normalised)
    if src then syncAllItems(src, normalised) end
end)

MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `qbx_license_history` (
          `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
          `citizenid` VARCHAR(50) NOT NULL,
          `license_type` VARCHAR(32) NOT NULL,
          `action` VARCHAR(32) NOT NULL,
          `points_before` INT DEFAULT NULL,
          `points_after` INT DEFAULT NULL,
          `amount` INT DEFAULT NULL,
          `issuer_citizenid` VARCHAR(50) DEFAULT NULL,
          `reason` VARCHAR(255) DEFAULT NULL,
          `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`),
          KEY `idx_qbx_lic_citizen` (`citizenid`),
          KEY `idx_qbx_lic_type` (`license_type`),
          KEY `idx_qbx_lic_action` (`action`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end)

registerCommands()

print('[qbx_licenses] ready — permis à points voiture/moto/bateau/avion')
