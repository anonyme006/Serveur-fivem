-- SD Company Announcements
-- Import manuel optionnel (la table est aussi créée automatiquement au démarrage).

CREATE TABLE IF NOT EXISTS `sd_company_announcements` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `company` VARCHAR(50) NOT NULL,
    `title` VARCHAR(150) NOT NULL,
    `content` TEXT NOT NULL,
    `type` VARCHAR(50) NOT NULL DEFAULT 'information',
    `priority` VARCHAR(50) NOT NULL DEFAULT 'normal',
    `status` VARCHAR(50) NOT NULL DEFAULT 'draft',
    `author_identifier` VARCHAR(100) NOT NULL,
    `author_name` VARCHAR(100) DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_company` (`company`),
    INDEX `idx_status` (`status`),
    INDEX `idx_company_created` (`company`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
