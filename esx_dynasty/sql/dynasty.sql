-- Dynasty 8 — job + tables logements
-- Exécuter une fois sur votre base ESX

INSERT INTO `jobs` (`name`, `label`) VALUES
    ('realestateagent', 'Dynasty 8')
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);

INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
    ('realestateagent', 0, 'recruit',   'Recrue',       150, '{}', '{}'),
    ('realestateagent', 1, 'agent',     'Agent',        250, '{}', '{}'),
    ('realestateagent', 2, 'experienc', 'Agent senior', 350, '{}', '{}'),
    ('realestateagent', 3, 'boss',      'Patron',       500, '{}', '{}')
ON DUPLICATE KEY UPDATE
    `label` = VALUES(`label`),
    `salary` = VALUES(`salary`);

INSERT INTO `addon_account` (`name`, `label`, `shared`) VALUES
    ('society_realestateagent', 'Dynasty 8', 1)
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);

INSERT INTO `addon_account_data` (`account_name`, `money`) VALUES
    ('society_realestateagent', 0)
ON DUPLICATE KEY UPDATE `account_name` = VALUES(`account_name`);

CREATE TABLE IF NOT EXISTS `dynasty_properties` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `label` VARCHAR(128) NOT NULL,
    `address` VARCHAR(255) NOT NULL DEFAULT '',
    `description` TEXT NULL,
    `interior` VARCHAR(64) NOT NULL DEFAULT 'apt_mid',
    `property_type` VARCHAR(32) NOT NULL DEFAULT 'appartement',
    `status` VARCHAR(32) NOT NULL DEFAULT 'libre',
    `price_sale` INT NOT NULL DEFAULT 0,
    `price_rent` INT NOT NULL DEFAULT 0,
    `entrance_x` FLOAT NOT NULL,
    `entrance_y` FLOAT NOT NULL,
    `entrance_z` FLOAT NOT NULL,
    `entrance_h` FLOAT NOT NULL DEFAULT 0,
    `garage_x` FLOAT NULL,
    `garage_y` FLOAT NULL,
    `garage_z` FLOAT NULL,
    `garage_h` FLOAT NULL,
    `owner` VARCHAR(64) NULL,
    `owner_name` VARCHAR(128) NULL,
    `renter` VARCHAR(64) NULL,
    `renter_name` VARCHAR(128) NULL,
    `locked` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` VARCHAR(64) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_owner` (`owner`),
    INDEX `idx_renter` (`renter`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `dynasty_keys` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `property_id` INT NOT NULL,
    `identifier` VARCHAR(64) NOT NULL,
    `player_name` VARCHAR(128) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_prop_ident` (`property_id`, `identifier`),
    INDEX `idx_identifier` (`identifier`),
    CONSTRAINT `fk_dynasty_keys_property`
        FOREIGN KEY (`property_id`) REFERENCES `dynasty_properties` (`id`)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `dynasty_news` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `author` VARCHAR(128) NOT NULL,
    `author_identifier` VARCHAR(64) NULL,
    `type` VARCHAR(32) NOT NULL DEFAULT 'normal',
    `content` TEXT NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `dynasty_billboard` (
    `id` INT NOT NULL DEFAULT 1,
    `content` TEXT NOT NULL,
    `updated_by` VARCHAR(128) NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `dynasty_billboard` (`id`, `content`, `updated_by`) VALUES
    (1, 'Bienvenue chez Dynasty 8 — publiez ici les annonces immobilières.', 'Système')
ON DUPLICATE KEY UPDATE `id` = `id`;
