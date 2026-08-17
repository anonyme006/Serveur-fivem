CREATE TABLE IF NOT EXISTS `drug_labs` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(64) NOT NULL,
    `type` VARCHAR(32) NOT NULL,
    `label` VARCHAR(128) NOT NULL,
    `ownership_type` ENUM('none', 'player', 'gang', 'admin') NOT NULL DEFAULT 'none',
    `owner_identifier` VARCHAR(64) NULL DEFAULT NULL,
    `owner_gang` VARCHAR(64) NULL DEFAULT NULL,
    `purchase_mode` ENUM('public', 'purchase', 'rent', 'gang', 'admin') NOT NULL DEFAULT 'purchase',
    `purchase_price` INT UNSIGNED NOT NULL DEFAULT 0,
    `rent_price` INT UNSIGNED NOT NULL DEFAULT 0,
    `sell_percentage` DECIMAL(5,4) NOT NULL DEFAULT 0.6500,
    `locked` TINYINT(1) NOT NULL DEFAULT 1,
    `access_code_hash` VARCHAR(128) NULL DEFAULT NULL,
    `sealed` TINYINT(1) NOT NULL DEFAULT 0,
    `entrance` LONGTEXT NOT NULL,
    `interior_data` LONGTEXT NOT NULL,
    `stash_data` LONGTEXT NOT NULL,
    `stations_data` LONGTEXT NULL DEFAULT NULL,
    `blip_data` LONGTEXT NULL DEFAULT NULL,
    `enabled` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_drug_labs_identifier` (`identifier`),
    KEY `idx_drug_labs_type` (`type`),
    KEY `idx_drug_labs_owner` (`owner_identifier`),
    KEY `idx_drug_labs_gang` (`owner_gang`),
    KEY `idx_drug_labs_sealed` (`sealed`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `drug_lab_members` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `lab_id` INT UNSIGNED NOT NULL,
    `citizenid` VARCHAR(64) NOT NULL,
    `permissions` LONGTEXT NOT NULL,
    `added_by` VARCHAR(64) NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_lab_member` (`lab_id`, `citizenid`),
    KEY `idx_lab_members_citizen` (`citizenid`),
    CONSTRAINT `fk_lab_members_lab`
        FOREIGN KEY (`lab_id`) REFERENCES `drug_labs` (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `drug_lab_rentals` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `lab_id` INT UNSIGNED NOT NULL,
    `renter` VARCHAR(64) NOT NULL,
    `start_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `expires_at` TIMESTAMP NOT NULL,
    `grace_until` TIMESTAMP NULL DEFAULT NULL,
    `status` ENUM('active', 'expired', 'cancelled', 'grace') NOT NULL DEFAULT 'active',
    `auto_renew` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_rentals_lab` (`lab_id`),
    KEY `idx_rentals_renter` (`renter`),
    KEY `idx_rentals_status` (`status`),
    KEY `idx_rentals_expires` (`expires_at`),
    CONSTRAINT `fk_lab_rentals_lab`
        FOREIGN KEY (`lab_id`) REFERENCES `drug_labs` (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `drug_lab_plants` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `lab_id` INT UNSIGNED NOT NULL,
    `station_id` VARCHAR(64) NOT NULL,
    `planted_by` VARCHAR(64) NULL DEFAULT NULL,
    `growth` DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    `water` DECIMAL(5,2) NOT NULL DEFAULT 50.00,
    `nutrients` DECIMAL(5,2) NOT NULL DEFAULT 50.00,
    `health` DECIMAL(5,2) NOT NULL DEFAULT 100.00,
    `quality` DECIMAL(5,2) NOT NULL DEFAULT 50.00,
    `planted_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `last_watered_at` TIMESTAMP NULL DEFAULT NULL,
    `last_fed_at` TIMESTAMP NULL DEFAULT NULL,
    `harvested` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_plants_lab` (`lab_id`),
    KEY `idx_plants_station` (`lab_id`, `station_id`),
    KEY `idx_plants_harvested` (`harvested`),
    CONSTRAINT `fk_lab_plants_lab`
        FOREIGN KEY (`lab_id`) REFERENCES `drug_labs` (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `drug_lab_batches` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `batch_code` VARCHAR(32) NOT NULL,
    `lab_id` INT UNSIGNED NOT NULL,
    `producer` VARCHAR(64) NOT NULL,
    `item_name` VARCHAR(64) NOT NULL,
    `quality` INT UNSIGNED NOT NULL DEFAULT 50,
    `recipe_id` VARCHAR(64) NULL DEFAULT NULL,
    `metadata` LONGTEXT NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_batch_code` (`batch_code`),
    KEY `idx_batches_lab` (`lab_id`),
    KEY `idx_batches_producer` (`producer`),
    KEY `idx_batches_item` (`item_name`),
    CONSTRAINT `fk_lab_batches_lab`
        FOREIGN KEY (`lab_id`) REFERENCES `drug_labs` (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `drug_lab_logs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `lab_id` INT UNSIGNED NULL DEFAULT NULL,
    `actor` VARCHAR(64) NULL DEFAULT NULL,
    `action` VARCHAR(64) NOT NULL,
    `data` LONGTEXT NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_logs_lab` (`lab_id`),
    KEY `idx_logs_action` (`action`),
    KEY `idx_logs_actor` (`actor`),
    KEY `idx_logs_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `drug_lab_code_attempts` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `lab_id` INT UNSIGNED NOT NULL,
    `citizenid` VARCHAR(64) NOT NULL,
    `attempts` INT UNSIGNED NOT NULL DEFAULT 0,
    `locked_until` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_code_attempt` (`lab_id`, `citizenid`),
    CONSTRAINT `fk_code_attempts_lab`
        FOREIGN KEY (`lab_id`) REFERENCES `drug_labs` (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
