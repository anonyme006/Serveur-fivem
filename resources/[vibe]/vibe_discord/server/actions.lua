local Whitelist = {}

local function loadWhitelist()
    local raw = LoadResourceFile(GetCurrentResourceName(), Config.WhitelistFile)
    if not raw or raw == '' then
        Whitelist = {}
        return
    end
    local ok, data = pcall(json.decode, raw)
    if ok and type(data) == 'table' then
        Whitelist = data
    else
        Whitelist = {}
    end
end

local function saveWhitelist()
    SaveResourceFile(GetCurrentResourceName(), Config.WhitelistFile, json.encode(Whitelist), -1)
end

CreateThread(function()
    loadWhitelist()
end)

local function ensureOnline(id)
    local p = FindPlayerById(id)
    if not p then
        return nil, 'Joueur introuvable / hors ligne'
    end
    return p
end

function ActionKick(body)
    local p, err = ensureOnline(body.id)
    if not p then return nil, err end
    DropPlayer(p.id, ('Kick staff (%s) : %s'):format(body.staff or 'Discord', body.reason or 'Sans raison'))
    PushStaffLog('kick', p, body)
    return { ok = true, name = p.name, id = p.id }
end

function ActionBan(body)
    local license = body.license
    local name = body.license or tostring(body.id)
    local p

    if body.id then
        p = FindPlayerById(body.id)
        if p then
            license = p.license
            name = p.name
        end
    end
    if not license then
        return nil, 'License manquante'
    end

    local hours = tonumber(body.hours) or 0
    local expire = hours > 0 and (os.time() + hours * 3600) or 0
    local reason = body.reason or 'Ban Discord'

    -- Qbox / qb-core ban
    local banned = false
    if GetResourceState('qbx_core') == 'started' then
        local ok = pcall(function()
            exports.qbx_core:BanPlayer(tonumber(body.id) or 0, reason, body.staff or 'Discord')
        end)
        if ok then banned = true end
    end

    if not banned and GetResourceState('qb-core') == 'started' then
        -- fallback Drop + note fichier
        banned = false
    end

    -- Ban fichier local (toujours, pour unban / hors ligne)
    local bansRaw = LoadResourceFile(GetCurrentResourceName(), 'bans.json') or '{}'
    local bans = {}
    pcall(function() bans = json.decode(bansRaw) or {} end)
    bans[license] = {
        reason = reason,
        staff = body.staff,
        staffId = body.staffId,
        expire = expire,
        name = name,
        at = os.time(),
    }
    SaveResourceFile(GetCurrentResourceName(), 'bans.json', json.encode(bans), -1)

    if p then
        DropPlayer(p.id, ('Ban (%s) : %s'):format(hours > 0 and (hours .. 'h') or 'perm', reason))
        PushStaffLog('ban', p, body)
    else
        PushStaffLog('ban', { name = name, license = license, id = 0 }, body)
    end

    return { ok = true, name = name, license = license }
end

function ActionUnban(body)
    local license = body.license
    if not license then return nil, 'License manquante' end
    local bansRaw = LoadResourceFile(GetCurrentResourceName(), 'bans.json') or '{}'
    local bans = {}
    pcall(function() bans = json.decode(bansRaw) or {} end)
    if not bans[license] then
        return nil, 'Aucun ban pour cette license'
    end
    bans[license] = nil
    SaveResourceFile(GetCurrentResourceName(), 'bans.json', json.encode(bans), -1)
    PushStaffLog('unban', { name = license, license = license, id = 0 }, body)
    return { ok = true, license = license }
end

function ActionWarn(body)
    local p, err = ensureOnline(body.id)
    if not p then return nil, err end
    TriggerClientEvent('vibe_discord:client:warn', p.id, body.reason or 'Avertissement', body.staff or 'Staff')
    PushStaffLog('warn', p, body)
    return { ok = true, name = p.name, id = p.id }
end

function ActionAnnounce(body)
    local msg = body.message
    if not msg or msg == '' then return nil, 'Message vide' end
    TriggerClientEvent('vibe_discord:client:announce', -1, Config.AnnounceTitle, msg)
    PushStaffLog('announce', { name = 'SERVEUR', id = 0 }, body)
    return { ok = true }
end

function ActionRevive(body)
    local p, err = ensureOnline(body.id)
    if not p then return nil, err end
    TriggerClientEvent('vibe_discord:client:revive', p.id)
    -- hooks frameworks
    if GetResourceState('qbx_medical') == 'started' then
        pcall(function() TriggerClientEvent('qbx_medical:client:playerRevived', p.id) end)
    end
    if GetResourceState('hospital') == 'started' or GetResourceState('qb-ambulancejob') == 'started' then
        pcall(function() TriggerClientEvent('hospital:client:Revive', p.id) end)
    end
    PushStaffLog('revive', p, body)
    return { ok = true, name = p.name, id = p.id }
