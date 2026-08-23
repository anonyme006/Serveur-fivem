-- ============================================================================
-- sql/01_rp_custom.sql
-- Tables de la couche custom FR (idempotentes)
-- Prérequis : qbx_core / ox installés, base MariaDB ≥ 10.9
-- ============================================================================

CREATE TABLE IF NOT EXISTS `rp_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `category` VARCHAR(32) NOT NULL,
  `citizenid` VARCHAR(50) DEFAULT NULL,
  `player_name` VARCHAR(128) DEFAULT NULL,
  `license` VARCHAR(80) DEFAULT NULL,
  `message` TEXT NOT NULL,
  `meta` LONGTEXT DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_rp_logs_category` (`category`),
  KEY `idx_rp_logs_citizenid` (`citizenid`),
  KEY `idx_rp_logs_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rp_license_history` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `license_type` VARCHAR(32) NOT NULL,
  `action` ENUM('grant','revoke') NOT NULL,
  `issuer_citizenid` VARCHAR(50) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_license_citizen` (`citizenid`),
  KEY `idx_license_type` (`license_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rp_invoices` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `invoice_id` VARCHAR(32) NOT NULL,
  `sender_cid` VARCHAR(50) NOT NULL,
  `target_cid` VARCHAR(50) NOT NULL,
  `society` VARCHAR(50) DEFAULT NULL,
  `amount` INT UNSIGNED NOT NULL,
  `reason` VARCHAR(180) NOT NULL,
  `status` ENUM('pending','paid','refused','expired') NOT NULL DEFAULT 'pending',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `paid_at` TIMESTAMP NULL DEFAULT NULL,
  `expires_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_invoice_id` (`invoice_id`),
  KEY `idx_inv_target` (`target_cid`),
  KEY `idx_inv_sender` (`sender_cid`),
  KEY `idx_inv_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rp_business_accounts` (
  `name` VARCHAR(50) NOT NULL,
  `balance` BIGINT NOT NULL DEFAULT 0,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rp_business_transactions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `business` VARCHAR(50) NOT NULL,
  `citizenid` VARCHAR(50) DEFAULT NULL,
  `type` VARCHAR(32) NOT NULL,
  `amount` INT NOT NULL,
  `reason` VARCHAR(180) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_biz_tx_business` (`business`),
  KEY `idx_biz_tx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rp_business_announcements` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `business` VARCHAR(50) NOT NULL,
  `citizenid` VARCHAR(50) NOT NULL,
  `message` VARCHAR(280) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_biz_ann_business` (`business`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rp_bans` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `license` VARCHAR(80) NOT NULL,
  `reason` VARCHAR(255) NOT NULL,
  `banned_by` VARCHAR(80) DEFAULT NULL,
  `expire` BIGINT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ban_license` (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO `rp_business_accounts` (`name`, `balance`) VALUES
('police', 0),
('ambulance', 0),
('mechanic', 0),
('taxi', 0),
('burgershot', 0),
('uwu', 0),
('government', 0),
('doj', 0);
