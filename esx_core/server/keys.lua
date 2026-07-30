if not Config.Keys.enabled then return end

local function isExpired(row)
    if tonumber(row.temporary) ~= 1 or not row.expires_at then
        return false
    end
    return tostring(row.expires_at) < os.date('!%Y-%m-%d %H:%M:%S', os.time())
end

local function hasKey(identifier, keyType, keyRef)
    keyRef = keyType == 'vehicle' and Core.NormalizePlate(keyRef) or tostring(keyRef)
    local rows = MySQL.query.await(
        'SELECT * FROM esx_core_keys WHERE holder = ? AND key_type = ? AND key_ref = ?',
        { identifier, keyType, keyRef }
    ) or {}

    for _, row in ipairs(rows) do
        if not isExpired(row) then
            return true, row
        end
    end

    -- Propriétaire ESX du véhicule = clé implicite
    if keyType == 'vehicle' then
        local cols = Config.Persistence.columns
        local owned = MySQL.single.await(
            ('SELECT 1 FROM `%s` WHERE `%s` = ? AND REPLACE(`%s`, " ", "") = ? LIMIT 1'):format(
                cols.table, cols.owner, cols.plate
            ),
            { identifier, keyRef }
        )
        if owned then return true, { owner = identifier, holder = identifier, implicit = true } end
    end

    return false, nil
end

function Core.HasKey(identifier, keyType, keyRef)
    local ok = hasKey(identifier, keyType, keyRef)
    return ok
end

exports('HasKey', function(src, keyType, keyRef)
    local id = Core.GetIdentifier(src)
    if not id then return false end
    return Core.HasKey(id, keyType, keyRef)
end)

exports('GiveKey', function(holderIdentifier, keyType, keyRef, ownerIdentifier, label, temporary, minutes)
    keyRef = keyType == 'vehicle' and Core.NormalizePlate(keyRef) or tostring(keyRef)
    local expires = nil
    if temporary then
        minutes = math.max(1, math.min(tonumber(minutes) or 60, Config.Keys.maxTempMinutes))
        expires = os.date('!%Y-%m-%d %H:%M:%S', os.time() + minutes * 60)
    end

    return MySQL.insert.await(
        'INSERT INTO esx_core_keys (owner, holder, key_type, key_ref, label, temporary, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
        {
            ownerIdentifier or holderIdentifier,
            holderIdentifier,
            keyType,
            keyRef,
            label,
            temporary and 1 or 0,
            expires,
        }
    )
end)

--- Donner une clé véhicule au propriétaire à l'achat (hook concessionnaire)
AddEventHandler('esx_core:keys:giveVehicleKey', function(src, plate, label)
    local id = Core.GetIdentifier(src)
    if not id or not plate then return end
    plate = Core.NormalizePlate(plate)

    local exists = MySQL.single.await(
        'SELECT id FROM esx_core_keys WHERE holder = ? AND key_type = ? AND key_ref = ? AND temporary = 0 LIMIT 1',
        { id, 'vehicle', plate }
    )
    if exists then return end

    MySQL.insert.await(
        'INSERT INTO esx_core_keys (owner, holder, key_type, key_ref, label, temporary) VALUES (?, ?, ?, ?, ?, 0)',
        { id, id, 'vehicle', plate, label or plate }
    )
end)

lib.callback.register('esx_core:keys:canLock', function(source, plate)
    local id = Core.GetIdentifier(source)
    if not id then return false end
    return hasKey(id, 'vehicle', plate)
end)

lib.callback.register('esx_core:keys:canHouse', function(source, houseId)
    local id = Core.GetIdentifier(source)
    if not id then return false end
    return hasKey(id, 'house', houseId)
end)

lib.callback.register('esx_core:keys:list', function(source)
    local id = Core.GetIdentifier(source)
    if not id then return {} end

    local rows = MySQL.query.await(
        'SELECT id, key_type, key_ref, label, temporary, expires_at, owner FROM esx_core_keys WHERE holder = ?',
        { id }
    ) or {}

    local list = {}
    for _, row in ipairs(rows) do
        if not isExpired(row) then
            list[#list + 1] = {
                id = row.id,
                type = row.key_type,
                ref = row.key_ref,
                label = row.label or row.key_ref,
                temporary = tonumber(row.temporary) == 1,
                isOwner = row.owner == id,
            }
        end
    end

    -- Ajoute les véhicules owned sans entrée clés explicite
    local cols = Config.Persistence.columns
    local owned = MySQL.query.await(
        ('SELECT `%s` AS plate FROM `%s` WHERE `%s` = ?'):format(cols.plate, cols.table, cols.owner),
        { id }
    ) or {}

    local seen = {}
    for _, k in ipairs(list) do
        if k.type == 'vehicle' then seen[Core.NormalizePlate(k.ref)] = true end
    end

    for _, row in ipairs(owned) do
        local p = Core.NormalizePlate(row.plate)
        if not seen[p] then
            list[#list + 1] = {
                id = nil,
                type = 'vehicle',
                ref = p,
                label = p,
                temporary = false,
                isOwner = true,
                implicit = true,
            }
        end
    end

    table.sort(list, function(a, b)
        if a.type == b.type then return (a.label or '') < (b.label or '') end
        return a.type < b.type
    end)

    return list
end)

