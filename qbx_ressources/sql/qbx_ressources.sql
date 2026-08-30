-- qbx_ressources — schéma unifié

-- qbx_ressources — tables complémentaires (player_vehicles reste celle de QBox)

CREATE TABLE IF NOT EXISTS `qbx_ressources_keys` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `owner` VARCHAR(60) NOT NULL COMMENT 'citizenid propriétaire',
  `holder` VARCHAR(60) NOT NULL COMMENT 'citizenid détenteur',
  `key_type` ENUM('vehicle','house') NOT NULL DEFAULT 'vehicle',
  `key_ref` VARCHAR(64) NOT NULL COMMENT 'plaque ou id habitation',
  `label` VARCHAR(80) DEFAULT NULL,
  `temporary` TINYINT(1) NOT NULL DEFAULT 0,
  `expires_at` DATETIME DEFAULT NULL,
  `meta` LONGTEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `holder` (`holder`),
  KEY `key_lookup` (`key_type`, `key_ref`),
  KEY `owner` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `qbx_ressources_covers` (
  `plate` VARCHAR(12) NOT NULL,
  `owner` VARCHAR(60) NOT NULL,
  `coords` LONGTEXT NOT NULL COMMENT 'json x,y,z,w',
  `props` LONGTEXT NULL COMMENT 'snapshot props véhicule',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`plate`),
  KEY `owner` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `qbx_ressources_used_parking` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `seller` VARCHAR(60) NOT NULL,
  `plate` VARCHAR(12) NOT NULL,
  `price` INT NOT NULL,
  `slot` INT NOT NULL,
  `vehicle` LONGTEXT NOT NULL,
  `label` VARCHAR(80) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `plate` (`plate`),
  UNIQUE KEY `slot` (`slot`),
  KEY `seller` (`seller`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `qbx_ressources_antennas` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `owner` VARCHAR(60) NOT NULL,
  `label` VARCHAR(80) DEFAULT NULL,
  `coords` LONGTEXT NOT NULL,
  `heading` FLOAT NOT NULL DEFAULT 0,
  `range_m` FLOAT NOT NULL DEFAULT 180,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `owner` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;



-- qbx-duty — historique optionnel du temps de service

CREATE TABLE IF NOT EXISTS `duty_logs` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(60) NOT NULL,
  `job` VARCHAR(50) NOT NULL,
  `grade` INT NOT NULL DEFAULT 0,
  `clock_in` DATETIME NOT NULL,
  `clock_out` DATETIME DEFAULT NULL,
  `duration` INT DEFAULT NULL COMMENT 'secondes',
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`),
  KEY `job` (`job`),
  KEY `clock_in` (`clock_in`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;



CREATE TABLE IF NOT EXISTS `sleeping_bodies` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `firstname` VARCHAR(100) DEFAULT NULL,
  `lastname` VARCHAR(100) DEFAULT NULL,
  `model` VARCHAR(100) DEFAULT NULL,
  `appearance` LONGTEXT DEFAULT NULL,
  `x` DOUBLE NOT NULL,
  `y` DOUBLE NOT NULL,
  `z` DOUBLE NOT NULL,
  `heading` FLOAT NOT NULL,
  `bucket` INT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
