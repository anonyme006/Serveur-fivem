Config = {}

Config.Licenses = {
    driver = { label = 'Permis voiture', item = 'driver_license' },
    motorcycle = { label = 'Permis moto', item = nil },
    truck = { label = 'Permis camion', item = nil },
    boat = { label = 'Permis bateau', item = nil },
    aircraft = { label = 'Permis avion', item = nil },
    weapon = { label = 'Permis port d\'armes', item = 'weaponlicense' },
}

--- Jobs autorisés à délivrer / retirer
Config.Issuers = {
    driver = { police = 2, government = 0, doj = 0 },
    motorcycle = { police = 2, government = 0 },
    truck = { police = 2, government = 0 },
    boat = { police = 2, government = 0 },
    aircraft = { police = 3, government = 1 },
    weapon = { police = 3, doj = 0 },
}
