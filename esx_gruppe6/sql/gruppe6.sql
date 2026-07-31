-- Gruppe 6 ESX — job + compte société + table points
-- Exécuter une fois sur votre base ESX

INSERT INTO `jobs` (`name`, `label`) VALUES
    ('gruppe6', 'Gruppe 6')
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);

INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
    ('gruppe6', 0, 'agent',       'Agent',       50,  '{}', '{}'),
    ('gruppe6', 1, 'superviseur', 'Superviseur', 100, '{}', '{}')
ON DUPLICATE KEY UPDATE
    `label` = VALUES(`label`),
    `salary` = VALUES(`salary`);

INSERT INTO `addon_account` (`name`, `label`, `shared`) VALUES
    ('society_gruppe6', 'Gruppe 6', 1)
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);

INSERT INTO `addon_account_data` (`account_name`, `money`, `owner`) VALUES
    ('society_gruppe6', 0, NULL)
ON DUPLICATE KEY UPDATE `account_name` = VALUES(`account_name`);

CREATE TABLE IF NOT EXISTS `esx_gruppe6_points` (
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

-- Item ox_inventory (ajouter aussi dans data/items.lua si besoin)
-- ['money_bag'] = { label = 'Sac de billets', weight = 2500, stack = false, close = true },
