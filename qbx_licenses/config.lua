Config = {}

Config.Locale = 'fr'

--- Points max par défaut (système français)
Config.DefaultMaxPoints = 12

--- Types de permis à points
Config.Licenses = {
    driver = {
        label = 'Permis voiture',
        short = 'Voiture',
        icon = 'fa-solid fa-car',
        maxPoints = 12,
        item = 'driver_license',
        cardColor = '#ff8c42',
    },
    motorcycle = {
        label = 'Permis moto',
        short = 'Moto',
        icon = 'fa-solid fa-motorcycle',
        maxPoints = 12,
        item = 'motorcycle_license',
        cardColor = '#5ec8ff',
    },
    boat = {
        label = 'Permis bateau',
        short = 'Bateau',
        icon = 'fa-solid fa-ship',
        maxPoints = 12,
        item = 'boat_license',
        cardColor = '#4ecdc4',
    },
    aircraft = {
        label = 'Permis avion',
        short = 'Avion',
        icon = 'fa-solid fa-plane',
        maxPoints = 12,
        item = 'aircraft_license',
        cardColor = '#a78bfa',
    },
}

--- Jobs autorisés à délivrer / retirer / enlever des points
--- grade minimum inclus
Config.PoliceJobs = {
    police = 0,
    sheriff = 0,
    fib = 2,
}

--- Grade minimum pour délivrer un permis (grant)
Config.GrantMinGrade = 2

--- Grade minimum pour retirer des points
Config.RemovePointsMinGrade = 0

--- Grade minimum pour révoquer entièrement un permis
Config.RevokeMinGrade = 2

--- Doit être en service (PlayerData.job.onduty)
Config.RequireOnDuty = true

--- Distance max pour cibler un joueur (ox_target / menu)
Config.TargetDistance = 2.5

--- Quand les points tombent à 0 → révoquer le permis
Config.RevokeAtZero = true

--- Notifier le joueur cible lors d'un retrait de points
Config.NotifyTarget = true

--- Synchroniser les points sur les items ox_inventory (metadata.points)
Config.SyncItemMetadata = true

--- Afficher le panneau carte permis (NUI intégré)
Config.Card = {
    enabled = true,
    closeKey = 'Backspace',
    autoCloseMs = 0, -- 0 = manuel
}

--- Commandes admin / staff
Config.Commands = {
    grant = 'grantlicense',
    revoke = 'revokelicense',
    setpoints = 'setlicensepoints',
    mylicenses = 'mespermis',
}

--- ACE admin bypass
Config.AdminAce = 'qbx_licenses.admin'
