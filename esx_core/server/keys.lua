if not Config.Keys.enabled then return end

local function isExpired(row)
    if tonumber(row.temporary) ~= 1 or not row.expires_at then
        return false
    end
    return tostring(row.expires_at) < os.date('!%Y-%m-%d %H:%M:%S', os.time())
end

local function hasKey(identifier, keyType, keyRef, src)
    keyRef = keyType == 'vehicle' and Core.NormalizePlate(keyRef) or tostring(keyRef)

    -- Item inventaire (prioritaire pour les véhicules)
    if keyType == 'vehicle' and src and Core.Inventory and Core.Inventory.Enabled() then
        if Core.Inventory.HasVehicleKey(src, keyRef) then
            return true, { inventory = true }
        end
    end

    local rows = MySQL.query.await(
        'SELECT * FROM esx_core_keys WHERE holder = ? AND key_type = ? AND key_ref = ?',
        { identifier, keyType, keyRef }
    ) or {}

    for _, row in ipairs(rows) do
        if not isExpired(row) then
            return true, row
        end
    end

    -- Propriétaire ESX = clé implicite (désactivable si requireItemToLock)
    local invCfg = Config.Keys.inventory or {}
    local requireItem = invCfg.enabled ~= false and invCfg.requireItemToLock
    if keyType == 'vehicle' and not requireItem then
        local cols = Config.Persistence.columns
        local owned = MySQL.single.await(
            ('SELECT 1 FROM `%s` WHERE `%s` = ? AND REPLACE(UPPER(`%s`), " ", "") = ? LIMIT 1'):format(
                cols.table, cols.owner, cols.plate
            ),
            { identifier, keyRef }
        )
        if owned then return true, { owner = identifier, holder = identifier, implicit = true } end
    end

    return false, nil
end

function Core.HasKey(identifier, keyType, keyRef, src)
    local ok = hasKey(identifier, keyType, keyRef, src)
    return ok
end

exports('HasKey', function(src, keyType, keyRef)
    local id = Core.GetIdentifier(src)
    if not id then return false end
    return Core.HasKey(id, keyType, keyRef, src)
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

--- Crée une clé permanente si absente. Retourne true si créée, false si déjà présente / échec.
---@param src number
---@param plate string
---@param label? string
---@param notifyKey? string locale key (key_received, key_garage, key_purchase)
---@return boolean created
function Core.EnsureVehicleKey(src, plate, label, notifyKey)
    local id = Core.GetIdentifier(src)
    if not id or not plate then return false end

    plate = Core.NormalizePlate(plate)
    if plate == '' then return false end

    -- Sécurité : uniquement le propriétaire ESX
    local cols = Config.Persistence.columns
    local owned = MySQL.single.await(
        ('SELECT 1 FROM `%s` WHERE `%s` = ? AND REPLACE(UPPER(`%s`), " ", "") = ? LIMIT 1'):format(
            cols.table, cols.owner, cols.plate
        ),
        { id, plate }
    )
    if not owned then return false end

    local exists = MySQL.single.await(
        'SELECT id FROM esx_core_keys WHERE holder = ? AND key_type = ? AND key_ref = ? AND temporary = 0 LIMIT 1',
        { id, 'vehicle', plate }
    )

    local created = false
    if not exists then
        MySQL.insert.await(
            'INSERT INTO esx_core_keys (owner, holder, key_type, key_ref, label, temporary) VALUES (?, ?, ?, ?, ?, 0)',
            { id, id, 'vehicle', plate, label or plate }
        )
        created = true
    end

    -- Item inventaire
    local invCfg = Config.Keys.inventory or {}
    local gaveItem = false
    if Core.Inventory and Core.Inventory.Enabled() then
        if notifyKey == 'key_shop' then
            -- Serrurier : toujours une nouvelle copie item
            gaveItem = Core.Inventory.AddVehicleKey(src, plate, label or plate, 1)
            if gaveItem then created = true end
        else
            local wantItem = false
            if notifyKey == 'key_purchase' and invCfg.giveItemOnPurchase ~= false then
                wantItem = true
            elseif notifyKey == 'key_garage' and invCfg.giveMissingOnGarage then
                wantItem = true
            elseif not notifyKey and invCfg.giveItemOnPurchase ~= false then
                wantItem = true
            end

            if wantItem and not Core.Inventory.HasVehicleKey(src, plate) then
                gaveItem = Core.Inventory.AddVehicleKey(src, plate, label or plate, 1)
                if gaveItem then created = true end
            end
        end
    end

    if Config.Keys.notifyOnGive and notifyKey then
        TriggerClientEvent(
            'esx_core:notify',
            src,
            Core.Locale(notifyKey, plate),
            created and 'success' or 'inform'
        )
    elseif Config.Keys.notifyOnGive and created then
        TriggerClientEvent('esx_core:notify', src, Core.Locale('key_received', plate), 'success')
    end

    return created or gaveItem
end

--- Donner une clé véhicule au propriétaire (hook concessionnaire / exports)
AddEventHandler('esx_core:keys:giveVehicleKey', function(src, plate, label)
    Core.EnsureVehicleKey(src, plate, label, 'key_purchase')
end)

exports('GiveVehicleKey', function(src, plate, label)
    return Core.EnsureVehicleKey(src, plate, label, 'key_purchase')
end)

exports('EnsureVehicleKey', function(src, plate, label, notifyKey)
    return Core.EnsureVehicleKey(src, plate, label, notifyKey)
end)

-- ESX usable item (serveur)
CreateThread(function()
    Wait(1000)
    if not Config.Keys or not Config.Keys.enabled then return end
    if not (Config.Keys.inventory and Config.Keys.inventory.enabled ~= false) then return end

    local item = Config.Keys.inventory.item or 'vehicle_key'
    local ESX = exports['es_extended']:getSharedObject()
    if ESX and ESX.RegisterUsableItem then
        ESX.RegisterUsableItem(item, function(playerId)
            TriggerClientEvent('esx_core:keys:useItem', playerId)
        end)
    end
end)

lib.callback.register('esx_core:keys:canLock', function(source, plate)
    local id = Core.GetIdentifier(source)
    if not id then return false end
    return hasKey(id, 'vehicle', plate, source)
end)

lib.callback.register('esx_core:keys:canHouse', function(source, houseId)
    local id = Core.GetIdentifier(source)
    if not id then return false end
    return hasKey(id, 'house', houseId, source)
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

    local ok = hasKey(xPlayer.identifier, keyType, keyRef, src)
    if not ok then
        TriggerClientEvent('esx_core:notify', src, Core.Locale('key_no_key'), 'error')
        return
    end

    -- Seul le propriétaire peut donner une clé permanente ; temp ok pour détenteur
    local cols = Config.Persistence.columns
    local isOwner = false
    if keyType == 'vehicle' then
        local owned = MySQL.single.await(
            ('SELECT 1 FROM `%s` WHERE `%s` = ? AND REPLACE(UPPER(`%s`), " ", "") = ? LIMIT 1'):format(
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

    -- Donne aussi l'item inventaire au destinataire (véhicule)
    if keyType == 'vehicle' and Core.Inventory and Core.Inventory.Enabled() then
        Core.Inventory.AddVehicleKey(target.source, keyRef, keyRef, 1)
    end

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
    if not hasKey(id, 'vehicle', plate, src) then
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
    if not hasKey(id, 'house', houseId, src) then
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
