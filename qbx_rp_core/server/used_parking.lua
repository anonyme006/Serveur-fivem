if not Config.UsedParking.enabled then return end

local listings = {} -- id -> row
local slotTaken = {} -- slot index -> id

local function refreshCache()
    listings = {}
    slotTaken = {}
    local rows = MySQL.query.await('SELECT * FROM qbx_rp_core_used_parking') or {}
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
    TriggerClientEvent('qbx_rp_core:used:sync', -1, listings)
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

lib.callback.register('qbx_rp_core:used:get', function()
    return listings
end)

lib.callback.register('qbx_rp_core:used:list', function(source, plate, price, props)
    local player = Core.GetPlayer(source)
    if not player then return false, 'cover_busy' end

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
        { Core.GetCitizenId(player), plate }
    )
    if not owned then return false, 'used_not_owner' end

    local existing = MySQL.single.await('SELECT id FROM qbx_rp_core_used_parking WHERE plate = ? LIMIT 1', { plate })
    if existing then return false, 'cover_busy' end

    local slot = freeSlot()
    if not slot then return false, 'used_no_slot' end

    local vehicleData = type(props) == 'table' and props or Core.DecodeJson(owned[cols.vehicle] or owned.vehicle)
    vehicleData.plate = plate

    local insertId = MySQL.insert.await(
        'INSERT INTO qbx_rp_core_used_parking (seller, plate, price, slot, vehicle, label) VALUES (?, ?, ?, ?, ?, ?)',
        { Core.GetCitizenId(player), plate, price, slot, json.encode(vehicleData), plate }
    )

    Core.SetVehicleStored(plate, true, 'used_parking')

    listings[insertId] = {
        id = insertId,
        seller = Core.GetCitizenId(player),
        plate = plate,
        price = price,
        slot = slot,
        vehicle = vehicleData,
        label = plate,
    }
    slotTaken[slot] = insertId

    TriggerClientEvent('qbx_rp_core:used:sync', -1, listings)
    if Core.Log then
        Core.Log('vehicles', '🅿️ Mise en vente (occasions)', ('Plaque `%s` — **%s$** — slot %s'):format(plate, price, slot), {
            color = 'money',
            src = source,
        })
    end
    return true, 'used_listed', price
end)

lib.callback.register('qbx_rp_core:used:remove', function(source, listingId)
    local player = Core.GetPlayer(source)
    if not player then return false, 'cover_busy' end

    listingId = tonumber(listingId)
    local entry = listingId and listings[listingId]
    if not entry or entry.seller ~= Core.GetCitizenId(player) then
        return false, 'used_not_owner'
    end

    MySQL.update.await('DELETE FROM qbx_rp_core_used_parking WHERE id = ?', { listingId })
    slotTaken[entry.slot] = nil
    listings[listingId] = nil

    Core.SetVehicleStored(entry.plate, true, 'legion')

    TriggerClientEvent('qbx_rp_core:used:sync', -1, listings)
    if Core.Log then
        Core.Log('vehicles', '🅿️ Annonce retirée', ('Plaque `%s`'):format(entry.plate), {
            color = 'warning',
            src = source,
        })
    end
    return true, 'used_removed'
end)

lib.callback.register('qbx_rp_core:used:buy', function(source, listingId)
    local player = Core.GetPlayer(source)
    if not player then return false, 'cover_busy' end

    listingId = tonumber(listingId)
    local entry = listingId and listings[listingId]
    if not entry then return false, 'used_empty' end

    local buyerId = Core.GetCitizenId(player)
    if entry.seller == buyerId then
        return false, 'cover_busy'
    end

    local price = entry.price
    local account = Core.NormalizeAccount(Config.UsedParking.payAccount or 'bank')

    if Core.GetMoney(source, account) < price then
        return false, 'used_no_money'
    end

    if not Core.RemoveMoney(source, account, price, 'used-parking-buy') then
        return false, 'used_no_money'
    end

    local commission = math.floor(price * ((Config.UsedParking.commission or 0) / 100))
    local sellerGain = price - commission

    local seller = Core.GetPlayerFromCitizenId(entry.seller)
    if seller and seller.PlayerData and seller.PlayerData.source then
        Core.AddMoney(seller.PlayerData.source, account, sellerGain, 'used-parking-sale')
        TriggerClientEvent('qbx_rp_core:notify', seller.PlayerData.source, Core.Locale('used_sold', sellerGain), 'success')
    else
        Core.AddMoneyOffline(entry.seller, account, sellerGain)
    end

    local cols = Config.Persistence.columns
    local garaged = (Config.Persistence.state and Config.Persistence.state.garaged) or 1
    MySQL.update.await(
        ('UPDATE `%s` SET `%s` = ?, `%s` = ?, `%s` = ? WHERE REPLACE(`%s`, " ", "") = ?'):format(
            cols.table, cols.owner, cols.stored, cols.parking, cols.plate
        ),
        { buyerId, garaged, 'legion', entry.plate }
    )

    MySQL.update.await('DELETE FROM qbx_rp_core_keys WHERE key_type = ? AND key_ref = ?', { 'vehicle', entry.plate })
    MySQL.insert.await(
        'INSERT INTO qbx_rp_core_keys (owner, holder, key_type, key_ref, label, temporary) VALUES (?, ?, ?, ?, ?, 0)',
        { buyerId, buyerId, 'vehicle', entry.plate, entry.plate }
    )

    if Core.Inventory and Core.Inventory.Enabled() then
        Core.Inventory.AddVehicleKey(source, entry.plate, entry.plate, 1)
    end

    MySQL.update.await('DELETE FROM qbx_rp_core_used_parking WHERE id = ?', { listingId })
    slotTaken[entry.slot] = nil
    listings[listingId] = nil

    TriggerClientEvent('qbx_rp_core:used:sync', -1, listings)
    if Core.Log then
        Core.Log('money', '💵 Vente occasion', ('Plaque `%s` — **%s$** (commission vendeur nette appliquée)'):format(entry.plate, price), {
            color = 'money',
            src = source,
            fields = {
                { name = 'Vendeur', value = ('`%s`'):format(entry.seller), inline = true },
            },
        })
    end
    return true, 'used_bought', entry.plate, price
end)
