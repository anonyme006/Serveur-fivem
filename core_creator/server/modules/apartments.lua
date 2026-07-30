local MODULE = 'apartments'
local playerBucket = {}

CoreCreator.RegisterModule(MODULE, {})

local function countPlayerApartments(identifier)
    return MySQL.scalar.await(
        'SELECT COUNT(*) FROM core_creator_apartment_owners WHERE identifier = ? AND role = ?',
        { identifier, 'owner' }
    ) or 0
end

local function hasAccess(apartmentId, identifier)
    local row = MySQL.single.await(
        'SELECT role FROM core_creator_apartment_owners WHERE apartment_id = ? AND identifier = ? LIMIT 1',
        { apartmentId, identifier }
    )
    return row ~= nil, row and row.role or nil
end

RegisterNetEvent('core_creator:apartments:buy', function(apartmentId)
    local src = source
    apartmentId = tonumber(apartmentId)
    local apt = Database.GetById(MODULE, apartmentId)
    if not apt or not apt.active then return end

    local near = ServerValidator.PlayerNearCoords(src, apt.coords, Config.Distances.interaction + 3.0)
    if not near then
        Bridge.Notify(src, _('error.distance'), 'error')
        return
    end

    local data = apt.data or {}
    local identifier = Bridge.GetIdentifier(src)
    local owned, _ = hasAccess(apartmentId, identifier)
    if owned then
        Bridge.Notify(src, 'Déjà propriétaire / accès', 'error')
        return
    end

    if countPlayerApartments(identifier) >= (Config.Limits.apartmentsPerPlayer or 3) then
        Bridge.Notify(src, 'Limite d\'appartements atteinte', 'error')
        return
    end

    local price = math.floor(tonumber(data.price) or 0)
    local currency = data.currency or 'bank'
    if price > 0 and not Bridge.RemoveMoney(src, currency, price, 'apartment_buy') then
        Bridge.Notify(src, _('error.money'), 'error')
        return
    end

    MySQL.insert.await(
        'INSERT INTO core_creator_apartment_owners (apartment_id, identifier, role, meta) VALUES (?, ?, ?, ?)',
        { apartmentId, identifier, 'owner', json.encode({ bought_at = CoreUtils.ISODate() }) }
    )

    -- ownership history in apartment data
    data.history = data.history or {}
    data.history[#data.history + 1] = { identifier = identifier, at = CoreUtils.ISODate(), action = 'buy' }
    data.owner = identifier
    Database.Update(MODULE, apartmentId, { data = data }, identifier)

    Bridge.Notify(src, 'Appartement acheté', 'success')
    Logger.Log(src, 'apartment_buy', MODULE, apartmentId, { price = price })
end)

RegisterNetEvent('core_creator:apartments:enter', function(apartmentId)
    local src = source
    apartmentId = tonumber(apartmentId)
    local apt = Database.GetById(MODULE, apartmentId)
    if not apt or not apt.active then return end
    local identifier = Bridge.GetIdentifier(src)
    local ok = hasAccess(apartmentId, identifier)
    local data = apt.data or {}
    if not ok and not data.public then
        Bridge.Notify(src, _('error.permission'), 'error')
        return
    end

    local bucket = Config.Apartments.bucketBase + (apartmentId % Config.Apartments.bucketRange)
    SetPlayerRoutingBucket(src, bucket)
    playerBucket[src] = bucket

    local interior = data.interior or data.exit or apt.coords
    TriggerClientEvent('core_creator:apartments:teleport', src, interior, true)
    Logger.Log(src, 'apartment_enter', MODULE, apartmentId, {})
end)

RegisterNetEvent('core_creator:apartments:exit', function(apartmentId)
    local src = source
    apartmentId = tonumber(apartmentId)
    local apt = Database.GetById(MODULE, apartmentId)
    SetPlayerRoutingBucket(src, 0)
    playerBucket[src] = nil
    local exit = apt and apt.coords or nil
    if exit then
        TriggerClientEvent('core_creator:apartments:teleport', src, exit, false)
    end
    Logger.Log(src, 'apartment_exit', MODULE, apartmentId, {})
end)

RegisterNetEvent('core_creator:apartments:invite', function(apartmentId, targetId, temporaryMinutes)
    local src = source
    apartmentId = tonumber(apartmentId)
    targetId = tonumber(targetId)
    if not apartmentId or not targetId then return end
    local identifier = Bridge.GetIdentifier(src)
    local ok, role = hasAccess(apartmentId, identifier)
    if not ok or (role ~= 'owner' and role ~= 'roommate') then
        Bridge.Notify(src, _('error.permission'), 'error')
        return
    end
    local guest = Bridge.GetIdentifier(targetId)
    MySQL.insert.await(
        'INSERT INTO core_creator_apartment_owners (apartment_id, identifier, role, meta) VALUES (?, ?, ?, ?)',
        {
            apartmentId,
            guest,
            'guest',
            json.encode({
                temporary = true,
                expires_at = CoreUtils.ISODate(os.time() + math.max(5, tonumber(temporaryMinutes) or 60) * 60),
                invited_by = identifier,
            }),
        }
    )
    Bridge.Notify(src, 'Invitation envoyée', 'success')
    Bridge.Notify(targetId, 'Invitation appartement reçue', 'inform')
    Logger.Log(src, 'apartment_invite', MODULE, apartmentId, { guest = guest })
end)

RegisterNetEvent('core_creator:apartments:requestSync', function()
    TriggerClientEvent('core_creator:apartments:sync', source, Database.GetAll(MODULE, true))
end)

AddEventHandler('core_creator:databaseReady', function()
    Wait(100)
    TriggerClientEvent('core_creator:apartments:sync', -1, Database.GetAll(MODULE, true))
end)

AddEventHandler('core_creator:entityChanged', function(moduleName)
    if moduleName ~= MODULE then return end
    TriggerClientEvent('core_creator:apartments:sync', -1, Database.GetAll(MODULE, true))
end)

AddEventHandler('playerDropped', function()
    local src = source
    if playerBucket[src] then
        SetPlayerRoutingBucket(src, 0)
        playerBucket[src] = nil
    end
end)
