local function findVehicle(model)
    for _, v in ipairs(Config.Vehicles) do
        if v.model == model then return v end
    end
end

local function genPlate()
    local chars = 'ABCDEFGHJKLMNPRSTUVWXYZ0123456789'
    local plate = 'VB'
    for _ = 1, 6 do
        local i = math.random(1, #chars)
        plate = plate .. chars:sub(i, i)
    end
    return plate
end

RegisterNetEvent('rr_concess:server:buy', function(model)
    local src = source
    local player = exports.rr_api:GetPlayer(src)
    if not player then return end
    if not exports.rr_api:DistCheck(src, Config.Shop.coords, 10.0) then return end

    local veh = findVehicle(model)
    if not veh then return end

    if not exports.rr_api:RemoveMoney(src, 'bank', veh.price, 'concess') then
        if not exports.rr_api:RemoveMoney(src, 'cash', veh.price, 'concess') then
            exports.rr_api:Notify(src, 'Concessionnaire', 'Fonds insuffisants.', 'error')
            return
        end
    end

    local plate = genPlate()
    local citizenid = player.PlayerData.citizenid
    local props = json.encode({ model = veh.model, plate = plate })

    MySQL.insert.await([[
        INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        player.PlayerData.license,
        citizenid,
        veh.model,
        joaat(veh.model),
        props,
        plate,
        'pillboxgarage',
        0,
    })

    TriggerClientEvent('rr_concess:client:deliver', src, veh.model, plate)
end)
