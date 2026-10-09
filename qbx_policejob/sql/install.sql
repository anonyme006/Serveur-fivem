-- qbx_policejob — schéma initial (oxmysql / MariaDB)
-- Exécution manuelle optionnelle : les tables sont aussi créées au start (server/database.lua)

CREATE TABLE IF NOT EXISTS `police_fines` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `officer_citizenid` VARCHAR(50) NOT NULL,
    `department` VARCHAR(50) NOT NULL,
    `category` VARCHAR(50) NOT NULL,
    `fine_key` VARCHAR(50) NOT NULL,
    `label` VARCHAR(120) NOT NULL,
    `amount` INT NOT NULL,
    `paid` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_police_fines_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `police_prison` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `officer_citizenid` VARCHAR(50) DEFAULT NULL,
    `department` VARCHAR(50) DEFAULT NULL,
    `minutes` INT NOT NULL,
    `release_at` TIMESTAMP NOT NULL,
    `active` TINYINT(1) NOT NULL DEFAULT 1,
    `reason` VARCHAR(255) DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_police_prison_citizen` (`citizenid`),
    KEY `idx_police_prison_active` (`citizenid`, `active`),
    KEY `idx_police_prison_release` (`release_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `police_community_service` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `officer_citizenid` VARCHAR(50) DEFAULT NULL,
    `tasks_remaining` INT NOT NULL,
    `tasks_total` INT NOT NULL,
    `active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_police_cs_citizen` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `police_incidents` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `department` VARCHAR(50) NOT NULL,
    `officer_citizenid` VARCHAR(50) NOT NULL,
    `target_citizenid` VARCHAR(50) DEFAULT NULL,
    `type` VARCHAR(50) NOT NULL,
    `payload` LONGTEXT DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_police_incidents_type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `police_objects` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `department` VARCHAR(50) NOT NULL,
    `owner_citizenid` VARCHAR(50) NOT NULL,
    `object_key` VARCHAR(50) NOT NULL,
    `model` VARCHAR(80) NOT NULL,
    `coords` VARCHAR(120) NOT NULL,
    `heading` FLOAT NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `police_gsr` (
    `citizenid` VARCHAR(50) NOT NULL,
    `positive` TINYINT(1) NOT NULL DEFAULT 0,
    `expires_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `police_confiscations` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `officer_citizenid` VARCHAR(50) NOT NULL,
    `target_citizenid` VARCHAR(50) NOT NULL,
    `department` VARCHAR(50) NOT NULL,
    `item_type` VARCHAR(30) NOT NULL,
    `item_name` VARCHAR(80) DEFAULT NULL,
    `amount` INT NOT NULL DEFAULT 0,
    `metadata` LONGTEXT DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_police_confisc_target` (`target_citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
