-- Historique des actions permis (délivrance, retrait de points, révocation)
-- Appliqué automatiquement au démarrage via MySQL.ready dans server/main.lua

CREATE TABLE IF NOT EXISTS `qbx_license_history` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `license_type` VARCHAR(32) NOT NULL,
  `action` VARCHAR(32) NOT NULL,
  `points_before` INT DEFAULT NULL,
  `points_after` INT DEFAULT NULL,
  `amount` INT DEFAULT NULL,
  `issuer_citizenid` VARCHAR(50) DEFAULT NULL,
  `reason` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_qbx_lic_citizen` (`citizenid`),
  KEY `idx_qbx_lic_type` (`license_type`),
  KEY `idx_qbx_lic_action` (`action`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
