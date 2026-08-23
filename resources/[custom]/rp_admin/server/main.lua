local frozen = {}

local function ensureAdmin(source)
    if not exports.rp_core:HasAce(source, Config.RequiredAce) then
        exports.rp_core:Notify(source, L('no_perm'), 'error')
        return false
    end
    return true
end

local function logAdmin(source, action, meta)
    if GetResourceState('rp_logs') == 'started' then
        exports.rp_logs:Log('admin', source, action, meta or {})
    end
end

lib.callback.register('rp_admin:isAdmin', function(source)
    return exports.rp_core:HasAce(source, Config.RequiredAce)
end)

lib.callback.register('rp_admin:getPlayers', function(source)
    if not ensureAdmin(source) then return {} end
    local list = {}
    for _, id in ipairs(GetPlayers()) do
        local src = tonumber(id)
        local player = exports.rp_core:GetPlayer(src)
        list[#list + 1] = {
            id = src,
            name = GetPlayerName(src),
            citizenid = player and player.PlayerData.citizenid or 'N/A',
        }
    end
    return list
end)

RegisterNetEvent('rp_admin:server:action', function(action, data)
    local src = source
    if not exports.rp_core:RateLimit(src, 'admin_action', 500) then return end
    if not ensureAdmin(src) then return end
    if not Config.Actions[action] then return end
    data = data or {}

    if action == 'kick' then
        local target = tonumber(data.target)
        if not target then return end
        logAdmin(src, 'kick', { target = target, reason = data.reason })
        DropPlayer(target, data.reason or 'Expulsé par un administrateur')
        exports.rp_core:Notify(src, L('kicked'), 'success')
        return
    end

    if action == 'ban' then
        local target = tonumber(data.target)
        if not target then return end
        local reason = data.reason or 'Ban admin'
        -- qbx_core ExploitBan or custom table
        MySQL.insert.await(
            'INSERT INTO rp_bans (license, reason, banned_by, expire) VALUES (?, ?, ?, ?)',
            {
                GetPlayerIdentifierByType(target --[[@as string]], 'license'),
                reason,
                GetPlayerIdentifierByType(src --[[@as string]], 'license'),
                data.expire or 0,
            }
        )
        logAdmin(src, 'ban', { target = target, reason = reason })
        DropPlayer(target, 'Banni : ' .. reason)
        exports.rp_core:Notify(src, L('banned'), 'success')
        return
    end

    if action == 'unban' then
        if type(data.license) ~= 'string' then return end
        MySQL.update.await('DELETE FROM rp_bans WHERE license = ?', { data.license })
        logAdmin(src, 'unban', { license = data.license })
        exports.rp_core:Notify(src, L('unbanned'), 'success')
        return
    end

    if action == 'bring' or action == 'teleport' then
        local target = tonumber(data.target)
        if not target then return end
        local pedSrc = GetPlayerPed(src)
        local pedTarget = GetPlayerPed(target)
        if pedSrc == 0 or pedTarget == 0 then return end
        if action == 'bring' then
            local coords = GetEntityCoords(pedSrc)
            SetEntityCoords(pedTarget, coords.x, coords.y, coords.z, false, false, false, false)
        else
            local coords = GetEntityCoords(pedTarget)
            SetEntityCoords(pedSrc, coords.x, coords.y, coords.z, false, false, false, false)
        end
        logAdmin(src, action, { target = target })
        return
    end

    if action == 'freeze' then
        local target = tonumber(data.target)
        if not target then return end
        frozen[target] = not frozen[target]
        TriggerClientEvent('rp_admin:client:freeze', target, frozen[target])
        logAdmin(src, 'freeze', { target = target, state = frozen[target] })
        return
    end

    if action == 'revive' or action == 'heal' then
        local target = tonumber(data.target) or src
        TriggerClientEvent('rp_admin:client:revive', target, action == 'heal')
        logAdmin(src, action, { target = target })
        return
    end

    if action == 'givemoney' then
        local target = tonumber(data.target)
        local amount = math.floor(tonumber(data.amount) or 0)
        local mtype = data.moneyType == 'cash' and 'cash' or 'bank'
        if not target or amount < 1 or amount > 10000000 then return end
        exports.rp_core:AddMoney(target, mtype, amount, 'admin_give')
        logAdmin(src, 'givemoney', { target = target, amount = amount, type = mtype })
        exports.rp_core:Notify(src, L('done'), 'success')
        return
    end

    if action == 'giveitem' then
        local target = tonumber(data.target)
        local item = data.item
        local count = math.floor(tonumber(data.count) or 1)
        if not target or type(item) ~= 'string' or count < 1 or count > 100 then return end
        exports.rp_core:AddItem(target, item, count)
        logAdmin(src, 'giveitem', { target = target, item = item, count = count })
        exports.rp_core:Notify(src, L('done'), 'success')
        return
    end

    if action == 'spawnvehicle' then
        local model = data.model
        if type(model) ~= 'string' then return end
        TriggerClientEvent('rp_admin:client:spawnVehicle', src, model)
        logAdmin(src, 'spawnvehicle', { model = model })
        return
    end

    if action == 'deletevehicle' then
        TriggerClientEvent('rp_admin:client:deleteVehicle', src)
        logAdmin(src, 'deletevehicle', {})
        return
    end

    if action == 'spectate' then
        local target = tonumber(data.target)
        if not target then return end
        TriggerClientEvent('rp_admin:client:spectate', src, target)
        logAdmin(src, 'spectate', { target = target })
    end
end)

-- Ban check on connecting
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    deferrals.defer()
    Wait(0)
    local license = GetPlayerIdentifierByType(src --[[@as string]], 'license')
    if license then
        local ban = MySQL.single.await('SELECT reason, expire FROM rp_bans WHERE license = ? LIMIT 1', { license })
        if ban then
            if ban.expire == 0 or ban.expire > os.time() then
                deferrals.done(('Banni : %s'):format(ban.reason or ''))
                return
            end
            MySQL.update.await('DELETE FROM rp_bans WHERE license = ?', { license })
        end
    end
    deferrals.done()
end)

MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `rp_bans` (
          `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
          `license` VARCHAR(80) NOT NULL,
          `reason` VARCHAR(255) NOT NULL,
          `banned_by` VARCHAR(80) DEFAULT NULL,
          `expire` BIGINT NOT NULL DEFAULT 0,
          `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`),
          UNIQUE KEY `uk_ban_license` (`license`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end)

print('[rp_admin] ready')
