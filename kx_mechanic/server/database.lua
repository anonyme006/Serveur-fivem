Database = {}

local function ensureTables()
    local statements = {
        [[CREATE TABLE IF NOT EXISTS `kx_mechanic_vehicles` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `plate` VARCHAR(12) NOT NULL,
            `engine_health` FLOAT NOT NULL DEFAULT 1000.0,
            `body_health` FLOAT NOT NULL DEFAULT 1000.0,
            `brakes_health` FLOAT NOT NULL DEFAULT 100.0,
            `transmission_health` FLOAT NOT NULL DEFAULT 100.0,
            `suspension_health` FLOAT NOT NULL DEFAULT 100.0,
            `clutch_health` FLOAT NOT NULL DEFAULT 100.0,
            `radiator_level` FLOAT NOT NULL DEFAULT 100.0,
            `oil_level` FLOAT NOT NULL DEFAULT 100.0,
            `battery_level` FLOAT NOT NULL DEFAULT 100.0,
            `spark_plugs` FLOAT NOT NULL DEFAULT 100.0,
            `tire_fl` FLOAT NOT NULL DEFAULT 100.0,
            `tire_fr` FLOAT NOT NULL DEFAULT 100.0,
            `tire_rl` FLOAT NOT NULL DEFAULT 100.0,
            `tire_rr` FLOAT NOT NULL DEFAULT 100.0,
            `tire_type` VARCHAR(32) NOT NULL DEFAULT 'stock',
            `fuel` FLOAT NOT NULL DEFAULT 100.0,
            `engine_temp` FLOAT NOT NULL DEFAULT 90.0,
            `mileage` FLOAT NOT NULL DEFAULT 0.0,
            `last_service` TIMESTAMP NULL DEFAULT NULL,
            `performance` LONGTEXT NULL,
            `cosmetics` LONGTEXT NULL,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `ux_kx_mechanic_vehicles_plate` (`plate`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],
        [[CREATE TABLE IF NOT EXISTS `kx_mechanic_repairs` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `plate` VARCHAR(12) NOT NULL,
            `vehicle_model` VARCHAR(64) NULL,
            `customer_citizenid` VARCHAR(64) NULL,
            `customer_name` VARCHAR(128) NULL,
            `mechanic_citizenid` VARCHAR(64) NOT NULL,
            `mechanic_name` VARCHAR(128) NOT NULL,
            `repair_type` VARCHAR(64) NOT NULL,
            `repair_label` VARCHAR(128) NOT NULL,
            `price` INT NOT NULL DEFAULT 0,
            `parts_used` LONGTEXT NULL,
            `notes` TEXT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_kx_mechanic_repairs_plate` (`plate`),
            KEY `idx_kx_mechanic_repairs_created` (`created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],
        [[CREATE TABLE IF NOT EXISTS `kx_mechanic_invoices` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `invoice_number` VARCHAR(32) NOT NULL,
            `mechanic_citizenid` VARCHAR(64) NOT NULL,
            `mechanic_name` VARCHAR(128) NOT NULL,
            `customer_citizenid` VARCHAR(64) NOT NULL,
            `customer_name` VARCHAR(128) NOT NULL,
            `customer_source` INT NULL,
            `items` LONGTEXT NOT NULL,
            `total` INT NOT NULL DEFAULT 0,
            `status` ENUM('pending','paid','cancelled','declined') NOT NULL DEFAULT 'pending',
            `paid_at` TIMESTAMP NULL DEFAULT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `ux_kx_mechanic_invoices_number` (`invoice_number`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],
        [[CREATE TABLE IF NOT EXISTS `kx_mechanic_orders` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `order_number` VARCHAR(32) NOT NULL,
            `supplier` VARCHAR(64) NOT NULL,
            `product` VARCHAR(64) NOT NULL,
            `product_label` VARCHAR(128) NOT NULL,
            `quantity` INT NOT NULL DEFAULT 1,
            `unit_price` INT NOT NULL DEFAULT 0,
            `total_price` INT NOT NULL DEFAULT 0,
            `status` ENUM('pending','preparing','shipping','delivered','cancelled') NOT NULL DEFAULT 'pending',
            `ordered_by` VARCHAR(64) NOT NULL,
            `ordered_by_name` VARCHAR(128) NOT NULL,
            `delivered_at` TIMESTAMP NULL DEFAULT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `ux_kx_mechanic_orders_number` (`order_number`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],
        [[CREATE TABLE IF NOT EXISTS `kx_mechanic_stock_log` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `action` ENUM('deposit','withdraw','consume','order_delivery','adjust') NOT NULL,
            `item` VARCHAR(64) NOT NULL,
            `amount` INT NOT NULL,
            `citizenid` VARCHAR(64) NULL,
            `player_name` VARCHAR(128) NULL,
            `reason` VARCHAR(255) NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],
        [[CREATE TABLE IF NOT EXISTS `kx_mechanic_stats` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `stat_date` DATE NOT NULL,
            `revenue` INT NOT NULL DEFAULT 0,
            `repairs_count` INT NOT NULL DEFAULT 0,
            `vehicles_count` INT NOT NULL DEFAULT 0,
            `parts_used` INT NOT NULL DEFAULT 0,
            `mechanic_citizenid` VARCHAR(64) NULL,
            `mechanic_name` VARCHAR(128) NULL,
            `mechanic_revenue` INT NOT NULL DEFAULT 0,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `ux_kx_mechanic_stats_day_mech` (`stat_date`, `mechanic_citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],
        [[CREATE TABLE IF NOT EXISTS `kx_mechanic_employees` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `citizenid` VARCHAR(64) NOT NULL,
            `name` VARCHAR(128) NOT NULL,
            `grade` TINYINT UNSIGNED NOT NULL DEFAULT 0,
            `salary` INT NOT NULL DEFAULT 0,
            `hired_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `hired_by` VARCHAR(64) NULL,
            `active` TINYINT(1) NOT NULL DEFAULT 1,
            PRIMARY KEY (`id`),
            UNIQUE KEY `ux_kx_mechanic_employees_citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],
    }

    for i = 1, #statements do
        MySQL.query.await(statements[i])
    end
end

function Database.Init()
    ensureTables()
    Utils.Debug('Database tables ready')
end

function Database.GetVehicle(plate)
    plate = Utils.NormalizePlate(plate)
    if not plate then return nil end

    local row = MySQL.single.await('SELECT * FROM kx_mechanic_vehicles WHERE plate = ? LIMIT 1', { plate })
    if not row then return nil end

    row.performance = Utils.DecodeJson(row.performance, Utils.DeepCopy(Config.DefaultVehicleData.performance))
    row.cosmetics = Utils.DecodeJson(row.cosmetics, Utils.DeepCopy(Config.DefaultVehicleData.cosmetics))
    return row
end

function Database.UpsertVehicle(plate, data)
    plate = Utils.NormalizePlate(plate)
    if not plate or type(data) ~= 'table' then return false end

    local merged = Utils.MergeDefaults(data)
    MySQL.insert.await([[
        INSERT INTO kx_mechanic_vehicles
        (plate, engine_health, body_health, brakes_health, transmission_health, suspension_health, clutch_health,
         radiator_level, oil_level, battery_level, spark_plugs, tire_fl, tire_fr, tire_rl, tire_rr, tire_type,
         fuel, engine_temp, mileage, last_service, performance, cosmetics)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
         engine_health = VALUES(engine_health),
         body_health = VALUES(body_health),
         brakes_health = VALUES(brakes_health),
         transmission_health = VALUES(transmission_health),
         suspension_health = VALUES(suspension_health),
         clutch_health = VALUES(clutch_health),
         radiator_level = VALUES(radiator_level),
         oil_level = VALUES(oil_level),
         battery_level = VALUES(battery_level),
         spark_plugs = VALUES(spark_plugs),
         tire_fl = VALUES(tire_fl),
         tire_fr = VALUES(tire_fr),
         tire_rl = VALUES(tire_rl),
         tire_rr = VALUES(tire_rr),
         tire_type = VALUES(tire_type),
         fuel = VALUES(fuel),
         engine_temp = VALUES(engine_temp),
         mileage = VALUES(mileage),
         last_service = VALUES(last_service),
         performance = VALUES(performance),
         cosmetics = VALUES(cosmetics)
    ]], {
        plate,
        merged.engine_health,
        merged.body_health,
        merged.brakes_health,
        merged.transmission_health,
        merged.suspension_health,
        merged.clutch_health,
        merged.radiator_level,
        merged.oil_level,
        merged.battery_level,
        merged.spark_plugs,
        merged.tire_fl,
        merged.tire_fr,
        merged.tire_rl,
        merged.tire_rr,
        merged.tire_type,
        merged.fuel,
        merged.engine_temp,
        merged.mileage,
        merged.last_service,
        Utils.EncodeJson(merged.performance),
        Utils.EncodeJson(merged.cosmetics),
    })

    return true
end

function Database.MarkServiced(plate)
    plate = Utils.NormalizePlate(plate)
    if not plate then return end
    MySQL.update.await('UPDATE kx_mechanic_vehicles SET last_service = CURRENT_TIMESTAMP WHERE plate = ?', { plate })
end

function Database.LogRepair(entry)
    return MySQL.insert.await([[
        INSERT INTO kx_mechanic_repairs
        (plate, vehicle_model, customer_citizenid, customer_name, mechanic_citizenid, mechanic_name,
         repair_type, repair_label, price, parts_used, notes)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        Utils.NormalizePlate(entry.plate),
        entry.vehicle_model,
        entry.customer_citizenid,
        entry.customer_name,
        entry.mechanic_citizenid,
        entry.mechanic_name,
        entry.repair_type,
        entry.repair_label,
        entry.price or 0,
        Utils.EncodeJson(entry.parts_used or {}),
        entry.notes,
    })
end

function Database.GetRepairHistory(limit, plate)
    limit = tonumber(limit) or 50
    if plate then
        return MySQL.query.await(
            'SELECT * FROM kx_mechanic_repairs WHERE plate = ? ORDER BY created_at DESC LIMIT ?',
            { Utils.NormalizePlate(plate), limit }
        ) or {}
    end
    return MySQL.query.await('SELECT * FROM kx_mechanic_repairs ORDER BY created_at DESC LIMIT ?', { limit }) or {}
end

function Database.CreateInvoice(entry)
    return MySQL.insert.await([[
        INSERT INTO kx_mechanic_invoices
        (invoice_number, mechanic_citizenid, mechanic_name, customer_citizenid, customer_name, customer_source, items, total, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending')
    ]], {
        entry.invoice_number,
        entry.mechanic_citizenid,
        entry.mechanic_name,
        entry.customer_citizenid,
        entry.customer_name,
        entry.customer_source,
        Utils.EncodeJson(entry.items),
        entry.total,
    })
end

function Database.GetInvoice(id)
    local row = MySQL.single.await('SELECT * FROM kx_mechanic_invoices WHERE id = ? LIMIT 1', { id })
    if not row then return nil end
    row.items = Utils.DecodeJson(row.items, {})
    return row
end

function Database.GetInvoiceByNumber(number)
    local row = MySQL.single.await('SELECT * FROM kx_mechanic_invoices WHERE invoice_number = ? LIMIT 1', { number })
    if not row then return nil end
    row.items = Utils.DecodeJson(row.items, {})
    return row
end

function Database.UpdateInvoiceStatus(id, status)
    if status == 'paid' then
        return MySQL.update.await(
            'UPDATE kx_mechanic_invoices SET status = ?, paid_at = CURRENT_TIMESTAMP WHERE id = ? AND status = \'pending\'',
            { status, id }
        )
    end
    return MySQL.update.await(
        'UPDATE kx_mechanic_invoices SET status = ? WHERE id = ? AND status = \'pending\'',
        { status, id }
    )
end

function Database.CreateOrder(entry)
    return MySQL.insert.await([[
        INSERT INTO kx_mechanic_orders
        (order_number, supplier, product, product_label, quantity, unit_price, total_price, status, ordered_by, ordered_by_name)
        VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', ?, ?)
    ]], {
        entry.order_number,
        entry.supplier,
        entry.product,
        entry.product_label,
        entry.quantity,
        entry.unit_price,
        entry.total_price,
        entry.ordered_by,
        entry.ordered_by_name,
    })
end

function Database.UpdateOrderStatus(id, status)
    if status == 'delivered' then
        return MySQL.update.await(
            'UPDATE kx_mechanic_orders SET status = ?, delivered_at = CURRENT_TIMESTAMP WHERE id = ?',
            { status, id }
        )
    end
    return MySQL.update.await('UPDATE kx_mechanic_orders SET status = ? WHERE id = ?', { status, id })
end

function Database.GetOrders(limit)
    return MySQL.query.await('SELECT * FROM kx_mechanic_orders ORDER BY created_at DESC LIMIT ?', { tonumber(limit) or 50 }) or {}
end

function Database.GetOrder(id)
    return MySQL.single.await('SELECT * FROM kx_mechanic_orders WHERE id = ? LIMIT 1', { id })
end

function Database.LogStock(action, item, amount, citizenid, playerName, reason)
    MySQL.insert.await([[
        INSERT INTO kx_mechanic_stock_log (action, item, amount, citizenid, player_name, reason)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], { action, item, amount, citizenid, playerName, reason })
end

function Database.GetStockLog(limit)
    return MySQL.query.await('SELECT * FROM kx_mechanic_stock_log ORDER BY created_at DESC LIMIT ?', { tonumber(limit) or 50 }) or {}
end

function Database.UpsertEmployee(citizenid, name, grade, salary, hiredBy)
    MySQL.insert.await([[
        INSERT INTO kx_mechanic_employees (citizenid, name, grade, salary, hired_by, active)
        VALUES (?, ?, ?, ?, ?, 1)
        ON DUPLICATE KEY UPDATE name = VALUES(name), grade = VALUES(grade), salary = VALUES(salary), active = 1
    ]], { citizenid, name, grade, salary or 0, hiredBy })
end

function Database.SetEmployeeActive(citizenid, active)
    MySQL.update.await('UPDATE kx_mechanic_employees SET active = ? WHERE citizenid = ?', { active and 1 or 0, citizenid })
end

function Database.UpdateEmployeeGrade(citizenid, grade, salary)
    MySQL.update.await('UPDATE kx_mechanic_employees SET grade = ?, salary = ? WHERE citizenid = ?', {
        grade,
        salary or (Config.Grades[grade] and Config.Grades[grade].salary or 0),
        citizenid,
    })
end

function Database.GetEmployees()
    return MySQL.query.await('SELECT * FROM kx_mechanic_employees WHERE active = 1 ORDER BY grade DESC, name ASC') or {}
end

function Database.RecordStats(mechanicCitizenId, mechanicName, revenue, repairs, vehicles, parts)
    local today = os.date('%Y-%m-%d')
    MySQL.insert.await([[
        INSERT INTO kx_mechanic_stats
        (stat_date, revenue, repairs_count, vehicles_count, parts_used, mechanic_citizenid, mechanic_name, mechanic_revenue)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            revenue = revenue + VALUES(revenue),
            repairs_count = repairs_count + VALUES(repairs_count),
            vehicles_count = vehicles_count + VALUES(vehicles_count),
            parts_used = parts_used + VALUES(parts_used),
            mechanic_name = VALUES(mechanic_name),
            mechanic_revenue = mechanic_revenue + VALUES(mechanic_revenue)
    ]], {
        today,
        revenue or 0,
        repairs or 0,
        vehicles or 0,
        parts or 0,
        mechanicCitizenId,
        mechanicName,
        revenue or 0,
    })
end

function Database.GetDashboard()
    local today = os.date('%Y-%m-%d')
    local weekAgo = os.date('%Y-%m-%d', os.time() - 7 * 86400)
    local monthAgo = os.date('%Y-%m-%d', os.time() - 30 * 86400)

    local day = MySQL.single.await([[
        SELECT COALESCE(SUM(revenue), 0) AS revenue,
               COALESCE(SUM(repairs_count), 0) AS repairs,
               COALESCE(SUM(vehicles_count), 0) AS vehicles,
               COALESCE(SUM(parts_used), 0) AS parts
        FROM kx_mechanic_stats WHERE stat_date = ?
    ]], { today }) or { revenue = 0, repairs = 0, vehicles = 0, parts = 0 }

    local week = MySQL.single.await([[
        SELECT COALESCE(SUM(revenue), 0) AS revenue,
               COALESCE(SUM(repairs_count), 0) AS repairs,
               COALESCE(SUM(vehicles_count), 0) AS vehicles
        FROM kx_mechanic_stats WHERE stat_date >= ?
    ]], { weekAgo }) or { revenue = 0, repairs = 0, vehicles = 0 }

    local month = MySQL.single.await([[
        SELECT COALESCE(SUM(revenue), 0) AS revenue,
               COALESCE(SUM(repairs_count), 0) AS repairs,
               COALESCE(SUM(vehicles_count), 0) AS vehicles
        FROM kx_mechanic_stats WHERE stat_date >= ?
    ]], { monthAgo }) or { revenue = 0, repairs = 0, vehicles = 0 }

    local best = MySQL.single.await([[
        SELECT mechanic_citizenid, mechanic_name, SUM(mechanic_revenue) AS total
        FROM kx_mechanic_stats
        WHERE stat_date >= ? AND mechanic_citizenid IS NOT NULL
        GROUP BY mechanic_citizenid, mechanic_name
        ORDER BY total DESC
        LIMIT 1
    ]], { weekAgo })

    local chart = MySQL.query.await([[
        SELECT stat_date AS day, COALESCE(SUM(revenue), 0) AS revenue, COALESCE(SUM(repairs_count), 0) AS repairs
        FROM kx_mechanic_stats
        WHERE stat_date >= ?
        GROUP BY stat_date
        ORDER BY stat_date ASC
    ]], { weekAgo }) or {}

    local partsUsed = MySQL.query.await([[
        SELECT item, SUM(ABS(amount)) AS total
        FROM kx_mechanic_stock_log
        WHERE action = 'consume' AND created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
        GROUP BY item
        ORDER BY total DESC
        LIMIT 8
    ]]) or {}

    return {
        day = day,
        week = week,
        month = month,
        bestMechanic = best,
        chart = chart,
        partsUsed = partsUsed,
    }
end