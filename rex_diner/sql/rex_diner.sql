CREATE TABLE IF NOT EXISTS `rex_diner_sales` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `restaurant` VARCHAR(64) NOT NULL,
    `employee_identifier` VARCHAR(64) NOT NULL,
    `employee_name` VARCHAR(128) NOT NULL DEFAULT '',
    `customer_identifier` VARCHAR(64) DEFAULT NULL,
    `customer_name` VARCHAR(128) DEFAULT NULL,
    `amount` INT UNSIGNED NOT NULL DEFAULT 0,
    `commission` INT UNSIGNED NOT NULL DEFAULT 0,
    `commission_rate` DECIMAL(5,4) NOT NULL DEFAULT 0.0000,
    `payment_method` VARCHAR(32) NOT NULL DEFAULT 'cash',
    `discount` INT UNSIGNED NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_restaurant_date` (`restaurant`, `created_at`),
    KEY `idx_employee` (`employee_identifier`),
    KEY `idx_customer` (`customer_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rex_diner_sale_items` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `sale_id` INT UNSIGNED NOT NULL,
    `product_id` VARCHAR(64) NOT NULL,
    `product_label` VARCHAR(128) NOT NULL,
    `quantity` INT UNSIGNED NOT NULL DEFAULT 1,
    `unit_price` INT UNSIGNED NOT NULL DEFAULT 0,
    `total_price` INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    KEY `idx_sale` (`sale_id`),
    KEY `idx_product` (`product_id`),
    CONSTRAINT `fk_sale_items_sale`
        FOREIGN KEY (`sale_id`) REFERENCES `rex_diner_sales` (`id`)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rex_diner_employees` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `restaurant` VARCHAR(64) NOT NULL,
    `identifier` VARCHAR(64) NOT NULL,
    `name` VARCHAR(128) NOT NULL DEFAULT '',
    `grade` INT NOT NULL DEFAULT 0,
    `hired_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `total_sales` INT UNSIGNED NOT NULL DEFAULT 0,
    `total_commission` INT UNSIGNED NOT NULL DEFAULT 0,
    `total_service_seconds` INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_restaurant_employee` (`restaurant`, `identifier`),
    KEY `idx_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rex_diner_invoices` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `restaurant` VARCHAR(64) NOT NULL,
    `issuer_identifier` VARCHAR(64) NOT NULL,
    `issuer_name` VARCHAR(128) NOT NULL DEFAULT '',
    `target_identifier` VARCHAR(64) NOT NULL,
    `target_name` VARCHAR(128) NOT NULL DEFAULT '',
    `amount` INT UNSIGNED NOT NULL DEFAULT 0,
    `reason` VARCHAR(255) NOT NULL DEFAULT '',
    `status` ENUM('pending', 'paid', 'cancelled') NOT NULL DEFAULT 'pending',
    `sale_id` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `paid_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_target_status` (`target_identifier`, `status`),
    KEY `idx_restaurant` (`restaurant`),
    KEY `idx_issuer` (`issuer_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rex_diner_stock` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `restaurant` VARCHAR(64) NOT NULL,
    `item` VARCHAR(64) NOT NULL,
    `quantity` INT NOT NULL DEFAULT 0,
    `max_quantity` INT NOT NULL DEFAULT 100,
    `min_quantity` INT NOT NULL DEFAULT 10,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_restaurant_item` (`restaurant`, `item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rex_diner_orders` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `restaurant` VARCHAR(64) NOT NULL,
    `ordered_by` VARCHAR(64) NOT NULL,
    `ordered_by_name` VARCHAR(128) NOT NULL DEFAULT '',
    `total_cost` INT UNSIGNED NOT NULL DEFAULT 0,
    `status` ENUM('pending', 'assigned', 'in_transit', 'delivered', 'cancelled') NOT NULL DEFAULT 'pending',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `delivered_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_restaurant_status` (`restaurant`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rex_diner_order_items` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `order_id` INT UNSIGNED NOT NULL,
    `item` VARCHAR(64) NOT NULL,
    `label` VARCHAR(128) NOT NULL DEFAULT '',
    `quantity` INT UNSIGNED NOT NULL DEFAULT 1,
    `unit_price` INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    KEY `idx_order` (`order_id`),
    CONSTRAINT `fk_order_items_order`
        FOREIGN KEY (`order_id`) REFERENCES `rex_diner_orders` (`id`)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rex_diner_deliveries` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `order_id` INT UNSIGNED NOT NULL,
    `restaurant` VARCHAR(64) NOT NULL,
    `driver_identifier` VARCHAR(64) DEFAULT NULL,
    `driver_name` VARCHAR(128) DEFAULT NULL,
    `status` ENUM('waiting', 'in_progress', 'completed', 'cancelled') NOT NULL DEFAULT 'waiting',
    `started_at` TIMESTAMP NULL DEFAULT NULL,
    `completed_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_order` (`order_id`),
    KEY `idx_driver` (`driver_identifier`),
    KEY `idx_restaurant_status` (`restaurant`, `status`),
    CONSTRAINT `fk_deliveries_order`
        FOREIGN KEY (`order_id`) REFERENCES `rex_diner_orders` (`id`)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rex_diner_service` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `restaurant` VARCHAR(64) NOT NULL,
    `identifier` VARCHAR(64) NOT NULL,
    `name` VARCHAR(128) NOT NULL DEFAULT '',
    `started_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `ended_at` TIMESTAMP NULL DEFAULT NULL,
    `duration_seconds` INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    KEY `idx_active` (`identifier`, `ended_at`),
    KEY `idx_restaurant_date` (`restaurant`, `started_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rex_diner_settings` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `restaurant` VARCHAR(64) NOT NULL,
    `setting_key` VARCHAR(64) NOT NULL,
    `setting_value` TEXT NOT NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_restaurant_setting` (`restaurant`, `setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
