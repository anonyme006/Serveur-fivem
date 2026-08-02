lib.callback.register('rr_garages:server:list', function(source, garageId)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return {} end

    if not Config.UsePlayerVehiclesTable then
        return {
            { vehicle = 'sultan', plate = 'DEMO001' },
        }
    end

    local rows = MySQL.query.await(
        'SELECT vehicle, plate FROM player_vehicles WHERE citizenid = ? AND state = 1',
        { player.PlayerData.citizenid }
    ) or {}

    -- Filtrage par garageId possible via colonne garage / type selon ton schéma
    return rows
end)

RegisterNetEvent('rr_garages:server:spawn', function(garageId, plate)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local garage
    for _, g in ipairs(Config.Garages) do
        if g.id == garageId then garage = g break end
    end
    if not garage then return end

    local row = MySQL.single.await(
        'SELECT vehicle, plate FROM player_vehicles WHERE citizenid = ? AND plate = ?',
        { player.PlayerData.citizenid, plate }
    )
    if not row then
        -- Mode démo si table absente
        TriggerClientEvent('rr_garages:client:spawnVehicle', src, 'sultan', garage.spawn, plate or 'DEMO001')
        return
    end

    local model = row.vehicle
    if type(model) == 'string' and model:sub(1, 1) == '{' then
        local ok, decoded = pcall(json.decode, model)
        if ok and decoded and decoded.model then model = decoded.model end
    end

    MySQL.update.await('UPDATE player_vehicles SET state = 0 WHERE plate = ?', { plate })
    TriggerClientEvent('rr_garages:client:spawnVehicle', src, model, garage.spawn, row.plate)
end)