end

function ActionHeal(body)
    local p, err = ensureOnline(body.id)
    if not p then return nil, err end
    TriggerClientEvent('vibe_discord:client:heal', p.id)
    PushStaffLog('heal', p, body)
    return { ok = true, name = p.name, id = p.id }
end

function ActionGiveItem(body)
    local p, err = ensureOnline(body.id)
    if not p then return nil, err end
    local item = body.item
    local count = tonumber(body.count) or 1
    if not item then return nil, 'Item manquant' end

    if GetResourceState('ox_inventory') == 'started' then
        local ok = exports.ox_inventory:AddItem(p.id, item, count)
        if not ok then return nil, 'Impossible d\'ajouter l\'item (inventaire plein / item inconnu)' end
    else
        return nil, 'ox_inventory non démarré'
    end
    PushStaffLog('giveitem', p, body)
    return { ok = true, name = p.name, id = p.id, item = item, count = count }
end

function ActionSetJob(body)
    local p, err = ensureOnline(body.id)
    if not p then return nil, err end
    local job = body.job
    local grade = tonumber(body.grade) or 0
    if not job then return nil, 'Job manquant' end

    local done = false
    if GetResourceState('qbx_core') == 'started' then
        local ok = pcall(function()
            exports.qbx_core:SetJob(p.id, job, grade)
        end)
        done = ok
        if not done then
            ok = pcall(function()
                local player = exports.qbx_core:GetPlayer(p.id)
                if player then player.Functions.SetJob(job, grade) end
            end)
            done = ok
        end
    end
    if not done and GetResourceState('qb-core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local player = QBCore.Functions.GetPlayer(p.id)
        if player then
            player.Functions.SetJob(job, grade)
            done = true
        end
    end
    if not done and GetResourceState('es_extended') == 'started' then
        local ESX = exports['es_extended']:getSharedObject()
        local xPlayer = ESX.GetPlayerFromId(p.id)
        if xPlayer then
            xPlayer.setJob(job, grade)
            done = true
        end
    end
    if not done then return nil, 'Impossible de set le job (framework?)' end
    PushStaffLog('setjob', p, body)
    return { ok = true, name = p.name, id = p.id, job = job, grade = grade }
end

function ActionWhitelistAdd(body)
    local license = body.license
    if not license then return nil, 'License manquante' end
    Whitelist[license] = {
        note = body.note or '',
        staff = body.staff,
        at = os.time(),
    }
    saveWhitelist()
    PushStaffLog('whitelist_add', { name = license, license = license, id = 0 }, body)
    return { ok = true, license = license }
end

function ActionWhitelistRemove(body)
    local license = body.license
    if not license then return nil, 'License manquante' end
    Whitelist[license] = nil
    saveWhitelist()
    PushStaffLog('whitelist_remove', { name = license, license = license, id = 0 }, body)
    return { ok = true, license = license }
end

function ActionWhitelistList()
    local entries = {}
    for license, meta in pairs(Whitelist) do
        entries[#entries + 1] = {
            license = license,
            note = meta.note,
            staff = meta.staff,
            at = meta.at,
        }
    end
    table.sort(entries, function(a, b) return (a.at or 0) > (b.at or 0) end)
    return { ok = true, entries = entries }
end

function IsBanned(license)
    if not license then return false end
    local bansRaw = LoadResourceFile(GetCurrentResourceName(), 'bans.json') or '{}'
    local bans = {}
    pcall(function() bans = json.decode(bansRaw) or {} end)
    local b = bans[license]
    if not b then return false end
    if b.expire and b.expire > 0 and b.expire < os.time() then
        bans[license] = nil
        SaveResourceFile(GetCurrentResourceName(), 'bans.json', json.encode(bans), -1)
        return false
    end
    return true, b.reason or 'Ban'
end

function IsWhitelisted(license)
    if not Config.WhitelistEnabled then return true end
    return Whitelist[license] ~= nil
end

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    deferrals.defer()
    Wait(0)
    deferrals.update('Vérification Discord bridge…')

    local license = GetPlayerLicense(src)
    local banned, reason = IsBanned(license)
    if banned then
        deferrals.done(('Tu es banni : %s'):format(reason))
        return
    end
    if Config.WhitelistEnabled and not IsWhitelisted(license) then
        deferrals.done(('Pas whitelist.\nTa license : %s\nPasse sur Discord.'):format(license or 'inconnue'))
        return
    end
    deferrals.done()
end)
