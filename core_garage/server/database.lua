--[[--------------------------------------------------------------------------
    core_garage — initialisation SQL + cache
---------------------------------------------------------------------------]]

GarageDB = {
    ready = false,
    garages = {},      -- [name] = row
    garagesById = {},  -- [id] = row
    companies = {},    -- [job] = { ... }
}

local function ensureTables()
    local sqlFile = LoadResourceFile(GetCurrentResourceName(), 'sql/install.sql')
    if not sqlFile then
        print('^1[core_garage]^7 sql/install.sql introuvable')
        return false
    end

    -- Retire les commentaires ligne puis exécute chaque statement
    local cleaned = sqlFile:gsub('%-%-[^\n]*', '')
    for statement in cleaned:gmatch('([^;]+);') do
        local trimmed = statement:match('^%s*(.-)%s*$')
        if trimmed and trimmed ~= '' then
            MySQL.query.await(trimmed)
        end
    end
    return true
end

local function decodeGarageRow(row)
    if not row then return nil end
    row.coords = GarageUtils.Decode(row.coords)
    row.spawn = GarageUtils.Decode(row.spawn)
    row.store = GarageUtils.Decode(row.store)
    row.blip = GarageUtils.Decode(row.blip)
    row.marker = GarageUtils.Decode(row.marker)
    row.enabled = row.enabled == 1 or row.enabled == true
    row.min_grade = tonumber(row.min_grade) or 0
    row.impound_price = tonumber(row.impound_price) or Config.Impound.defaultPrice
    row.impound_time = tonumber(row.impound_time) or Config.Impound.defaultTimeMinutes
    return row
end

