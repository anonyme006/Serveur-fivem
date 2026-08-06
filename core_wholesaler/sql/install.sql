--[[
    core_wholesaler — Schéma SQL
    Tables créées automatiquement au démarrage (voir server/database.lua).
    Ce fichier sert de référence / installation manuelle.
]]

CREATE TABLE IF NOT EXISTS `wholesaler_products` (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `wholesaler_stock` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `item` VARCHAR(64) NOT NULL,
    `quantity` INT NOT NULL DEFAULT 0,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_stock_item` (`item`),
    CONSTRAINT `fk_stock_product` FOREIGN KEY (`item`) REFERENCES `wholesaler_products` (`item`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `wholesaler_orders` (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `wholesaler_history` (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `wholesaler_employees` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(64) NOT NULL,
    `name` VARCHAR(128) NOT NULL,
    `grade` INT NOT NULL DEFAULT 0,
    `hired_by` VARCHAR(64) DEFAULT NULL,
    `hired_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_emp_citizen` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `wholesaler_companies` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `job` VARCHAR(64) NOT NULL,
    `label` VARCHAR(128) NOT NULL,
    `total_spent` BIGINT NOT NULL DEFAULT 0,
    `order_count` INT UNSIGNED NOT NULL DEFAULT 0,
    `last_order_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_company_job` (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `wholesaler_exports` (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
