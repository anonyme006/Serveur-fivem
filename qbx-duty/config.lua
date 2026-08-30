Config = {}

Config.Locale = 'fr'

--- Distance max (m) au point de service pour prendre / quitter le service
Config.DutyPointRadius = 3.0

--- Comptabiliser le temps de service en base (duty_logs)
Config.TrackDutyTime = true

--- UI NUI (toast en service / hors service)
Config.UI = {
    enabled = true,
    duration = 3500,
}

--- Paramètres globaux des blips (surchargés par job)
Config.Blips = {
    updateInterval = 2000,
    showPlayerName = true,
    shortRange = false,
}

--- Qui voit les employés de quelle entreprise (viewerJob → jobs visibles)
Config.Visibility = {
    mechanic = {
        mechanic = true,
    },
    police = {
        police = true,
        ambulance = true,
    },
    ambulance = {
        ambulance = true,
        police = true,
    },
    taxi = {
        taxi = true,
    },
    burgershot = {
        burgershot = true,
    },
}

--- Entreprises / jobs
--- Ajoute une entrée ici sans toucher au code principal.
Config.Jobs = {
    mechanic = {
        label = 'Mechanic',
        enabled = true,
        duty = true,
        blips = true,
        showOffDuty = true,
        showPlayerName = true,
        onDuty = {
            sprite = 446,
            color = 2,
            scale = 0.70,
        },
        offDuty = {
            sprite = 446,
            color = 1,
            scale = 0.65,
        },
    },
    police = {
        label = 'Police',
        enabled = true,
        duty = true,
        blips = true,
        showOffDuty = true,
        showPlayerName = true,
        onDuty = {
            sprite = 60,
            color = 2,
            scale = 0.70,
        },
        offDuty = {
            sprite = 60,
            color = 1,
            scale = 0.65,
        },
    },
    ambulance = {
        label = 'EMS',
        enabled = true,
        duty = true,
        blips = true,
        showOffDuty = true,
        showPlayerName = true,
        onDuty = {
            sprite = 153,
            color = 2,
            scale = 0.70,
        },
        offDuty = {
            sprite = 153,
            color = 1,
            scale = 0.65,
        },
    },
    taxi = {
        label = 'Taxi',
        enabled = true,
        duty = true,
        blips = true,
        showOffDuty = true,
        showPlayerName = true,
        onDuty = {
            sprite = 198,
            color = 2,
            scale = 0.70,
        },
        offDuty = {
            sprite = 198,
            color = 1,
            scale = 0.65,
        },
    },
    burgershot = {
        label = 'Burger Shot',
        enabled = true,
        duty = true,
        blips = true,
        showOffDuty = true,
        showPlayerName = true,
        onDuty = {
            sprite = 106,
            color = 2,
            scale = 0.70,
        },
        offDuty = {
            sprite = 106,
            color = 1,
            scale = 0.65,
        },
    },
}

--- Points de prise de service (ox_target) — remplace par tes coords
Config.DutyPoints = {
    mechanic = {
        vec3(-347.45, -133.27, 39.01),
    },
    police = {
        vec3(441.85, -982.05, 30.69),
    },
    ambulance = {
        vec3(311.18, -599.43, 43.29),
    },
    taxi = {
        vec3(903.32, -170.55, 74.08),
    },
    burgershot = {
        vec3(-1193.38, -892.26, 13.99),
    },
}

--- Commande optionnelle (nil = désactivée)
Config.Command = {
    enabled = false,
    name = 'duty',
}
