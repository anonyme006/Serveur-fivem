Access = {}

local function hashCode(code)
    return GetHashKey(('%s:%s'):format(Config.Server.hashPepper, tostring(code)))
end

function Access.HashCode(code)
    return tostring(hashCode(code))
end

function Access.ValidateCodeFormat(code)
    if type(code) ~= 'string' then return false end
    local len = #code
    if len < Config.Security.codeMinLength or len > Config.Security.codeMaxLength then
        return false
    end
    return code:match('^%d+$') ~= nil
end

---@param source number
---@param lab table
---@param permission string|nil
---@return boolean, string|nil reason
function Access.Can(source, lab, permission)
    if not lab then return false, 'invalid_lab' end
    if lab.sealed then return false, 'sealed' end

    local citizenid = Bridge.GetCitizenId(source)
    if not citizenid then return false, 'no_player' end

    -- Admin bypass for management inspection only when permission nil
    if Bridge.IsAdmin(source) and permission == nil then
        return true
    end

    if lab.ownership_type == 'none' then
        if permission == nil or permission == DrugLabs.Permissions.ENTER then
            -- available labs: entry for viewing/purchase handled separately
            return false, 'unowned'
        end
        return false, 'unowned'
    end

    if lab.ownership_type == 'player' then
        if lab.owner_identifier == citizenid then
            return true
        end
        local rental = Repository.GetRental(lab.id)
        if rental and rental.renter == citizenid and (rental.status == 'active' or rental.status == 'grace') then
            if rental.status == 'grace' and permission and permission ~= DrugLabs.Permissions.ENTER and permission ~= DrugLabs.Permissions.USE_STASH then
                return false, 'rental_grace'
            end
            if not permission then return true end
            return DrugLabs.HasPermissionFlag(DrugLabs.OwnerPermissions, permission), 'renter'
        end
        local member = Repository.GetMember(lab.id, citizenid)
        if member then
            if not permission then return true end
            return DrugLabs.HasPermissionFlag(member.permissions, permission), 'member'
        end
        return false, 'not_member'
    end

    if lab.ownership_type == 'gang' then
        local gangName, grade = Bridge.GetGang(source)
        if gangName and gangName == lab.owner_gang then
            local perms = Bridge.GetGangPermissions(grade)
            if not permission then return true end
            return DrugLabs.HasPermissionFlag(perms, permission), 'gang'
        end
        return false, 'wrong_gang'
    end

    if lab.ownership_type == 'admin' then
        return Bridge.IsAdmin(source), 'admin_only'
    end

    return false, 'denied'
end

---@param source number
---@param lab table
---@return boolean
function Access.CanEnter(source, lab)
    if not lab then return false end
    if lab.sealed and not Bridge.IsPolice(source) and not Bridge.IsAdmin(source) then
        return false
    end

    if lab.ownership_type == 'none' then
        return false
    end

    local ok = Access.Can(source, lab, DrugLabs.Permissions.ENTER)
    if not ok then return false end

    if lab.locked and not Bridge.IsPolice(source) and not Bridge.IsAdmin(source) then
        -- locked labs require unlock session or owner/member with enter after unlock event
        local citizenid = Bridge.GetCitizenId(source)
        return Access.HasUnlockSession(lab.id, citizenid)
    end

    return true
end

local unlockSessions = {} ---@type table<string, number> key=labId:citizenid -> expires

function Access.GrantUnlockSession(labId, citizenid, seconds)
    seconds = seconds or 300
    unlockSessions[('%s:%s'):format(labId, citizenid)] = os.time() + seconds
end

function Access.HasUnlockSession(labId, citizenid)
    local key = ('%s:%s'):format(labId, citizenid)
    local expires = unlockSessions[key]
    if not expires then return false end
    if os.time() > expires then
        unlockSessions[key] = nil
        return false
    end
    return true
end

function Access.ClearUnlockSession(labId, citizenid)
    unlockSessions[('%s:%s'):format(labId, citizenid)] = nil
end

---@param source number
---@param labId number
---@param code string
---@return boolean, string|nil
function Access.TryCode(source, labId, code)
    if not RateLimit.Check(source, 'codeAttempt') then
        return false, 'rate_limited'
    end

    local lab = Repository.Get(labId)
    if not lab then return false, 'invalid_lab' end

    local citizenid = Bridge.GetCitizenId(source)
    if not citizenid then return false, 'no_player' end

    local membershipOk = Access.Can(source, lab, DrugLabs.Permissions.ENTER)
    if not membershipOk then
        return false, 'no_access'
    end

    local attempt = MySQL.single.await(
        'SELECT * FROM drug_lab_code_attempts WHERE lab_id = ? AND citizenid = ?',
        { labId, citizenid }
    )

    if attempt and attempt.locked_until then
        local lockedUntil = attempt.locked_until
        -- oxmysql may return datetime string; compare via UNIX
        local lockedTs = MySQL.scalar.await('SELECT UNIX_TIMESTAMP(?)', { lockedUntil })
        if lockedTs and os.time() < lockedTs then
            return false, 'cooldown'
        end
    end

    if not Access.ValidateCodeFormat(code) then
        return false, 'invalid_format'
    end

    local hash = Repository.GetCodeHash(labId)
    if not hash or hash == '' then
        -- no code set: treat as unlocked session for members
        Access.GrantUnlockSession(labId, citizenid)
        return true
    end

    local ok = Access.HashCode(code) == tostring(hash)
    if ok then
        MySQL.query.await(
            'DELETE FROM drug_lab_code_attempts WHERE lab_id = ? AND citizenid = ?',
            { labId, citizenid }
        )
        Access.GrantUnlockSession(labId, citizenid)
        LogAction('code_success', { labId = labId, actor = citizenid })
        return true
    end

    local attempts = (attempt and attempt.attempts or 0) + 1
    if attempts >= Config.Security.maxCodeAttempts then
        MySQL.query.await([[
            INSERT INTO drug_lab_code_attempts (lab_id, citizenid, attempts, locked_until)
            VALUES (?, ?, ?, DATE_ADD(NOW(), INTERVAL ? SECOND))
            ON DUPLICATE KEY UPDATE attempts = VALUES(attempts), locked_until = VALUES(locked_until)
        ]], { labId, citizenid, attempts, Config.Security.codeCooldownSeconds })
        LogAction('code_lockout', { labId = labId, actor = citizenid, attempts = attempts })
        return false, 'cooldown'
    end

    MySQL.query.await([[
        INSERT INTO drug_lab_code_attempts (lab_id, citizenid, attempts, locked_until)
        VALUES (?, ?, ?, NULL)
        ON DUPLICATE KEY UPDATE attempts = VALUES(attempts)
    ]], { labId, citizenid, attempts })

    LogAction('code_fail', { labId = labId, actor = citizenid, attempts = attempts })
    return false, 'wrong_code'
end

function Access.IsAvailableForPurchase(lab)
    return lab and lab.ownership_type == 'none' and lab.enabled and not lab.sealed
end
