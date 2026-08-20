-- Item ESX classique (si tu n'utilises pas ox_inventory)
INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES
    ('vehicle_key', 'Clé de véhicule', 1, 0, 1),
    ('phone_antenna', 'Antenne réseau', 1, 0, 1)
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);
