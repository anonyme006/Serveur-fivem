CREATE TABLE IF NOT EXISTS `kx_mechanic_vehicles` (
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
    UNIQUE KEY `ux_kx_mechanic_vehicles_plate` (`plate`),
    KEY `idx_kx_mechanic_vehicles_mileage` (`mileage`),
    KEY `idx_kx_mechanic_vehicles_updated` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `kx_mechanic_repairs` (
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
    KEY `idx_kx_mechanic_repairs_mechanic` (`mechanic_citizenid`),
    KEY `idx_kx_mechanic_repairs_created` (`created_at`),
    KEY `idx_kx_mechanic_repairs_type` (`repair_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `kx_mechanic_invoices` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `invoice_number` VARCHAR(32) NOT NULL,
    `mechanic_citizenid` VARCHAR(64) NOT NULL,
    `mechanic_name` VARCHAR(128) NOT NULL,
    `customer_citizenid` VARCHAR(64) NOT NULL,
    `customer_name` VARCHAR(128) NOT NULL,
    `customer_source` INT NULL,
    `items` LONGTEXT NOT NULL,
    `total` INT NOT NULL DEFAULT 0,
    `status` ENUM('pending', 'paid', 'cancelled', 'declined') NOT NULL DEFAULT 'pending',
    `paid_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `ux_kx_mechanic_invoices_number` (`invoice_number`),
    KEY `idx_kx_mechanic_invoices_customer` (`customer_citizenid`),
    KEY `idx_kx_mechanic_invoices_status` (`status`),
    KEY `idx_kx_mechanic_invoices_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `kx_mechanic_orders` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `order_number` VARCHAR(32) NOT NULL,
    `supplier` VARCHAR(64) NOT NULL,
    `product` VARCHAR(64) NOT NULL,
    `product_label` VARCHAR(128) NOT NULL,
    `quantity` INT NOT NULL DEFAULT 1,
    `unit_price` INT NOT NULL DEFAULT 0,
    `total_price` INT NOT NULL DEFAULT 0,
    `status` ENUM('pending', 'preparing', 'shipping', 'delivered', 'cancelled') NOT NULL DEFAULT 'pending',
    `ordered_by` VARCHAR(64) NOT NULL,
    `ordered_by_name` VARCHAR(128) NOT NULL,
    `delivered_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `ux_kx_mechanic_orders_number` (`order_number`),
    KEY `idx_kx_mechanic_orders_status` (`status`),
    KEY `idx_kx_mechanic_orders_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `kx_mechanic_stock_log` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `action` ENUM('deposit', 'withdraw', 'consume', 'order_delivery', 'adjust') NOT NULL,
    `item` VARCHAR(64) NOT NULL,
    `amount` INT NOT NULL,
    `citizenid` VARCHAR(64) NULL,
    `player_name` VARCHAR(128) NULL,
    `reason` VARCHAR(255) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_kx_mechanic_stock_item` (`item`),
    KEY `idx_kx_mechanic_stock_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `kx_mechanic_stats` (
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
    UNIQUE KEY `ux_kx_mechanic_stats_day_mech` (`stat_date`, `mechanic_citizenid`),
    KEY `idx_kx_mechanic_stats_date` (`stat_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `kx_mechanic_employees` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(64) NOT NULL,
    `name` VARCHAR(128) NOT NULL,
    `grade` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `salary` INT NOT NULL DEFAULT 0,
    `hired_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `hired_by` VARCHAR(64) NULL,
    `active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    UNIQUE KEY `ux_kx_mechanic_employees_citizenid` (`citizenid`),
    KEY `idx_kx_mechanic_employees_active` (`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;