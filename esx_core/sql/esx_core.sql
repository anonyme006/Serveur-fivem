-- esx_core — tables complémentaires (owned_vehicles reste celle d'ESX / pa_garage)

CREATE TABLE IF NOT EXISTS `esx_core_keys` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `owner` VARCHAR(60) NOT NULL COMMENT 'identifiant propriétaire d''origine',
  `holder` VARCHAR(60) NOT NULL COMMENT 'identifiant détenteur actuel',
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

CREATE TABLE IF NOT EXISTS `esx_core_covers` (
  `plate` VARCHAR(12) NOT NULL,
  `owner` VARCHAR(60) NOT NULL,
  `coords` LONGTEXT NOT NULL COMMENT 'json x,y,z,w',
  `props` LONGTEXT NULL COMMENT 'snapshot props véhicule',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`plate`),
  KEY `owner` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `esx_core_used_parking` (
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
