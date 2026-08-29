-- qbx-mechanic — Schéma MySQL
-- Exécuter ce fichier une fois via HeidiSQL, phpMyAdmin ou `mysql < mechanic.sql`

CREATE TABLE IF NOT EXISTS `mechanic_stock` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `mechanic_id` VARCHAR(64) NOT NULL,
    `item` VARCHAR(64) NOT NULL,
    `label` VARCHAR(128) DEFAULT NULL,
    `quantity` INT NOT NULL DEFAULT 0,
    `price` INT NOT NULL DEFAULT 0,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_mechanic_item` (`mechanic_id`, `item`),
    KEY `idx_mechanic_id` (`mechanic_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `mechanic_transactions` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `mechanic_id` VARCHAR(64) NOT NULL,
    `type` ENUM('income', 'expense', 'stock_in', 'stock_out', 'invoice', 'payout') NOT NULL,
    `amount` INT NOT NULL DEFAULT 0,
    `item` VARCHAR(64) DEFAULT NULL,
    `quantity` INT DEFAULT NULL,
    `citizenid` VARCHAR(64) DEFAULT NULL,
    `target_citizenid` VARCHAR(64) DEFAULT NULL,
    `description` VARCHAR(255) DEFAULT NULL,
    `metadata` JSON DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_mechanic_id` (`mechanic_id`),
    KEY `idx_type` (`type`),
    KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `mechanic_repairs` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `mechanic_id` VARCHAR(64) NOT NULL,
    `plate` VARCHAR(16) NOT NULL,
    `vehicle_model` VARCHAR(64) DEFAULT NULL,
    `service` VARCHAR(64) NOT NULL,
    `price` INT NOT NULL DEFAULT 0,
    `mechanic_citizenid` VARCHAR(64) NOT NULL,
    `customer_citizenid` VARCHAR(64) DEFAULT NULL,
    `metadata` JSON DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_plate` (`plate`),
    KEY `idx_mechanic_id` (`mechanic_id`),
    KEY `idx_mechanic_citizenid` (`mechanic_citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `mechanic_logs` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `mechanic_id` VARCHAR(64) NOT NULL,
    `citizenid` VARCHAR(64) DEFAULT NULL,
    `action` VARCHAR(64) NOT NULL,
    `details` JSON DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_mechanic_id` (`mechanic_id`),
    KEY `idx_action` (`action`),
    KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `mechanic_invoices` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `mechanic_id` VARCHAR(64) NOT NULL,
    `invoice_number` VARCHAR(32) NOT NULL,
    `issuer_citizenid` VARCHAR(64) NOT NULL,
    `target_citizenid` VARCHAR(64) NOT NULL,
    `services` JSON NOT NULL,
    `total` INT NOT NULL DEFAULT 0,
    `status` ENUM('draft', 'sent', 'paid', 'declined', 'cancelled') NOT NULL DEFAULT 'draft',
    `paid_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_invoice_number` (`invoice_number`),
    KEY `idx_mechanic_id` (`mechanic_id`),
    KEY `idx_target` (`target_citizenid`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Données initiales stock (exemple Benny's)
INSERT INTO `mechanic_stock` (`mechanic_id`, `item`, `label`, `quantity`, `price`) VALUES
    ('bennys', 'engine_oil', 'Huile moteur', 50, 25),
    ('bennys', 'brake_pads', 'Plaquettes de frein', 30, 80),
    ('bennys', 'spark_plug', 'Bougie d''allumage', 40, 15),
    ('bennys', 'car_battery', 'Batterie', 20, 120),
    ('bennys', 'tire', 'Pneu', 25, 150),
    ('bennys', 'repair_kit', 'Kit de réparation', 15, 200),
    ('bennys', 'body_parts', 'Pièces carrosserie', 20, 350),
    ('lscustoms', 'engine_oil', 'Huile moteur', 50, 25),
    ('lscustoms', 'brake_pads', 'Plaquettes de frein', 30, 80),
    ('lscustoms', 'spark_plug', 'Bougie d''allumage', 40, 15),
    ('lscustoms', 'car_battery', 'Batterie', 20, 120),
    ('lscustoms', 'tire', 'Pneu', 25, 150),
    ('lscustoms', 'repair_kit', 'Kit de réparation', 15, 200),
    ('lscustoms', 'body_parts', 'Pièces carrosserie', 20, 350)
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);
