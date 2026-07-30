CREATE TABLE IF NOT EXISTS `banque_transactions` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `account_type` VARCHAR(32) NOT NULL DEFAULT 'personal',
    `account_id` VARCHAR(64) NOT NULL,
    `identifier` VARCHAR(64) NULL,
    `actor_name` VARCHAR(64) NULL,
    `type` VARCHAR(32) NOT NULL,
    `label` VARCHAR(128) NOT NULL,
    `amount` INT NOT NULL,
    `balance_after` INT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_account` (`account_type`, `account_id`),
    INDEX `idx_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `banque_favorites` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `owner` VARCHAR(64) NOT NULL,
    `name` VARCHAR(64) NOT NULL,
    `account_number` VARCHAR(64) NOT NULL,
    `target_identifier` VARCHAR(64) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_owner` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `banque_account_numbers` (
    `identifier` VARCHAR(64) NOT NULL,
    `account_number` VARCHAR(64) NOT NULL,
    PRIMARY KEY (`identifier`),
    UNIQUE KEY `uk_account_number` (`account_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
