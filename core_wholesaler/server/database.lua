--[[
    Database bootstrap — core_wholesaler
    Crée les tables et synchronise les produits depuis Config.
]]

local SCHEMA = {
    [[CREATE TABLE IF NOT EXISTS `wholesaler_products` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
        `item` VARCHAR(64) NOT NULL,
        `label` VARCHAR(128) NOT NULL,
        `category` VARCHAR(64) NOT NULL,
        `price` INT UNSIGNED NOT NULL DEFAULT 0,
        `image` VARCHAR(128) DEFAULT NULL,
        `requires_ammo` TINYINT(1) NOT NULL DEFAULT 0,
        `active` TINYINT(1) NOT NULL DEFAULT 1,
        `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_item` (`item`),
        KEY `idx_category` (`category`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],

    [[CREATE TABLE IF NOT EXISTS `wholesaler_stock` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
        `item` VARCHAR(64) NOT NULL,
        `quantity` INT NOT NULL DEFAULT 0,
        `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_stock_item` (`item`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],

    [[CREATE TABLE IF NOT EXISTS `wholesaler_orders` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
        `citizenid` VARCHAR(64) NOT NULL,
        `company` VARCHAR(64) NOT NULL,
        `items` LONGTEXT NOT NULL,
        `subtotal` INT UNSIGNED NOT NULL DEFAULT 0,
        `tax` INT UNSIGNED NOT NULL DEFAULT 0,
        `vat` INT UNSIGNED NOT NULL DEFAULT 0,
        `total` INT UNSIGNED NOT NULL DEFAULT 0,
        `payment_method` VARCHAR(32) NOT NULL DEFAULT 'society',
        `fulfillment` VARCHAR(32) NOT NULL DEFAULT 'pickup',
        `status` VARCHAR(32) NOT NULL DEFAULT 'pending',
        `delivery_citizenid` VARCHAR(64) DEFAULT NULL,
        `delivery_reward` INT UNSIGNED DEFAULT 0,
        `delivery_coords` TEXT DEFAULT NULL,
        `prepared_at` TIMESTAMP NULL DEFAULT NULL,
        `available_at` TIMESTAMP NULL DEFAULT NULL,
        `completed_at` TIMESTAMP NULL DEFAULT NULL,
        `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        KEY `idx_citizenid` (`citizenid`),
        KEY `idx_company` (`company`),
        KEY `idx_status` (`status`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],

    [[CREATE TABLE IF NOT EXISTS `wholesaler_history` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
        `order_id` INT UNSIGNED DEFAULT NULL,
        `citizenid` VARCHAR(64) NOT NULL,
        `company` VARCHAR(64) NOT NULL,
        `action` VARCHAR(64) NOT NULL,
        `details` LONGTEXT DEFAULT NULL,
        `amount` INT DEFAULT 0,
        `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        KEY `idx_hist_citizen` (`citizenid`),
        KEY `idx_hist_company` (`company`),
        KEY `idx_hist_order` (`order_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],

    [[CREATE TABLE IF NOT EXISTS `wholesaler_employees` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
        `citizenid` VARCHAR(64) NOT NULL,
        `name` VARCHAR(128) NOT NULL,
        `grade` INT NOT NULL DEFAULT 0,
        `hired_by` VARCHAR(64) DEFAULT NULL,
        `hired_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `active` TINYINT(1) NOT NULL DEFAULT 1,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_emp_citizen` (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],

    [[CREATE TABLE IF NOT EXISTS `wholesaler_companies` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
        `job` VARCHAR(64) NOT NULL,
        `label` VARCHAR(128) NOT NULL,
        `total_spent` BIGINT NOT NULL DEFAULT 0,
        `order_count` INT UNSIGNED NOT NULL DEFAULT 0,
        `last_order_at` TIMESTAMP NULL DEFAULT NULL,
        `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_company_job` (`job`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],

    [[CREATE TABLE IF NOT EXISTS `wholesaler_exports` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
        `citizenid` VARCHAR(64) NOT NULL,
        `destination` VARCHAR(64) NOT NULL,
        `items` LONGTEXT NOT NULL,
        `value` INT UNSIGNED NOT NULL DEFAULT 0,
        `reward` INT UNSIGNED NOT NULL DEFAULT 0,
        `status` VARCHAR(32) NOT NULL DEFAULT 'active',
        `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `completed_at` TIMESTAMP NULL DEFAULT NULL,
        PRIMARY KEY (`id`),
        KEY `idx_export_citizen` (`citizenid`),
        KEY `idx_export_status` (`status`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],
}

DB = {}

--- Initialise le schéma SQL
function DB.Init()
    for i = 1, #SCHEMA do
        MySQL.query.await(SCHEMA[i])
    end
    Wholesaler.Debug('SQL schema ready')
end

--- Synchronise Config.Categories → wholesaler_products + wholesaler_stock
function DB.SyncProducts()
    for catId, cat in pairs(Config.Categories) do
        for _, product in ipairs(cat.products) do
            MySQL.insert.await([[
                INSERT INTO wholesaler_products (item, label, category, price, image, requires_ammo, active)
                VALUES (?, ?, ?, ?, ?, ?, 1)
                ON DUPLICATE KEY UPDATE
                    label = VALUES(label),
                    category = VALUES(category),
                    image = VALUES(image),
                    requires_ammo = VALUES(requires_ammo),
                    active = 1
            ]], {
                product.item,
                product.label,
                catId,
                product.price,
                product.image or product.item,
                product.requiresAmmoAuth and 1 or 0,
            })

            -- Ne touche pas le stock existant ; initialise seulement si absent
            MySQL.insert.await([[
                INSERT IGNORE INTO wholesaler_stock (item, quantity)
                VALUES (?, ?)
            ]], { product.item, product.stock or 0 })
        end
    end
    Wholesaler.Debug('Products synced from config')
end

--- Log d'historique
---@param data table
function DB.LogHistory(data)
    MySQL.insert('INSERT INTO wholesaler_history (order_id, citizenid, company, action, details, amount) VALUES (?, ?, ?, ?, ?, ?)', {
        data.orderId or nil,
        data.citizenid,
        data.company or 'system',
        data.action,
        data.details and json.encode(data.details) or nil,
        data.amount or 0,
    })
end

--- Upsert stats entreprise cliente
---@param job string
---@param label string
---@param amount number
function DB.UpsertCompany(job, label, amount)
    MySQL.insert.await([[
        INSERT INTO wholesaler_companies (job, label, total_spent, order_count, last_order_at)
        VALUES (?, ?, ?, 1, NOW())
        ON DUPLICATE KEY UPDATE
            label = VALUES(label),
            total_spent = total_spent + VALUES(total_spent),
            order_count = order_count + 1,
            last_order_at = NOW()
    ]], { job, label, amount })
end
