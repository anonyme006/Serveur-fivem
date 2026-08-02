--[[--------------------------------------------------------------------------
    core_garage — liste véhicules / ouverture garage
---------------------------------------------------------------------------]]

local function rowToNui(row)
    local props = GarageUtils.Decode(row.vehicle)
    local model = props.model
    local modelName = type(model) == 'string' and model or nil
    if type(model) == 'number' then
        -- hash — le client résoudra le display name
        modelName = tostring(model)
    end

    return {
        id = row.id,
        plate = row.plate,
        owner = row.owner,
        garage = row.garage,
        type = row.type,
        model = model,
        modelName = modelName,
        props = props,
        nickname = row.nickname,
        category = row.category or 'other',
        engine = GarageUtils.HealthPercent(row.engine or props.engineHealth or 1000),
        body = GarageUtils.HealthPercent(row.body or props.bodyHealth or 1000),
        fuel = math.floor(tonumber(row.fuel or props.fuelLevel or 100) + 0.5),
        dirt = tonumber(row.dirt) or 0.0,
        mileage = tonumber(row.mileage) or 0.0,
        mileageLabel = GarageUtils.FormatMileage(row.mileage),
        insured = row.insured == 1 or row.insured == true,
        status = GarageUtils.GetStatus(row),
        company = row.company,
        impoundFee = tonumber(row.impound_fee) or 0,
        impoundUntil = row.impound_until,
        lastOut = row.last_out,
        lastIn = row.last_in,
    }
end

