Permissions = Permissions or {}

local cooldowns = {}

local function aceAllowed(src, perm)
    if not perm or perm == '' then return true end
    return IsPlayerAceAllowed(src, perm) == true
end

function Permissions.HasAce(src, perm)
    return aceAllowed(src, perm)
end

function Permissions.IsAdmin(src)
    if not src or src <= 0 then return true end -- console

    local ace = Config.Permissions.ace
    local hasAce = aceAllowed(src, ace)
    local hasFw = Bridge.IsFrameworkAdmin(src)

    if Config.Permissions.aceOnly then
        return hasAce
    end
    if Config.Permissions.frameworkOnly then
        return hasFw
    end
    return hasAce or hasFw
end

function Permissions.CanUseModule(src, moduleName)
    if not Permissions.IsAdmin(src) then return false end
    if not Config.Modules[moduleName] then return false end
    local moduleAce = Config.Permissions.modules and Config.Permissions.modules[moduleName]
    if not moduleAce or moduleAce == '' then return true end
    -- Module ACE is optional elevating control: if player has admin ACE or framework admin, allow unless module ACE is denied explicitly.
    -- If module ACE is configured, require either admin ACE or module ACE.
    if aceAllowed(src, Config.Permissions.ace) then return true end
    if aceAllowed(src, moduleAce) then return true end
    return Bridge.IsFrameworkAdmin(src)
end

function Permissions.Deny(src, reason)
    Bridge.Notify(src, _('error.permission') .. (reason and (' (' .. reason .. ')') or ''), 'error')
    if Config.Logs.console then
        CoreUtils.Print(('Permission denied for %s (%s): %s'):format(GetPlayerName(src) or '?', tostring(src), reason or 'n/a'))
    end
end

function Permissions.Guard(src, moduleName)
    if not Permissions.IsAdmin(src) then
        Permissions.Deny(src, 'admin')
        return false
    end
    if moduleName and not Permissions.CanUseModule(src, moduleName) then
        Permissions.Deny(src, 'module:' .. moduleName)
        return false
    end
    return true
end

function Permissions.CheckCooldown(src, key, ms)
    ms = ms or Config.Cooldowns.adminMutate
    local bucket = cooldowns[src]
    if not bucket then
        bucket = {}
        cooldowns[src] = bucket
    end
    local now = GetGameTimer()
    local last = bucket[key] or 0
    if now - last < ms then
        return false
    end
    bucket[key] = now
    return true
end

AddEventHandler('playerDropped', function()
    local src = source
    cooldowns[src] = nil
end)

exports('IsAdmin', function(src)
    return Permissions.IsAdmin(src)
end)

exports('CanUseModule', function(src, moduleName)
    return Permissions.CanUseModule(src, moduleName)
end)
