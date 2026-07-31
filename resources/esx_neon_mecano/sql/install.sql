-- Neon Mechanic ESX — compte société
-- Exécuter une fois sur ta base ESX

INSERT INTO `addon_account` (`name`, `label`, `shared`) VALUES
    ('society_mechanic', 'Neon Mechanic', 1)
ON DUPLICATE KEY UPDATE `label` = 'Neon Mechanic';

INSERT INTO `addon_account_data` (`account_name`, `money`, `owner`) VALUES
    ('society_mechanic', 0, NULL)
ON DUPLICATE KEY UPDATE `account_name` = 'society_mechanic';

-- Job mechanic (si absent de ta base)
INSERT INTO `jobs` (`name`, `label`) VALUES ('mechanic', 'Neon Mechanic')
ON DUPLICATE KEY UPDATE `label` = 'Neon Mechanic';

INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
    ('mechanic', 0, 'recrue', 'Recrue', 200, '{}', '{}'),
    ('mechanic', 1, 'mecano', 'Mécano', 350, '{}', '{}'),
    ('mechanic', 2, 'chef', 'Chef d\'équipe', 500, '{}', '{}'),
    ('mechanic', 3, 'boss', 'Patron', 750, '{}', '{}')
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);
