-- PA Benny's ESX — compte société et job
-- Exécuter une fois sur ta base ESX

INSERT INTO `addon_account` (`name`, `label`, `shared`) VALUES
    ('society_bennys', 'Benny\'s Original', 1)
ON DUPLICATE KEY UPDATE `label` = 'Benny\'s Original';

INSERT INTO `addon_account_data` (`account_name`, `money`, `owner`) VALUES
    ('society_bennys', 0, NULL)
ON DUPLICATE KEY UPDATE `account_name` = 'society_bennys';

INSERT INTO `jobs` (`name`, `label`) VALUES ('bennys', 'Benny\'s Original')
ON DUPLICATE KEY UPDATE `label` = 'Benny\'s Original';

INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
    ('bennys', 0, 'recrue', 'Recrue', 200, '{}', '{}'),
    ('bennys', 1, 'mecano', 'Mécano', 350, '{}', '{}'),
    ('bennys', 2, 'chef', 'Chef d\'équipe', 500, '{}', '{}'),
    ('bennys', 3, 'boss', 'Patron', 750, '{}', '{}')
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);
