CREATE TABLE IF NOT EXISTS `marlowe_stats` (
    `citizenid` VARCHAR(50) NOT NULL,
    `grapes_harvested` INT NOT NULL DEFAULT 0,
    `bottles_produced` INT NOT NULL DEFAULT 0,
    `deliveries_completed` INT NOT NULL DEFAULT 0,
    `revenue_generated` INT NOT NULL DEFAULT 0,
    `hours_worked` INT NOT NULL DEFAULT 0,
    `duty_started_at` INT NULL DEFAULT NULL,
    PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `marlowe_orders` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `client_name` VARCHAR(100) NOT NULL,
    `product_item` VARCHAR(50) NOT NULL,
    `product_label` VARCHAR(100) NOT NULL,
    `quantity` INT NOT NULL DEFAULT 1,
    `price` INT NOT NULL DEFAULT 0,
    `destination_label` VARCHAR(100) NOT NULL,
    `destination_x` FLOAT NOT NULL,
    `destination_y` FLOAT NOT NULL,
    `destination_z` FLOAT NOT NULL,
    `status` VARCHAR(20) NOT NULL DEFAULT 'pending',
    `assigned_citizenid` VARCHAR(50) NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `marlowe_finances` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `type` ENUM('income', 'expense') NOT NULL,
    `amount` INT NOT NULL,
    `reason` VARCHAR(255) NOT NULL,
    `citizenid` VARCHAR(50) NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