---@param source number
---@param garageName string
---@return table|nil, string|nil
local function buildVehicleList(source, garageName)
    local garage = GarageDB.GetGarage(garageName)
    if not garage then return nil, 'error' end

    local ok, err = GarageSecurity.CanAccessGarage(source, garage)
    if not ok then return nil, err end

    if not GarageSecurity.IsNear(source, garage.coords, Config.General.maxDistance + 5.0) then
        return nil, 'too_far'
    end

    local identifier = GarageGetIdentifier(source)
    if not identifier then return nil, 'error' end

    local rows
    if garage.type == 'impound' then
        rows = MySQL.query.await([[
            SELECT * FROM garage_vehicles
            WHERE owner = ? AND impound = 1
            ORDER BY updated_at DESC
        ]], { identifier })
    elseif garage.type == 'company' or garage.type == 'job' then
        local job = garage.job
        rows = MySQL.query.await([[
            SELECT * FROM garage_vehicles
            WHERE (owner = ? OR company = ?)
              AND (garage = ? OR garage IS NULL OR type = ?)
              AND impound = 0
            ORDER BY stored DESC, nickname ASC, plate ASC
        ]], { identifier, job, garageName, garage.vehicle_type or 'car' })
    elseif garage.type == 'personal' then
        rows = MySQL.query.await([[
            SELECT * FROM garage_vehicles
            WHERE owner = ? AND company IS NULL AND impound = 0
              AND (garage = ? OR stored = 0)
              AND type = ?
            ORDER BY stored DESC, nickname ASC, plate ASC
        ]], { identifier, garageName, garage.vehicle_type or 'car' })
    else
        -- public / boat / plane / helicopter
        rows = MySQL.query.await([[
            SELECT * FROM garage_vehicles
            WHERE owner = ? AND company IS NULL AND impound = 0
              AND type = ?
            ORDER BY stored DESC, nickname ASC, plate ASC
        ]], { identifier, garage.vehicle_type or 'car' })
    end

    local list = {}
    for _, row in ipairs(rows or {}) do
        list[#list + 1] = rowToNui(row)
    end
    return {
        garage = {
            name = garage.name,
            label = garage.label,
            type = garage.type,
            impoundPrice = garage.impound_price,
        },
        vehicles = list,
    }
end

lib.callback.register('core_garage:openGarage', function(source, garageName)
    if not GarageSecurity.RateOk(source) then return { ok = false, error = 'anti_dupe' } end
    local data, err = buildVehicleList(source, garageName)
    if not data then
        return { ok = false, error = err or 'error' }
    end
    return { ok = true, data = data }
end)

lib.callback.register('core_garage:getCompanyLogs', function(source, garageName)
    local garage = GarageDB.GetGarage(garageName)
    if not garage or (garage.type ~= 'company' and garage.type ~= 'job') then
        return { ok = false }
    end
    local ok = GarageSecurity.CanAccessGarage(source, garage)
    if not ok then return { ok = false } end

    local company = GarageDB.companies[garage.job] and GarageDB.companies[garage.job][garageName]
    local xPlayer = ESX.GetPlayerFromId(source)
    local grade = xPlayer and xPlayer.getJob().grade or 0
    if company and grade < (company.min_grade_manage or 2) then
        return { ok = false, error = 'no_permission' }
    end

    local logs = MySQL.query.await([[
        SELECT * FROM garage_logs
        WHERE company = ? OR garage = ?
        ORDER BY created_at DESC LIMIT ?
    ]], { garage.job, garageName, Config.Company.maxLogs or 50 })

    return { ok = true, logs = logs or {} }
end)

--- Enregistrement véhicule (export / event)
local function registerVehicle(data)
    local plate = GarageUtils.NormalizePlate(data.plate)
    if plate == '' or not data.owner then return false end

    local props = data.props or data.vehicle or {}
    if type(props) ~= 'string' then props = GarageUtils.Encode(props) end
    local decoded = GarageUtils.Decode(props)

    local existing = MySQL.scalar.await('SELECT id FROM garage_vehicles WHERE plate = ?', { plate })
    if existing then
        MySQL.update.await([[
            UPDATE garage_vehicles SET owner = ?, vehicle = ?, garage = COALESCE(?, garage),
                type = ?, company = ?, category = COALESCE(?, category), nickname = COALESCE(?, nickname)
            WHERE plate = ?
        ]], {
            data.owner, props, data.garage, data.type or 'car', data.company,
            data.category, data.nickname, plate
        })
    else
        MySQL.insert.await([[
            INSERT INTO garage_vehicles
                (owner, plate, vehicle, garage, type, stored, engine, body, fuel, dirt, mileage, insured, nickname, category, company)
            VALUES (?, ?, ?, ?, ?, 1, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]], {
            data.owner, plate, props, data.garage or 'legion_public', data.type or 'car',
            decoded.engineHealth or 1000.0, decoded.bodyHealth or 1000.0,
            decoded.fuelLevel or 100.0, decoded.dirtLevel or 0.0,
            data.mileage or 0.0, data.insured and 1 or 0,
            data.nickname, data.category, data.company
        })
    end
    return true
end

RegisterNetEvent('core_garage:server:registerVehicle', function(data)
    local src = source
    if type(data) ~= 'table' then return end
    -- Seuls admins / autres ressources via export
    if not GarageSecurity.IsAdmin(src) then return end
    registerVehicle(data)
end)

exports('RegisterVehicle', registerVehicle)

--- Mise à jour kilométrage
RegisterNetEvent('core_garage:server:updateMileage', function(plate, mileage, coords)
    local src = source
    plate = GarageUtils.NormalizePlate(plate)
    mileage = tonumber(mileage)
    if not plate or not mileage or mileage < 0 then return end

    local row = MySQL.single.await('SELECT owner, company, mileage FROM garage_vehicles WHERE plate = ?', { plate })
    if not row then return end
    if not GarageSecurity.IsOwnerOrCompany(src, row.owner, row.company) then return end

    -- Empêche les sauts irréalistes
    local current = tonumber(row.mileage) or 0.0
    if mileage < current then return end
    if mileage - current > 50.0 then -- max +50 km par tick
        mileage = current + 0.5
    end

    MySQL.update.await('UPDATE garage_vehicles SET mileage = ? WHERE plate = ?', { mileage, plate })
    MySQL.query.await([[
        INSERT INTO vehicle_mileage (plate, mileage, last_coords)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE mileage = VALUES(mileage), last_coords = VALUES(last_coords)
    ]], { plate, mileage, GarageUtils.Encode(coords) })
end)