RegisterNetEvent('esx_core:keys:give', function(targetId, keyType, keyRef, temporary, minutes)
    local src = source
    local xPlayer = Core.GetPlayer(src)
    local target = Core.GetPlayer(tonumber(targetId))
    if not xPlayer or not target then return end

    keyType = keyType == 'house' and 'house' or 'vehicle'
    keyRef = keyType == 'vehicle' and Core.NormalizePlate(keyRef) or tostring(keyRef)

    local ok = hasKey(xPlayer.identifier, keyType, keyRef)
    if not ok then
        TriggerClientEvent('esx_core:notify', src, Core.Locale('key_no_key'), 'error')
        return
    end

    -- Seul le propriétaire peut donner une clé permanente ; temp ok pour détenteur
    local cols = Config.Persistence.columns
    local isOwner = false
    if keyType == 'vehicle' then
        local owned = MySQL.single.await(
            ('SELECT 1 FROM `%s` WHERE `%s` = ? AND REPLACE(`%s`, " ", "") = ? LIMIT 1'):format(
                cols.table, cols.owner, cols.plate
            ),
            { xPlayer.identifier, keyRef }
        )
        isOwner = owned ~= nil
    else
        local row = MySQL.single.await(
            'SELECT 1 FROM esx_core_keys WHERE owner = ? AND key_type = ? AND key_ref = ? LIMIT 1',
            { xPlayer.identifier, keyType, keyRef }
        )
        isOwner = row ~= nil
    end

    if not temporary and not isOwner then
        temporary = true
        minutes = minutes or 60
    end

    local expires = nil
    if temporary then
        minutes = math.max(1, math.min(tonumber(minutes) or 60, Config.Keys.maxTempMinutes))
        expires = os.date('!%Y-%m-%d %H:%M:%S', os.time() + minutes * 60)
    end

    MySQL.insert.await(
        'INSERT INTO esx_core_keys (owner, holder, key_type, key_ref, label, temporary, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
        {
            xPlayer.identifier,
            target.identifier,
            keyType,
            keyRef,
            keyRef,
            temporary and 1 or 0,
            expires,
        }
    )

    TriggerClientEvent('esx_core:notify', src, Core.Locale('key_given', keyRef), 'success')
    TriggerClientEvent('esx_core:notify', target.source, Core.Locale('key_received', keyRef), 'inform')
end)

RegisterNetEvent('esx_core:keys:remove', function(keyId)
    local src = source
    local xPlayer = Core.GetPlayer(src)
    if not xPlayer then return end

    keyId = tonumber(keyId)
    if not keyId then return end

    local row = MySQL.single.await('SELECT * FROM esx_core_keys WHERE id = ? LIMIT 1', { keyId })
    if not row then return end

    -- Propriétaire peut retirer n'importe quelle clé ; détenteur peut jeter la sienne
    if row.owner ~= xPlayer.identifier and row.holder ~= xPlayer.identifier then
        return
    end

    MySQL.update.await('DELETE FROM esx_core_keys WHERE id = ?', { keyId })
    TriggerClientEvent('esx_core:notify', src, Core.Locale('key_removed'), 'success')
end)

RegisterNetEvent('esx_core:keys:setLock', function(netId, plate, locking)
    local src = source
    local id = Core.GetIdentifier(src)
    if not id then return end
    plate = Core.NormalizePlate(plate)
    if not hasKey(id, 'vehicle', plate) then
        TriggerClientEvent('esx_core:notify', src, Core.Locale('key_no_key'), 'error')
        return
    end
    TriggerClientEvent('esx_core:keys:applyLock', -1, netId, locking and true or false, plate, src)
end)

RegisterNetEvent('esx_core:keys:toggleHouse', function(houseId, locked)
    local src = source
    local id = Core.GetIdentifier(src)
    if not id then return end
    houseId = tostring(houseId or '')
    if not hasKey(id, 'house', houseId) then
        TriggerClientEvent('esx_core:notify', src, Core.Locale('key_house_no_key'), 'error')
        return
    end
    TriggerClientEvent('esx_core:keys:setHouseLock', -1, houseId, locked and true or false)
    TriggerClientEvent(
        'esx_core:notify',
        src,
        locked and Core.Locale('key_house_locked') or Core.Locale('key_house_unlocked'),
        'inform'
    )
end)

--- Création clé habitation (export pour housing)
exports('GiveHouseKey', function(holderSrc, houseId, label, ownerIdentifier)
    local holder = Core.GetIdentifier(holderSrc)
    if not holder or not houseId then return false end
    MySQL.insert.await(
        'INSERT INTO esx_core_keys (owner, holder, key_type, key_ref, label, temporary) VALUES (?, ?, ?, ?, ?, 0)',
        { ownerIdentifier or holder, holder, 'house', tostring(houseId), label or tostring(houseId) }
    )
    return true
end)

exports('RegisterHouseDoor', function(houseId, coords, locked)
    TriggerClientEvent('esx_core:keys:registerHouse', -1, houseId, coords, locked ~= false)
end)
