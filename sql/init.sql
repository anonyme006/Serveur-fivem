-- Base initiale pour un serveur Qbox + Ox
-- Adapte le nom de base si besoin.

CREATE DATABASE IF NOT EXISTS `fivem_qbox`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `fivem_qbox`;

-- Les tables Qbox / ox_inventory / ox_doorlock sont créées
-- automatiquement au premier démarrage des ressources, ou via
-- leurs fichiers SQL officiels (à importer après install-opensource.sh).

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
