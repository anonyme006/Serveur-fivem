-- Pulse Phone — extension Services v0.2
-- À exécuter si install.sql a déjà été importé

ALTER TABLE `phone_companies`
    ADD COLUMN IF NOT EXISTS `location` VARCHAR(120) DEFAULT NULL AFTER `description`,
    ADD COLUMN IF NOT EXISTS `balance` INT NOT NULL DEFAULT 0 AFTER `status`,
    ADD COLUMN IF NOT EXISTS `icon` VARCHAR(16) DEFAULT NULL AFTER `logo`,
    ADD COLUMN IF NOT EXISTS `icon_color` VARCHAR(16) DEFAULT NULL AFTER `icon`;

CREATE TABLE IF NOT EXISTS `phone_company_messages` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `company_id` VARCHAR(50) NOT NULL,
    `citizenid` VARCHAR(50) NOT NULL,
    `sender_type` ENUM('player','company') NOT NULL,
    `sender_name` VARCHAR(80) NOT NULL,
    `sender_number` VARCHAR(20) DEFAULT NULL,
    `body` TEXT NOT NULL,
    `is_read` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_cmsg_company_citizen` (`company_id`, `citizenid`, `id`),
    KEY `idx_cmsg_company_unread` (`company_id`, `is_read`),
    KEY `idx_cmsg_citizen` (`citizenid`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
