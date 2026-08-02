-- core_garage — schéma SQL (création auto au démarrage également)

CREATE TABLE IF NOT EXISTS `garages` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(64) NOT NULL,
    `label` VARCHAR(128) NOT NULL,
    `type` VARCHAR(32) NOT NULL DEFAULT 'public',
    `coords` LONGTEXT NOT NULL,
    `spawn` LONGTEXT NOT NULL,
    `heading` FLOAT NOT NULL DEFAULT 0.0,
    `store` LONGTEXT NOT NULL,
    `blip` LONGTEXT DEFAULT NULL,
    `marker` LONGTEXT DEFAULT NULL,
    `job` VARCHAR(64) DEFAULT NULL,
    `gang` VARCHAR(64) DEFAULT NULL,
    `min_grade` INT NOT NULL DEFAULT 0,
    `vehicle_type` VARCHAR(32) NOT NULL DEFAULT 'car',
    `impound_price` INT NOT NULL DEFAULT 1500,
    `impound_time` INT NOT NULL DEFAULT 0,
    `enabled` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_garages_name` (`name`),
    KEY `idx_garages_type` (`type`),
    KEY `idx_garages_job` (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `garage_vehicles` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `owner` VARCHAR(60) NOT NULL,
    `plate` VARCHAR(12) NOT NULL,
    `vehicle` LONGTEXT NOT NULL,
    `garage` VARCHAR(64) DEFAULT NULL,
    `type` VARCHAR(32) NOT NULL DEFAULT 'car',
    `stored` TINYINT(1) NOT NULL DEFAULT 1,
    `impound` TINYINT(1) NOT NULL DEFAULT 0,
    `impound_id` VARCHAR(64) DEFAULT NULL,
    `impound_fee` INT NOT NULL DEFAULT 0,
    `impound_until` DATETIME DEFAULT NULL,
    `engine` FLOAT NOT NULL DEFAULT 1000.0,
    `body` FLOAT NOT NULL DEFAULT 1000.0,
    `fuel` FLOAT NOT NULL DEFAULT 100.0,
    `dirt` FLOAT NOT NULL DEFAULT 0.0,
    `mileage` FLOAT NOT NULL DEFAULT 0.0,
    `insured` TINYINT(1) NOT NULL DEFAULT 0,
    `nickname` VARCHAR(64) DEFAULT NULL,
    `category` VARCHAR(32) DEFAULT NULL,
    `company` VARCHAR(64) DEFAULT NULL,
    `net_id` INT DEFAULT NULL,
    `last_out` DATETIME DEFAULT NULL,
    `last_in` DATETIME DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_garage_vehicles_plate` (`plate`),
    KEY `idx_gv_owner` (`owner`),
    KEY `idx_gv_garage` (`garage`),
    KEY `idx_gv_stored` (`stored`),
    KEY `idx_gv_impound` (`impound`),
    KEY `idx_gv_company` (`company`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `garage_company` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `job` VARCHAR(64) NOT NULL,
    `garage` VARCHAR(64) NOT NULL,
    `label` VARCHAR(128) NOT NULL,
    `min_grade_out` INT NOT NULL DEFAULT 0,
    `min_grade_store` INT NOT NULL DEFAULT 0,
    `min_grade_manage` INT NOT NULL DEFAULT 2,
    `max_out` INT NOT NULL DEFAULT 5,
    `shared` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_company_job_garage` (`job`, `garage`),
    KEY `idx_gc_job` (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `garage_logs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `action` VARCHAR(32) NOT NULL,
    `plate` VARCHAR(12) NOT NULL,
    `owner` VARCHAR(60) DEFAULT NULL,
    `identifier` VARCHAR(60) NOT NULL,
    `garage` VARCHAR(64) DEFAULT NULL,
    `company` VARCHAR(64) DEFAULT NULL,
    `details` LONGTEXT DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_gl_plate` (`plate`),
    KEY `idx_gl_identifier` (`identifier`),
    KEY `idx_gl_company` (`company`),
    KEY `idx_gl_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `impound` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `plate` VARCHAR(12) NOT NULL,
    `owner` VARCHAR(60) NOT NULL,
    `vehicle` LONGTEXT NOT NULL,
    `impound_garage` VARCHAR(64) NOT NULL,
    `reason` VARCHAR(128) DEFAULT 'destroyed',
    `fee` INT NOT NULL DEFAULT 1500,
    `available_at` DATETIME NOT NULL,
    `released` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_impound_plate` (`plate`),
    KEY `idx_impound_owner` (`owner`),
    KEY `idx_impound_released` (`released`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `vehicle_mileage` (
    `plate` VARCHAR(12) NOT NULL,
    `mileage` FLOAT NOT NULL DEFAULT 0.0,
    `last_coords` LONGTEXT DEFAULT NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
