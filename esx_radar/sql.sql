-- =============================================================================
-- esx_radar — Tables SQL
-- Compatible MySQL 5.7+ / MariaDB / oxmysql
-- =============================================================================

CREATE TABLE IF NOT EXISTS `radar_list` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(64) NOT NULL,
    `road_name` VARCHAR(128) NOT NULL,
    `speed_limit` INT UNSIGNED NOT NULL DEFAULT 50,
    `tolerance` INT UNSIGNED NOT NULL DEFAULT 5,
    `detection_distance` FLOAT NOT NULL DEFAULT 20.0,
    `direction` ENUM('both', 'forward', 'backward') NOT NULL DEFAULT 'both',
    `x` FLOAT NOT NULL,
    `y` FLOAT NOT NULL,
    `z` FLOAT NOT NULL,
    `heading` FLOAT NOT NULL DEFAULT 0.0,
    `enabled` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` VARCHAR(64) DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_enabled` (`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `radar_flashes` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(64) NOT NULL,
    `player_name` VARCHAR(128) NOT NULL,
    `plate` VARCHAR(16) NOT NULL,
    `vehicle_model` VARCHAR(64) NOT NULL,
    `position` VARCHAR(128) NOT NULL,
    `radar_id` INT UNSIGNED DEFAULT NULL,
    `radar_name` VARCHAR(64) NOT NULL,
    `road_name` VARCHAR(128) NOT NULL,
    `speed` INT UNSIGNED NOT NULL,
    `retained_speed` INT UNSIGNED NOT NULL,
    `speed_limit` INT UNSIGNED NOT NULL,
    `fine_amount` INT UNSIGNED NOT NULL DEFAULT 0,
    `authorized` TINYINT(1) NOT NULL DEFAULT 0,
    `flashed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_plate` (`plate`),
    INDEX `idx_radar_id` (`radar_id`),
    INDEX `idx_flashed_at` (`flashed_at`),
    CONSTRAINT `fk_radar_flashes_radar`
        FOREIGN KEY (`radar_id`) REFERENCES `radar_list` (`id`)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
