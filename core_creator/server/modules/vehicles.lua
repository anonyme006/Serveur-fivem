local MODULE = 'vehicles'
local spawnedPlates = {} -- plate -> netId tracking to prevent double spawn abuse

CoreCreator.RegisterModule(MODULE, {})

local function normalizePlate(plate)
    return string.upper((tostring(plate or ''):gsub('%s+', '')))
end

local function generatePlate()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    for _ = 1, 30 do
        local plate = ''
        for i = 1, 8 do
            local idx = math.random(1, #chars)
            plate = plate .. chars:sub(idx, idx)
        end
        local exists = MySQL.scalar.await('SELECT 1 FROM core_creator_vehicle_keys WHERE plate = ? LIMIT 1', { plate })
        if not exists then return plate end
    end
    return normalizePlate(('CC%06d'):format(math.random(0, 999999)))
end

local function giveExternalKeys(src, plate, model)
    local system = Bridge.Keys
    if system == 'wasabi_carlock' then
        pcall(function() exports['wasabi_carlock']:GiveKey(src, plate) end)
    elseif system == 'qs-vehiclekeys' then
        pcall(function() exports['qs-vehiclekeys']:GiveKeys(src, plate, model) end)
    elseif system == 'qb-vehiclekeys' or system == 'qbx_vehiclekeys' then
        TriggerClientEvent('vehiclekeys:client:SetOwner', src, plate)
    end
end

RegisterNetEvent('core_creator:vehicles:create', function(payload)
    local src = source
    if not Permissions.Guard(src, 'vehicles') then return end
    if type(payload) ~= 'table' then return end

    local model = tostring(payload.model or '')
    if model == '' or #model > 40 then return end

    local plate = normalizePlate(payload.plate ~= '' and payload.plate or generatePlate())
    if #plate < 1 or #plate > 8 then
        Bridge.Notify(src, 'Plaque invalide', 'error')
        return
    end

    local targetSrc = tonumber(payload.target) or src
    local owner = Bridge.GetIdentifier(targetSrc)
    if not owner then return end

    local props = {
        model = joaat(model),
        modelName = model,
        plate = plate,
        color1 = tonumber(payload.color1) or 0,
        color2 = tonumber(payload.color2) or 0,
        mods = payload.mods or {},
    }

    Bridge.InsertOwnedVehicle(owner, plate, props, payload.type or 'car', payload.stored ~= false)

    MySQL.insert.await(
        'INSERT INTO core_creator_vehicle_keys (plate, owner, holder, temporary, meta) VALUES (?, ?, ?, ?, ?)',
        { plate, owner, owner, 0, json.encode({ model = model }) }
    )

    giveExternalKeys(targetSrc, plate, model)

    if payload.spawn and payload.coords then
        TriggerClientEvent('core_creator:vehicles:spawn', targetSrc, {
            model = model,
            plate = plate,
            coords = payload.coords,
            heading = payload.coords.w or payload.heading or 0.0,
            props = props,
        })
    end

    Bridge.Notify(src, ('Véhicule %s créé (%s)'):format(model, plate), 'success')
    Logger.Log(src, 'vehicle_create', MODULE, nil, { plate = plate, model = model, owner = owner })
end)

RegisterNetEvent('core_creator:vehicles:giveKey', function(plate, targetId, temporary, minutes)
    local src = source
    if not Permissions.Guard(src, 'vehicles') then return end
    plate = normalizePlate(plate)
    targetId = tonumber(targetId)
    if plate == '' or not targetId then return end

    local holder = Bridge.GetIdentifier(targetId)
    local ownerRow = MySQL.single.await('SELECT owner FROM core_creator_vehicle_keys WHERE plate = ? ORDER BY id ASC LIMIT 1', { plate })
    local owner = ownerRow and ownerRow.owner or Bridge.GetIdentifier(src)

    local expires = nil
    if temporary then
        minutes = math.max(1, math.min(tonumber(minutes) or 60, 10080))
        expires = os.date('!%Y-%m-%d %H:%M:%S', os.time() + minutes * 60)
    end

    MySQL.insert.await(
        'INSERT INTO core_creator_vehicle_keys (plate, owner, holder, temporary, expires_at, meta) VALUES (?, ?, ?, ?, ?, ?)',
        { plate, owner, holder, temporary and 1 or 0, expires, json.encode({}) }
    )
    giveExternalKeys(targetId, plate, nil)
    Bridge.Notify(src, 'Clé attribuée', 'success')
    Bridge.Notify(targetId, ('Clé reçue: %s'):format(plate), 'inform')
    Logger.Log(src, 'key_give', MODULE, nil, { plate = plate, holder = holder, temporary = temporary and true or false })
end)

RegisterNetEvent('core_creator:vehicles:removeKey', function(plate, holder)
    local src = source
    if not Permissions.Guard(src, 'vehicles') then return end
    plate = normalizePlate(plate)
    holder = tostring(holder or '')
    MySQL.update.await('DELETE FROM core_creator_vehicle_keys WHERE plate = ? AND holder = ? AND temporary = 1', { plate, holder })
    -- permanent duplicates: delete non-owner keys matching holder
    MySQL.update.await('DELETE FROM core_creator_vehicle_keys WHERE plate = ? AND holder = ? AND holder <> owner', { plate, holder })
    Logger.Log(src, 'key_remove', MODULE, nil, { plate = plate, holder = holder })
    Bridge.Notify(src, 'Clé retirée', 'success')
end)

RegisterNetEvent('core_creator:vehicles:transferKey', function(plate, fromHolder, toTarget)
    local src = source
    if not Permissions.Guard(src, 'vehicles') then return end
    plate = normalizePlate(plate)
    local toId = tonumber(toTarget)
    if not toId then return end
    local newHolder = Bridge.GetIdentifier(toId)
    MySQL.update.await(
        'UPDATE core_creator_vehicle_keys SET holder = ? WHERE plate = ? AND holder = ?',
        { newHolder, plate, tostring(fromHolder) }
    )
    giveExternalKeys(toId, plate, nil)
    Logger.Log(src, 'key_transfer', MODULE, nil, { plate = plate, to = newHolder })
    Bridge.Notify(src, 'Clé transférée', 'success')
end)

local function playerHasKey(identifier, plate)
    plate = normalizePlate(plate)
    local rows = MySQL.query.await(
        'SELECT * FROM core_creator_vehicle_keys WHERE plate = ? AND holder = ?',
        { plate, identifier }
    ) or {}
    local now = os.time()
    for i = 1, #rows do
        local row = rows[i]
        if row.temporary == 1 and row.expires_at then
            -- expires_at is timestamp string; approximate check via unix if possible
            local exp = row.expires_at
            -- MySQL returns string 'YYYY-MM-DD HH:MM:SS'
            -- Accept if not obviously expired by comparing string to current UTC string
            if tostring(exp) < os.date('!%Y-%m-%d %H:%M:%S', now) then
                goto continue
            end
        end
        return true
        ::continue::
    end
    return false
end

exports('HasVehicleKey', function(src, plate)
    local identifier = Bridge.GetIdentifier(src)
    if not identifier then return false end
    return playerHasKey(identifier, plate)
end)

exports('IsVehicleOwner', function(src, plate)
    local identifier = Bridge.GetIdentifier(src)
    plate = normalizePlate(plate)
    local row = MySQL.single.await(
        'SELECT 1 FROM core_creator_vehicle_keys WHERE plate = ? AND owner = ? LIMIT 1',
        { plate, identifier }
    )
    return row ~= nil
end)

RegisterNetEvent('core_creator:vehicles:toggleLock', function(plate, netId)
    local src = source
    plate = normalizePlate(plate)
    local identifier = Bridge.GetIdentifier(src)
    if not playerHasKey(identifier, plate) then
        Bridge.Notify(src, 'Pas de clé', 'error')
        return
    end
    TriggerClientEvent('core_creator:vehicles:setLock', -1, netId, plate, src)
end)

AddEventHandler('playerDropped', function()
    -- no-op for now
end)
