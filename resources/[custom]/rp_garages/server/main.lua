---@param plate string
---@return string
local function normalizePlate(plate)
    return (plate or ''):gsub('%s+', ''):upper()
end

lib.callback.register('rp_garages:getVehicles', function(source, garageId, filter)
    local player = exports.rp_core:GetPlayer(source)
    if not player then return {} end
    local cid = player.PlayerData.citizenid

    if filter == 'impound' then
        return MySQL.query.await(
            'SELECT id, vehicle, plate, garage, fuel, engine, body, state, depotprice FROM player_vehicles WHERE citizenid = ? AND state = 2',
            { cid }
        ) or {}
    end

    return MySQL.query.await(
        'SELECT id, vehicle, plate, garage, fuel, engine, body, state, mods FROM player_vehicles WHERE citizenid = ? AND (garage = ? OR ? IS NULL) AND state = 1',
        { cid, garageId, garageId }
    ) or {}
end)

RegisterNetEvent('rp_garages:server:store', function(garageId, plate, props)
    local src = source
    if not exports.rp_core:RateLimit(src, 'garage_store', 1500) then return end
    local player = exports.rp_core:GetPlayer(src)
    if not player or type(garageId) ~= 'string' or type(plate) ~= 'string' then return end
    plate = normalizePlate(plate)

    local row = MySQL.single.await(
        [[SELECT id FROM player_vehicles WHERE citizenid = ? AND REPLACE(plate, ' ', '') = ? LIMIT 1]],
        { player.PlayerData.citizenid, plate }
    )
    if not row then
        exports.rp_core:Notify(src, L('not_yours'), 'error')
        return
    end

    MySQL.update.await(
        'UPDATE player_vehicles SET state = 1, garage = ?, fuel = ?, engine = ?, body = ?, mods = ? WHERE id = ?',
        {
            garageId,
            props and props.fuelLevel or 100,
            props and props.engineHealth or 1000,
            props and props.bodyHealth or 1000,
            props and json.encode(props) or nil,
            row.id,
        }
    )
    exports.rp_core:Notify(src, L('stored'), 'success')
    if GetResourceState('rp_logs') == 'started' then
        exports.rp_logs:Log('vehicles', src, 'Véhicule rangé', { plate = plate, garage = garageId })
    end
end)

RegisterNetEvent('rp_garages:server:spawn', function(garageId, vehicleId)
    local src = source
    if not exports.rp_core:RateLimit(src, 'garage_spawn', 1500) then return end
    local player = exports.rp_core:GetPlayer(src)
    vehicleId = tonumber(vehicleId)
    if not player or not vehicleId then return end

    local row = MySQL.single.await(
        'SELECT * FROM player_vehicles WHERE id = ? AND citizenid = ? LIMIT 1',
        { vehicleId, player.PlayerData.citizenid }
    )
    if not row or row.state ~= 1 then
        exports.rp_core:Notify(src, L('already_out'), 'error')
        return
    end

    MySQL.update.await('UPDATE player_vehicles SET state = 0 WHERE id = ?', { vehicleId })
    TriggerClientEvent('rp_garages:client:spawn', src, garageId, row)
    if GetResourceState('rp_logs') == 'started' then
        exports.rp_logs:Log('vehicles', src, 'Véhicule sorti', { plate = row.plate })
    end
end)

RegisterNetEvent('rp_garages:server:impoundRelease', function(vehicleId)
    local src = source
    if not exports.rp_core:RateLimit(src, 'impound', 2000) then return end
    local player = exports.rp_core:GetPlayer(src)
    vehicleId = tonumber(vehicleId)
    if not player or not vehicleId then return end

    local row = MySQL.single.await(
        'SELECT * FROM player_vehicles WHERE id = ? AND citizenid = ? AND state = 2 LIMIT 1',
        { vehicleId, player.PlayerData.citizenid }
    )
    if not row then return end
    local fee = tonumber(row.depotprice) or Config.ImpoundFee
    if not exports.rp_core:RemoveMoney(src, 'bank', fee, 'impound_fee') then
        exports.rp_core:Notify(src, L('no_money'), 'error')
        return
    end
    MySQL.update.await('UPDATE player_vehicles SET state = 1, garage = ?, depotprice = 0 WHERE id = ?', { 'impound', vehicleId })
    exports.rp_core:Notify(src, L('fee', fee), 'success')
end)

print('[rp_garages] ready — utilise la table player_vehicles (qbx_core)')
