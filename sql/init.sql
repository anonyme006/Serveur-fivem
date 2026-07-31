-- Base initiale pour un serveur Qbox + Ox
-- Usage: mysql -u root -p < sql/init.sql
-- Puis:  bash sql/import-all.sh   (importe aussi sql/vendor/*.sql)

CREATE DATABASE IF NOT EXISTS `fivem_qbox`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `fivem_qbox`;

-- Tables Qbox / ox_doorlock : voir sql/vendor/ (qbx_core.sql, ox_doorlock.sql, …)
-- Certaines tables ox_inventory se créent au premier démarrage.

-- Exemple de table custom pour les stubs vibe_*
CREATE TABLE IF NOT EXISTS `vibe_player_meta` (
  `citizenid` VARCHAR(50) NOT NULL,
  `stats` LONGTEXT NULL,
  `permits` LONGTEXT NULL,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `vibe_invoices` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `from_citizenid` VARCHAR(50) NOT NULL,
  `to_citizenid` VARCHAR(50) NOT NULL,
  `amount` INT NOT NULL,
  `reason` VARCHAR(255) NOT NULL,
  `paid` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_to` (`to_citizenid`),
  KEY `idx_paid` (`paid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `vibe_gruppe6_points` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `point_type` VARCHAR(32) NOT NULL,
  `label` VARCHAR(128) NOT NULL,
  `x` DOUBLE NOT NULL,
  `y` DOUBLE NOT NULL,
  `z` DOUBLE NOT NULL,
  `enabled` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_type` (`point_type`),
  KEY `idx_enabled` (`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
