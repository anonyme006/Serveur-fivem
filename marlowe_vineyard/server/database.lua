MarloweDB = MarloweDB or {}

local DatabaseReady = false

local function ensureTables()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `marlowe_stats` (
            `citizenid` VARCHAR(50) NOT NULL,
            `grapes_harvested` INT NOT NULL DEFAULT 0,
            `bottles_produced` INT NOT NULL DEFAULT 0,
            `deliveries_completed` INT NOT NULL DEFAULT 0,
            `revenue_generated` INT NOT NULL DEFAULT 0,
            `hours_worked` INT NOT NULL DEFAULT 0,
            `duty_started_at` INT NULL DEFAULT NULL,
            PRIMARY KEY (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `marlowe_orders` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `client_name` VARCHAR(100) NOT NULL,
            `product_item` VARCHAR(50) NOT NULL,
            `product_label` VARCHAR(100) NOT NULL,
            `quantity` INT NOT NULL DEFAULT 1,
            `price` INT NOT NULL DEFAULT 0,
            `destination_label` VARCHAR(100) NOT NULL,
            `destination_x` FLOAT NOT NULL,
            `destination_y` FLOAT NOT NULL,
            `destination_z` FLOAT NOT NULL,
            `status` VARCHAR(20) NOT NULL DEFAULT 'pending',
            `assigned_citizenid` VARCHAR(50) NULL DEFAULT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `marlowe_finances` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `type` ENUM('income', 'expense') NOT NULL,
            `amount` INT NOT NULL,
            `reason` VARCHAR(255) NOT NULL,
            `citizenid` VARCHAR(50) NULL DEFAULT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    DatabaseReady = true
end

CreateThread(function()
    ensureTables()
end)

---@return boolean
function MarloweDB.IsReady()
    return DatabaseReady
end

---@param citizenid string
---@return table
function MarloweDB.GetStats(citizenid)
    local row = MySQL.single.await('SELECT * FROM marlowe_stats WHERE citizenid = ?', { citizenid })
    if row then return row end

    MySQL.insert.await('INSERT INTO marlowe_stats (citizenid) VALUES (?)', { citizenid })
    return {
        citizenid = citizenid,
        grapes_harvested = 0,
        bottles_produced = 0,
        deliveries_completed = 0,
        revenue_generated = 0,
        hours_worked = 0,
        duty_started_at = nil,
    }
end

---@param citizenid string
---@param field string
---@param amount number
function MarloweDB.IncrementStat(citizenid, field, amount)
    MarloweDB.GetStats(citizenid)
    MySQL.update.await(('UPDATE marlowe_stats SET %s = %s + ? WHERE citizenid = ?'):format(field, field), {
        amount,
        citizenid,
    })
end

---@param citizenid string
---@param timestamp number|nil
function MarloweDB.SetDutyStartedAt(citizenid, timestamp)
    MarloweDB.GetStats(citizenid)
    MySQL.update.await('UPDATE marlowe_stats SET duty_started_at = ? WHERE citizenid = ?', {
        timestamp,
        citizenid,
    })
end

---@param citizenid string
---@param seconds number
function MarloweDB.AddHoursWorked(citizenid, seconds)
    MarloweDB.IncrementStat(citizenid, 'hours_worked', seconds)
end

---@return table[]
function MarloweDB.GetOrders(statusFilter)
    if statusFilter then
        return MySQL.query.await('SELECT * FROM marlowe_orders WHERE status = ? ORDER BY id DESC', { statusFilter }) or {}
    end
    return MySQL.query.await('SELECT * FROM marlowe_orders ORDER BY id DESC') or {}
end

---@param orderId number
---@return table|nil
function MarloweDB.GetOrder(orderId)
    return MySQL.single.await('SELECT * FROM marlowe_orders WHERE id = ?', { orderId })
end

---@param data table
---@return number
function MarloweDB.CreateOrder(data)
    return MySQL.insert.await([[
        INSERT INTO marlowe_orders
        (client_name, product_item, product_label, quantity, price, destination_label, destination_x, destination_y, destination_z, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.client_name,
        data.product_item,
        data.product_label,
        data.quantity,
        data.price,
        data.destination_label,
        data.destination_x,
        data.destination_y,
        data.destination_z,
        data.status or 'pending',
    })
end

---@param orderId number
---@param status string
---@param assignedCitizenid? string
function MarloweDB.UpdateOrderStatus(orderId, status, assignedCitizenid)
    if assignedCitizenid then
        MySQL.update.await('UPDATE marlowe_orders SET status = ?, assigned_citizenid = ? WHERE id = ?', {
            status,
            assignedCitizenid,
            orderId,
        })
        return
    end

    MySQL.update.await('UPDATE marlowe_orders SET status = ? WHERE id = ?', {
        status,
        orderId,
    })
end

---@param entry table
function MarloweDB.AddFinanceEntry(entry)
    MySQL.insert.await('INSERT INTO marlowe_finances (type, amount, reason, citizenid) VALUES (?, ?, ?, ?)', {
        entry.type,
        entry.amount,
        entry.reason,
        entry.citizenid,
    })
end

---@return table
function MarloweDB.GetFinanceSummary()
    local income = MySQL.scalar.await("SELECT COALESCE(SUM(amount), 0) FROM marlowe_finances WHERE type = 'income'") or 0
    local expense = MySQL.scalar.await("SELECT COALESCE(SUM(amount), 0) FROM marlowe_finances WHERE type = 'expense'") or 0
    return {
        income = income,
        expense = expense,
        turnover = income,
    }
end
