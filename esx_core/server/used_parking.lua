if not Config.UsedParking.enabled then return end

local ESX = exports['es_extended']:getSharedObject()

local listings = {} -- id -> row
local slotTaken = {} -- slot index -> id

local function refreshCache()
    listings = {}
    slotTaken = {}
    local rows = MySQL.query.await('SELECT * FROM esx_core_used_parking') or {}
    for _, row in ipairs(rows) do
        listings[row.id] = {
            id = row.id,
            seller = row.seller,
            plate = Core.NormalizePlate(row.plate),
            price = tonumber(row.price) or 0,
            slot = tonumber(row.slot),
            vehicle = Core.DecodeJson(row.vehicle),
            label = row.label,
        }
        if row.slot then slotTaken[tonumber(row.slot)] = row.id end
    end
    TriggerClientEvent('esx_core:used:sync', -1, listings)
end

MySQL.ready(function()
    SetTimeout(2500, refreshCache)
end)

local function freeSlot()
    for i = 1, #(Config.UsedParking.slots or {}) do
        if not slotTaken[i] then return i end
    end
    return nil
end

lib.callback.register('esx_core:used:get', function()
    return listings
end)

lib.callback.register('esx_core:used:list', function(source, plate, price, props)
    local xPlayer = Core.GetPlayer(source)
    if not xPlayer then return false, 'cover_busy' end

    plate = Core.NormalizePlate(plate)
    price = math.floor(tonumber(price) or 0)

    if price < Config.UsedParking.minPrice or price > Config.UsedParking.maxPrice then
        return false, 'used_invalid_price', Config.UsedParking.minPrice, Config.UsedParking.maxPrice
    end

    local cols = Config.Persistence.columns
    local owned = MySQL.single.await(
        ('SELECT * FROM `%s` WHERE `%s` = ? AND REPLACE(`%s`, " ", "") = ? LIMIT 1'):format(
            cols.table, cols.owner, cols.plate
        ),
        { xPlayer.identifier, plate }
    )
    if not owned then return false, 'used_not_owner' end

    -- déjà en vente ?
    local existing = MySQL.single.await('SELECT id FROM esx_core_used_parking WHERE plate = ? LIMIT 1', { plate })
    if existing then return false, 'cover_busy' end

    local slot = freeSlot()
    if not slot then return false, 'used_no_slot' end

    local vehicleData = type(props) == 'table' and props or Core.DecodeJson(owned[cols.vehicle] or owned.vehicle)
    vehicleData.plate = plate

    local insertId = MySQL.insert.await(
        'INSERT INTO esx_core_used_parking (seller, plate, price, slot, vehicle, label) VALUES (?, ?, ?, ?, ?, ?)',
        { xPlayer.identifier, plate, price, slot, json.encode(vehicleData), plate }
    )

    -- Range le véhicule (plus sorti)
    Core.SetVehicleStored(plate, true, 'used_parking')

    listings[insertId] = {
        id = insertId,
        seller = xPlayer.identifier,
        plate = plate,
        price = price,
        slot = slot,
        vehicle = vehicleData,
        label = plate,
    }
    slotTaken[slot] = insertId

    TriggerClientEvent('esx_core:used:sync', -1, listings)
    return true, 'used_listed', price
end)

lib.callback.register('esx_core:used:remove', function(source, listingId)
    local xPlayer = Core.GetPlayer(source)
    if not xPlayer then return false, 'cover_busy' end

    listingId = tonumber(listingId)
    local entry = listingId and listings[listingId]
    if not entry or entry.seller ~= xPlayer.identifier then
        return false, 'used_not_owner'
    end

    MySQL.update.await('DELETE FROM esx_core_used_parking WHERE id = ?', { listingId })
    slotTaken[entry.slot] = nil
    listings[listingId] = nil

    Core.SetVehicleStored(entry.plate, true, 'legion') -- retour garage public par défaut

    TriggerClientEvent('esx_core:used:sync', -1, listings)
    return true, 'used_removed'
end)

lib.callback.register('esx_core:used:buy', function(source, listingId)
    local xPlayer = Core.GetPlayer(source)
    if not xPlayer then return false, 'cover_busy' end

    listingId = tonumber(listingId)
    local entry = listingId and listings[listingId]
    if not entry then return false, 'used_empty' end

    if entry.seller == xPlayer.identifier then
        return false, 'cover_busy'
    end

    local price = entry.price
    local account = Config.UsedParking.payAccount or 'bank'
    local bal = xPlayer.getAccount(account)
    if not bal or (bal.money or 0) < price then
        return false, 'used_no_money'
    end

    xPlayer.removeAccountMoney(account, price)

    local commission = math.floor(price * ((Config.UsedParking.commission or 0) / 100))
    local sellerGain = price - commission

    local seller = ESX.GetPlayerFromIdentifier and ESX.GetPlayerFromIdentifier(entry.seller)
    if seller then
        seller.addAccountMoney(account, sellerGain)
        TriggerClientEvent('esx_core:notify', seller.source, Core.Locale('used_sold', sellerGain), 'success')
    else
        -- joueur offline : crédite users.accounts
        pcall(function()
            local row = MySQL.single.await('SELECT accounts FROM users WHERE identifier = ? LIMIT 1', { entry.seller })
            if row and row.accounts then
                local accounts = Core.DecodeJson(row.accounts)
                accounts[account] = (tonumber(accounts[account]) or 0) + sellerGain
                MySQL.update.await('UPDATE users SET accounts = ? WHERE identifier = ?', {
                    json.encode(accounts), entry.seller
                })
            end
        end)
    end

    local cols = Config.Persistence.columns
    MySQL.update.await(
        ('UPDATE `%s` SET `%s` = ?, `%s` = 1, `%s` = ? WHERE REPLACE(`%s`, " ", "") = ?'):format(
            cols.table, cols.owner, cols.stored, cols.parking, cols.plate
        ),
        { xPlayer.identifier, 'legion', entry.plate }
    )

    -- Transfert clés
    MySQL.update.await('DELETE FROM esx_core_keys WHERE key_type = ? AND key_ref = ?', { 'vehicle', entry.plate })
    MySQL.insert.await(
        'INSERT INTO esx_core_keys (owner, holder, key_type, key_ref, label, temporary) VALUES (?, ?, ?, ?, ?, 0)',
        { xPlayer.identifier, xPlayer.identifier, 'vehicle', entry.plate, entry.plate }
    )

    MySQL.update.await('DELETE FROM esx_core_used_parking WHERE id = ?', { listingId })
    slotTaken[entry.slot] = nil
    listings[listingId] = nil

    TriggerClientEvent('esx_core:used:sync', -1, listings)
    return true, 'used_bought', entry.plate, price
end)