function GarageDB.RefreshGarages()
    local rows = MySQL.query.await('SELECT * FROM garages') or {}
    GarageDB.garages = {}
    GarageDB.garagesById = {}
    for _, row in ipairs(rows) do
        local g = decodeGarageRow(row)
        if g then
            GarageDB.garages[g.name] = g
            GarageDB.garagesById[g.id] = g
        end
    end
    GarageUtils.Debug(('Garages chargés: %s'):format(#rows))
end

function GarageDB.RefreshCompanies()
    local rows = MySQL.query.await('SELECT * FROM garage_company') or {}
    GarageDB.companies = {}
    for _, row in ipairs(rows) do
        GarageDB.companies[row.job] = GarageDB.companies[row.job] or {}
        GarageDB.companies[row.job][row.garage] = row
    end
end

local function seedDefaults()
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM garages') or 0
    if count == 0 and Config.DefaultGarages then
        for _, g in ipairs(Config.DefaultGarages) do
            local blip = g.blip or { enabled = true }
            local marker = g.marker or { enabled = true }
            MySQL.insert.await([[
                INSERT INTO garages
                    (name, label, type, coords, spawn, heading, store, blip, marker, job, gang, min_grade, vehicle_type, impound_price, impound_time, enabled)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ]], {
                g.name,
                g.label,
                g.type,
                GarageUtils.Encode(GarageUtils.CoordsToTable(g.coords)),
                GarageUtils.Encode(GarageUtils.CoordsToTable(g.spawn)),
                (g.spawn and g.spawn.w) or 0.0,
                GarageUtils.Encode(GarageUtils.CoordsToTable(g.store)),
                GarageUtils.Encode(blip),
                GarageUtils.Encode(marker),
                g.job,
                g.gang,
                g.minGrade or 0,
                g.vehicleType or Config.GarageVehicleTypes[g.type] or 'car',
                g.impoundPrice or Config.Impound.defaultPrice,
                g.impoundTime or Config.Impound.defaultTimeMinutes,
                g.enabled == false and 0 or 1,
            })
        end
        print('^2[core_garage]^7 Garages par défaut insérés.')
    end

    local cCount = MySQL.scalar.await('SELECT COUNT(*) FROM garage_company') or 0
    if cCount == 0 and Config.DefaultCompanies then
        for _, c in ipairs(Config.DefaultCompanies) do
            MySQL.insert.await([[
                INSERT INTO garage_company
                    (job, garage, label, min_grade_out, min_grade_store, min_grade_manage, max_out, shared)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ]], {
                c.job, c.garage, c.label,
                c.minGradeOut or 0, c.minGradeStore or 0, c.minGradeManage or 2,
                c.maxOut or 5, c.shared == false and 0 or 1,
            })
        end
        print('^2[core_garage]^7 Entreprises par défaut insérées.')
    end
end

--- Migration douce depuis owned_vehicles (ESX)
function GarageDB.ImportOwnedVehicles()
    if not Config.General.syncOwnedVehicles then return end
    local tableName = Config.General.ownedVehiclesTable or 'owned_vehicles'
    local exists = MySQL.scalar.await(([[
        SELECT COUNT(*) FROM information_schema.tables
        WHERE table_schema = DATABASE() AND table_name = '%s'
    ]]):format(tableName))
    if not exists or exists == 0 then return end

    local rows = MySQL.query.await(('SELECT * FROM `%s`'):format(tableName)) or {}
    local imported = 0
    for _, row in ipairs(rows) do
        local plate = GarageUtils.NormalizePlate(row.plate)
        if plate ~= '' then
            local existsPlate = MySQL.scalar.await('SELECT id FROM garage_vehicles WHERE plate = ?', { plate })
            if not existsPlate then
                local props = type(row.vehicle) == 'string' and row.vehicle or GarageUtils.Encode(row.vehicle)
                local decoded = GarageUtils.Decode(props)
                MySQL.insert.await([[
                    INSERT INTO garage_vehicles
                        (owner, plate, vehicle, garage, type, stored, impound, engine, body, fuel, mileage)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ]], {
                    row.owner,
                    plate,
                    props,
                    row.parking or row.garage or 'legion_public',
                    row.type or 'car',
                    (row.stored == 1 or row.stored == true) and 1 or 0,
                    (row.pound and row.pound ~= '' and row.pound ~= nil) and 1 or 0,
                    decoded.engineHealth or 1000.0,
                    decoded.bodyHealth or 1000.0,
                    decoded.fuelLevel or 100.0,
                    0.0,
                })
                imported = imported + 1
            end
        end
    end
    if imported > 0 then
        print(('^2[core_garage]^7 %s véhicules importés depuis %s'):format(imported, tableName))
    end
end

function GarageDB.SyncOwnedVehicle(plate, data)
    if not Config.General.syncOwnedVehicles then return end
    local tableName = Config.General.ownedVehiclesTable or 'owned_vehicles'
    plate = GarageUtils.NormalizePlate(plate)
    pcall(function()
        MySQL.update.await(([[
            UPDATE `%s` SET stored = ?, parking = ?, pound = ?, vehicle = ?
            WHERE plate = ? OR REPLACE(plate, ' ', '') = ?
        ]]):format(tableName), {
            data.stored and 1 or 0,
            data.garage,
            data.impound and (data.impoundId or 'impound_public') or nil,
            type(data.vehicle) == 'string' and data.vehicle or GarageUtils.Encode(data.vehicle),
            plate,
            plate,
        })
    end)
end

CreateThread(function()
    MySQL.ready(function()
        if ensureTables() then
            seedDefaults()
            GarageDB.ImportOwnedVehicles()
            GarageDB.RefreshGarages()
            GarageDB.RefreshCompanies()
            GarageDB.ready = true
            print('^2[core_garage]^7 Base de données prête.')
            TriggerEvent('core_garage:server:dbReady')
        end
    end)
end)

--- Helpers CRUD garage
function GarageDB.GetGarage(name)
    return GarageDB.garages[name]
end

function GarageDB.GetGarageById(id)
    return GarageDB.garagesById[tonumber(id)]
end

function GarageDB.GetPublicGarages()
    local list = {}
    for _, g in pairs(GarageDB.garages) do
        list[#list + 1] = g
    end
    table.sort(list, function(a, b) return (a.id or 0) < (b.id or 0) end)
    return list
end
