CREATE TABLE IF NOT EXISTS `shopcreator_shops` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `slug` VARCHAR(48) NOT NULL,
    `name` VARCHAR(96) NOT NULL,
    `description` VARCHAR(512) NULL DEFAULT NULL,
    `logo_url` VARCHAR(512) NULL DEFAULT NULL,
    `enabled` TINYINT(1) NOT NULL DEFAULT 1,
    `infinite_stock` TINYINT(1) NOT NULL DEFAULT 0,
    `default_stock` INT NOT NULL DEFAULT 0,
    `storage_capacity` INT NOT NULL DEFAULT 500,
    `auto_hours` TINYINT(1) NOT NULL DEFAULT 0,
    `open_hour` DECIMAL(4,2) NOT NULL DEFAULT 8.00,
    `close_hour` DECIMAL(4,2) NOT NULL DEFAULT 22.00,
    `is_open` TINYINT(1) NOT NULL DEFAULT 1,
    `ownership_mode` ENUM('none','purchasable','owned') NOT NULL DEFAULT 'none',
    `owner_citizenid` VARCHAR(64) NULL DEFAULT NULL,
    `buy_price` INT UNSIGNED NOT NULL DEFAULT 0,
    `resale_enabled` TINYINT(1) NOT NULL DEFAULT 0,
    `resale_percent` DECIMAL(5,2) NOT NULL DEFAULT 70.00,
    `balance` BIGINT NOT NULL DEFAULT 0,
    `allow_cash` TINYINT(1) NOT NULL DEFAULT 1,
    `allow_bank` TINYINT(1) NOT NULL DEFAULT 1,
    `blip_enabled` TINYINT(1) NOT NULL DEFAULT 1,
    `blip_sprite` INT NOT NULL DEFAULT 52,
    `blip_color` INT NOT NULL DEFAULT 2,
    `blip_scale` DECIMAL(4,2) NOT NULL DEFAULT 0.75,
    `blip_name` VARCHAR(96) NULL DEFAULT NULL,
    `npc_enabled` TINYINT(1) NOT NULL DEFAULT 0,
    `npc_model` VARCHAR(64) NULL DEFAULT NULL,
    `npc_scenario` VARCHAR(96) NULL DEFAULT NULL,
    `npc_x` FLOAT NULL DEFAULT NULL,
    `npc_y` FLOAT NULL DEFAULT NULL,
    `npc_z` FLOAT NULL DEFAULT NULL,
    `npc_w` FLOAT NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_shop_slug` (`slug`),
    KEY `idx_shop_owner` (`owner_citizenid`),
    KEY `idx_shop_enabled` (`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `shopcreator_locations` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `shop_id` INT UNSIGNED NOT NULL,
    `location_type` ENUM('customer','management','storage','delivery','garage','vehicle_spawn','vehicle_return') NOT NULL,
    `label` VARCHAR(96) NULL DEFAULT NULL,
    `x` FLOAT NOT NULL,
    `y` FLOAT NOT NULL,
    `z` FLOAT NOT NULL,
    `w` FLOAT NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_loc_shop_type` (`shop_id`, `location_type`),
    CONSTRAINT `fk_loc_shop` FOREIGN KEY (`shop_id`) REFERENCES `shopcreator_shops` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `shopcreator_categories` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `shop_id` INT UNSIGNED NOT NULL,
    `label` VARCHAR(96) NOT NULL,
    `icon` VARCHAR(64) NULL DEFAULT 'package',
    `sort_order` INT NOT NULL DEFAULT 0,
    `enabled` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_cat_shop_order` (`shop_id`, `sort_order`),
    CONSTRAINT `fk_cat_shop` FOREIGN KEY (`shop_id`) REFERENCES `shopcreator_shops` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `shopcreator_products` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `shop_id` INT UNSIGNED NOT NULL,
    `category_id` INT UNSIGNED NULL DEFAULT NULL,
    `item_name` VARCHAR(64) NOT NULL,
    `label` VARCHAR(96) NULL DEFAULT NULL,
    `image` VARCHAR(512) NULL DEFAULT NULL,
    `price` INT UNSIGNED NOT NULL DEFAULT 0,
    `wholesale_price` INT UNSIGNED NOT NULL DEFAULT 0,
    `stock` INT NOT NULL DEFAULT 0,
    `max_stock` INT NOT NULL DEFAULT 100,
    `enabled` TINYINT(1) NOT NULL DEFAULT 1,
    `sort_order` INT NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_shop_item` (`shop_id`, `item_name`),
    KEY `idx_prod_shop_cat` (`shop_id`, `category_id`),
    KEY `idx_prod_enabled` (`shop_id`, `enabled`),
    CONSTRAINT `fk_prod_shop` FOREIGN KEY (`shop_id`) REFERENCES `shopcreator_shops` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_prod_category` FOREIGN KEY (`category_id`) REFERENCES `shopcreator_categories` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `shopcreator_employees` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `shop_id` INT UNSIGNED NOT NULL,
    `citizenid` VARCHAR(64) NOT NULL,
    `name` VARCHAR(96) NOT NULL,
    `permissions` LONGTEXT NOT NULL,
    `active` TINYINT(1) NOT NULL DEFAULT 1,
    `hired_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_shop_employee` (`shop_id`, `citizenid`),
    KEY `idx_emp_citizen` (`citizenid`),
    CONSTRAINT `fk_emp_shop` FOREIGN KEY (`shop_id`) REFERENCES `shopcreator_shops` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `shopcreator_transactions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `shop_id` INT UNSIGNED NOT NULL,
    `tx_type` VARCHAR(32) NOT NULL,
    `amount` BIGINT NOT NULL DEFAULT 0,
    `citizenid` VARCHAR(64) NULL DEFAULT NULL,
    `player_name` VARCHAR(96) NULL DEFAULT NULL,
    `description` VARCHAR(255) NULL DEFAULT NULL,
    `meta` LONGTEXT NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_tx_shop_type` (`shop_id`, `tx_type`),
    KEY `idx_tx_created` (`shop_id`, `created_at`),
    CONSTRAINT `fk_tx_shop` FOREIGN KEY (`shop_id`) REFERENCES `shopcreator_shops` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `shopcreator_stock_orders` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `shop_id` INT UNSIGNED NOT NULL,
    `ordered_by` VARCHAR(64) NOT NULL,
    `ordered_by_name` VARCHAR(96) NULL DEFAULT NULL,
    `method` ENUM('instant','self','public') NOT NULL,
    `status` ENUM('pending','accepted','in_transit','delivered','cancelled') NOT NULL DEFAULT 'pending',
    `total_cost` INT UNSIGNED NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_order_shop_status` (`shop_id`, `status`),
    CONSTRAINT `fk_order_shop` FOREIGN KEY (`shop_id`) REFERENCES `shopcreator_shops` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `shopcreator_stock_order_items` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `order_id` INT UNSIGNED NOT NULL,
    `product_id` INT UNSIGNED NOT NULL,
    `item_name` VARCHAR(64) NOT NULL,
    `quantity` INT UNSIGNED NOT NULL,
    `unit_cost` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_order_items` (`order_id`),
    CONSTRAINT `fk_order_items_order` FOREIGN KEY (`order_id`) REFERENCES `shopcreator_stock_orders` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `shopcreator_delivery_jobs` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `order_id` INT UNSIGNED NOT NULL,
    `shop_id` INT UNSIGNED NOT NULL,
    `status` ENUM('open','accepted','completed','cancelled') NOT NULL DEFAULT 'open',
    `reward` INT UNSIGNED NOT NULL DEFAULT 0,
    `accepted_by` VARCHAR(64) NULL DEFAULT NULL,
    `accepted_by_name` VARCHAR(96) NULL DEFAULT NULL,
    `origin_x` FLOAT NOT NULL,
    `origin_y` FLOAT NOT NULL,
    `origin_z` FLOAT NOT NULL,
    `dest_x` FLOAT NOT NULL,
    `dest_y` FLOAT NOT NULL,
    `dest_z` FLOAT NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_job_order` (`order_id`),
    KEY `idx_job_status` (`status`),
    CONSTRAINT `fk_job_order` FOREIGN KEY (`order_id`) REFERENCES `shopcreator_stock_orders` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_job_shop` FOREIGN KEY (`shop_id`) REFERENCES `shopcreator_shops` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `shopcreator_business_vehicles` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `shop_id` INT UNSIGNED NOT NULL,
    `model` VARCHAR(64) NOT NULL,
    `label` VARCHAR(96) NOT NULL,
    `enabled` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_veh_shop` (`shop_id`),
    CONSTRAINT `fk_veh_shop` FOREIGN KEY (`shop_id`) REFERENCES `shopcreator_shops` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `shopcreator_admins` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(128) NOT NULL,
    `label` VARCHAR(96) NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_admin_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `shopcreator_settings` (
    `setting_key` VARCHAR(64) NOT NULL,
    `setting_value` LONGTEXT NOT NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;