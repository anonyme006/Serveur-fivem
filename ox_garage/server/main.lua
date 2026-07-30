local function trimPlate(plate)
    if not plate then return '' end
    return (string.gsub(string.upper(plate), '^%s*(.-)%s*$', '%1'))
end

local function getGarage(garageId)
    for _, garage in ipairs(Config.Garages) do
        if garage.id == garageId then
            return garage
        end
    end
    if Config.Impound and Config.Impound.id == garageId then
        return Config.Impound
    end
    return nil
end

local function decodeVehicle(row)
    if not row then return nil end
    local props = {}
    if row.vehicle and row.vehicle ~= '' then
        local ok, decoded = pcall(json.decode, row.vehicle)
        if ok and type(decoded) == 'table' then
            props = decoded
        end
    end

    local model = props.model
    local label = props.name or props.modelLabel
    if type(label) ~= 'string' or label == '' then
        if type(model) == 'string' then
            label = model
        else
            label = trimPlate(row.plate)
        end
    end

    return {
        plate = trimPlate(row.plate),
        props = props,
        model = model,
        label = label,
        stored = row.stored,
        parking = row.parking or row.garage,
        pound = row.pound,
        engine = props.engineHealth or 1000.0,
        body = props.bodyHealth or 1000.0,
        fuel = props.fuelLevel or 100.0,
    }
end

--- Liste des véhicules du joueur (garage ou fourrière)
lib.callback.register('ox_garage:list', function(source, garageId, impound)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local identifier = xPlayer.getIdentifier()
    local rows

    if impound then
        -- stockés = 0 et hors garage / pound flag
        rows = MySQL.query.await([[
            SELECT plate, vehicle, stored, parking, pound
            FROM owned_vehicles
            WHERE owner = ?
              AND (stored = 0 OR stored = false)
              AND (pound IS NOT NULL OR parking = ? OR parking IS NULL OR parking = '')
        ]], { identifier, Config.Impound.id })
    else
        rows = MySQL.query.await([[
            SELECT plate, vehicle, stored, parking, pound
            FROM owned_vehicles
            WHERE owner = ?
              AND (stored = 1 OR stored = true)
              AND (parking = ? OR parking IS NULL OR parking = '' OR parking = ?)
        ]], { identifier, garageId, garageId })
    end

    local list = {}
    for _, row in ipairs(rows or {}) do
        if impound then
            -- en fourrière : pas stocké
            if tonumber(row.stored) == 0 or row.stored == false or row.stored == '0' then
                list[#list + 1] = decodeVehicle(row)
            end
        else
            list[#list + 1] = decodeVehicle(row)
        end
    end

    return list
end)

lib.callback.register('ox_garage:store', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or type(data) ~= 'table' then
        return { ok = false, reason = 'Données invalides' }
    end

    local garage = getGarage(data.garageId)
    if not garage or garage.id == Config.Impound.id then
        return { ok = false, reason = 'Garage invalide' }
    end

    local plate = trimPlate(data.plate)
    if plate == '' then
        return { ok = false, reason = 'Plaque invalide' }
    end

    local row = MySQL.single.await(
        'SELECT plate, owner, vehicle FROM owned_vehicles WHERE plate = ? LIMIT 1',
        { plate }
    )

    -- compat plaques avec espaces
    if not row then
        row = MySQL.single.await(
            "SELECT plate, owner, vehicle FROM owned_vehicles WHERE REPLACE(plate, ' ', '') = ? LIMIT 1",
            { (string.gsub(plate, '%s+', '')) }
        )
    end

    if not row then
        return { ok = false, reason = 'Ce véhicule ne vous appartient pas' }
    end

    if row.owner ~= xPlayer.getIdentifier() then
        return { ok = false, reason = 'Ce véhicule ne vous appartient pas' }
    end

    local props = data.props or {}
    props.plate = plate
    if data.engine then props.engineHealth = data.engine end
    if data.body then props.bodyHealth = data.body end
    if data.fuel then props.fuelLevel = data.fuel end

    MySQL.update.await([[
        UPDATE owned_vehicles
        SET vehicle = ?, stored = 1, parking = ?, pound = NULL
        WHERE plate = ?
    ]], { json.encode(props), garage.id, row.plate })

    return { ok = true }
end)

lib.callback.register('ox_garage:retrieve', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or type(data) ~= 'table' then
        return { ok = false, reason = 'Données invalides' }
    end

    local plate = trimPlate(data.plate)
    local impound = data.impound == true

    local row = MySQL.single.await(
        'SELECT plate, owner, vehicle, stored, parking, pound FROM owned_vehicles WHERE plate = ? LIMIT 1',
        { plate }
    )
    if not row then
        row = MySQL.single.await(
            "SELECT plate, owner, vehicle, stored, parking, pound FROM owned_vehicles WHERE REPLACE(plate, ' ', '') = ? LIMIT 1",
            { (string.gsub(plate, '%s+', '')) }
        )
    end

    if not row or row.owner ~= xPlayer.getIdentifier() then
        return { ok = false, reason = 'Véhicule introuvable' }
    end

    if impound then
        local price = Config.Impound.price or 0
        if price > 0 then
            if xPlayer.getMoney() >= price then
                xPlayer.removeMoney(price, 'ox_garage-impound')
            elseif xPlayer.getAccount('bank').money >= price then
                xPlayer.removeAccountMoney('bank', price, 'ox_garage-impound')
            else
                return { ok = false, reason = ('Fonds insuffisants ($%s)'):format(price) }
            end
        end
    else
        local stored = tonumber(row.stored) == 1 or row.stored == true or row.stored == '1'
        if not stored then
            return { ok = false, reason = 'Véhicule déjà sorti (fourrière ?)' }
        end
    end

    MySQL.update.await([[
        UPDATE owned_vehicles
        SET stored = 0, parking = NULL, pound = NULL
        WHERE plate = ?
    ]], { row.plate })

    local decoded = decodeVehicle(row)
    return {
        ok = true,
        plate = decoded.plate,
        props = decoded.props,
        model = decoded.model,
        engine = decoded.engine,
        body = decoded.body,
        fuel = decoded.fuel,
    }
end)
