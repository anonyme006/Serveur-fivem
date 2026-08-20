-- Pulse Phone — Schéma SQL (oxmysql / MariaDB)
-- Charset utf8mb4 pour noms, messages et descriptions

CREATE TABLE IF NOT EXISTS `phone_users` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `phone_number` VARCHAR(20) NOT NULL,
    `pin` VARCHAR(8) DEFAULT NULL,
    `wallpaper` VARCHAR(32) NOT NULL DEFAULT 'ocean',
    `theme` VARCHAR(16) NOT NULL DEFAULT 'dark',
    `settings` LONGTEXT DEFAULT NULL,
    `battery` TINYINT UNSIGNED NOT NULL DEFAULT 100,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_phone_users_citizenid` (`citizenid`),
    UNIQUE KEY `uq_phone_users_number` (`phone_number`),
    KEY `idx_phone_users_number` (`phone_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_contacts` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `owner_citizenid` VARCHAR(50) NOT NULL,
    `firstname` VARCHAR(50) NOT NULL,
    `lastname` VARCHAR(50) NOT NULL DEFAULT '',
    `number` VARCHAR(20) NOT NULL,
    `avatar` VARCHAR(255) DEFAULT NULL,
    `company` VARCHAR(80) DEFAULT NULL,
    `favorite` TINYINT(1) NOT NULL DEFAULT 0,
    `notes` VARCHAR(255) DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_contacts_owner` (`owner_citizenid`),
    KEY `idx_contacts_owner_number` (`owner_citizenid`, `number`),
    KEY `idx_contacts_favorite` (`owner_citizenid`, `favorite`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_messages` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `conversation_id` VARCHAR(64) NOT NULL,
    `sender_citizenid` VARCHAR(50) NOT NULL,
    `sender_number` VARCHAR(20) NOT NULL,
    `receiver_number` VARCHAR(20) NOT NULL,
    `body` TEXT NOT NULL,
    `attachments` LONGTEXT DEFAULT NULL, -- JSON: [{type,url,meta}]
    `is_read` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_messages_conversation` (`conversation_id`, `id`),
    KEY `idx_messages_receiver_unread` (`receiver_number`, `is_read`),
    KEY `idx_messages_sender` (`sender_citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_calls` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `caller_citizenid` VARCHAR(50) NOT NULL,
    `caller_number` VARCHAR(20) NOT NULL,
    `callee_number` VARCHAR(20) NOT NULL,
    `callee_citizenid` VARCHAR(50) DEFAULT NULL,
    `direction` ENUM('outgoing','incoming','missed') NOT NULL,
    `status` ENUM('ringing','accepted','declined','ended','missed','failed') NOT NULL,
    `company_id` VARCHAR(50) DEFAULT NULL,
    `started_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `answered_at` TIMESTAMP NULL DEFAULT NULL,
    `ended_at` TIMESTAMP NULL DEFAULT NULL,
    `duration` INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    KEY `idx_calls_caller` (`caller_citizenid`, `started_at`),
    KEY `idx_calls_callee_number` (`callee_number`, `started_at`),
    KEY `idx_calls_company` (`company_id`, `started_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_notifications` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `type` VARCHAR(32) NOT NULL,
    `title` VARCHAR(120) NOT NULL,
    `body` VARCHAR(255) NOT NULL,
    `payload` LONGTEXT DEFAULT NULL,
    `is_read` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_notif_citizen_unread` (`citizenid`, `is_read`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_companies` (
    `id` VARCHAR(50) NOT NULL,
    `label` VARCHAR(80) NOT NULL,
    `job` VARCHAR(50) NOT NULL,
    `category` VARCHAR(40) NOT NULL DEFAULT 'service',
    `description` VARCHAR(255) DEFAULT NULL,
    `number` VARCHAR(20) NOT NULL,
    `logo` VARCHAR(255) DEFAULT NULL,
    `status` ENUM('open','busy','closed') NOT NULL DEFAULT 'closed',
    `auto_status` TINYINT(1) NOT NULL DEFAULT 1,
    `pos_x` FLOAT DEFAULT NULL,
    `pos_y` FLOAT DEFAULT NULL,
    `pos_z` FLOAT DEFAULT NULL,
    `settings` LONGTEXT DEFAULT NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_companies_number` (`number`),
    KEY `idx_companies_job` (`job`),
    KEY `idx_companies_category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_company_employees` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `company_id` VARCHAR(50) NOT NULL,
    `citizenid` VARCHAR(50) NOT NULL,
    `grade` INT NOT NULL DEFAULT 0,
    `on_duty` TINYINT(1) NOT NULL DEFAULT 0,
    `last_seen` TIMESTAMP NULL DEFAULT NULL,
    `hired_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_company_employee` (`company_id`, `citizenid`),
    KEY `idx_employee_citizen` (`citizenid`),
    KEY `idx_employee_duty` (`company_id`, `on_duty`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_service_requests` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `company_id` VARCHAR(50) NOT NULL,
    `citizenid` VARCHAR(50) NOT NULL,
    `client_name` VARCHAR(80) NOT NULL,
    `client_number` VARCHAR(20) NOT NULL,
    `service_type` VARCHAR(80) NOT NULL DEFAULT 'general',
    `description` TEXT NOT NULL,
    `pos_x` FLOAT NOT NULL,
    `pos_y` FLOAT NOT NULL,
    `pos_z` FLOAT NOT NULL,
    `location_label` VARCHAR(120) DEFAULT NULL,
    `status` ENUM('pending','accepted','refused','cancelled','completed') NOT NULL DEFAULT 'pending',
    `accepted_by` VARCHAR(50) DEFAULT NULL,
    `accepted_at` TIMESTAMP NULL DEFAULT NULL,
    `closed_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_requests_company_status` (`company_id`, `status`, `created_at`),
    KEY `idx_requests_citizen` (`citizenid`, `created_at`),
    KEY `idx_requests_accepted_by` (`accepted_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_marketplace` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `seller_citizenid` VARCHAR(50) NOT NULL,
    `seller_number` VARCHAR(20) NOT NULL,
    `title` VARCHAR(120) NOT NULL,
    `description` TEXT NOT NULL,
    `price` INT UNSIGNED NOT NULL DEFAULT 0,
    `category` VARCHAR(40) NOT NULL,
    `image` VARCHAR(255) DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_market_category_active` (`category`, `is_active`, `created_at`),
    KEY `idx_market_seller` (`seller_citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_transactions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `account` VARCHAR(40) NOT NULL DEFAULT 'bank',
    `type` ENUM('transfer_in','transfer_out','payment','receive','fee') NOT NULL,
    `amount` INT NOT NULL,
    `balance_after` INT DEFAULT NULL,
    `counterparty` VARCHAR(80) DEFAULT NULL,
    `label` VARCHAR(120) DEFAULT NULL,
    `meta` LONGTEXT DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_tx_citizen` (`citizenid`, `created_at`),
    KEY `idx_tx_type` (`type`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
