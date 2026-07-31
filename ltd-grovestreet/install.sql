-- =============================================================================
-- LTD Grove Street — Installation ESX
-- Exécuter ce fichier SQL une seule fois avant le premier démarrage.
-- =============================================================================

-- Métier LTD
INSERT INTO `jobs` (`name`, `label`) VALUES ('ltd', 'LTD Grove Street');

INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
    ('ltd', 0, 'recrue',       'Recrue',         150, '{}', '{}'),
    ('ltd', 1, 'employe',       'Employé',        250, '{}', '{}'),
    ('ltd', 2, 'chef',          'Chef d\'équipe', 350, '{}', '{}'),
    ('ltd', 3, 'manager',       'Manager',        450, '{}', '{}'),
    ('ltd', 4, 'boss',          'Patron',         600, '{}', '{}');

-- Compte société (esx_addonaccount)
INSERT INTO `addon_account` (`name`, `label`, `shared`) VALUES ('society_ltd', 'LTD Grove Street', 1);
INSERT INTO `addon_account_data` (`account_name`, `money`) VALUES ('society_ltd', 0);

-- Item ticket de caisse (ox_inventory)
-- Ajoutez également dans ox_inventory/data/items.lua :
-- ['receipt'] = { label = 'Ticket de caisse', weight = 10, stack = false, close = true,
--     description = 'Reçu d\'achat LTD Grove Street' },
