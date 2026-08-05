-- esx_interim — Jobs Pôle Emploi
-- Exécuter une fois sur votre base ESX

INSERT INTO `jobs` (`name`, `label`) VALUES
    ('electricien', 'Electricien'),
    ('eboueur', 'Éboueur'),
    ('plombier', 'Plombier'),
    ('mineur', 'Joaillier'),
    ('livreur', 'Livreur de Journaux')
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);

INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
    ('electricien', 0, 'interim', 'Intérimaire', 0, '{}', '{}'),
    ('eboueur',     0, 'interim', 'Intérimaire', 0, '{}', '{}'),
    ('plombier',    0, 'interim', 'Intérimaire', 0, '{}', '{}'),
    ('mineur',      0, 'interim', 'Intérimaire', 0, '{}', '{}'),
    ('livreur',     0, 'interim', 'Intérimaire', 0, '{}', '{}')
ON DUPLICATE KEY UPDATE
    `label` = VALUES(`label`),
    `salary` = VALUES(`salary`);
