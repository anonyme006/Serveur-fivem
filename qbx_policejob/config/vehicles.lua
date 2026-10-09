--[[--------------------------------------------------------------------------
    Garage police, plaques, liveries (PHASE 8)
---------------------------------------------------------------------------]]

Config.Vehicles = {
    --- Format de plaque : {DEPT}{random} — ex: LSPD1234
    plateFormat = {
        police = 'LSPD',
        sheriff = 'BCSO',
        statepolice = 'SASP',
        fib = 'FIB',
    },
    plateDigits = 4,

    --- Garage par département
    --- minGrade = grade minimum pour sortir le véhicule
    garages = {
        police = {
            {
                model = 'police',
                label = 'Police Cruiser',
                minGrade = 0,
                livery = 0,
            },
            {
                model = 'police2',
                label = 'Police Buffalo',
                minGrade = 1,
                livery = 0,
            },
            {
                model = 'police3',
                label = 'Police Interceptor',
                minGrade = 2,
                livery = 0,
            },
            {
                model = 'police4',
                label = 'Police Unmarked',
                minGrade = 3,
                livery = 0,
            },
            {
                model = 'policet',
                label = 'Police Transporter',
                minGrade = 1,
                livery = 0,
            },
            {
                model = 'policeb',
                label = 'Police Motorcycle',
                minGrade = 1,
                livery = 0,
            },
            {
                model = 'riot',
                label = 'Riot Van',
                minGrade = 4,
                livery = 0,
            },
        },
        sheriff = {
            {
                model = 'sheriff',
                label = 'Sheriff Cruiser',
                minGrade = 0,
                livery = 0,
            },
            {
                model = 'sheriff2',
                label = 'Sheriff SUV',
                minGrade = 1,
                livery = 0,
            },
        },
        statepolice = {
            {
                model = 'police',
                label = 'SASP Cruiser',
                minGrade = 0,
                livery = 1,
            },
            {
                model = 'police2',
                label = 'SASP Buffalo',
                minGrade = 1,
                livery = 1,
            },
            {
                model = 'police3',
                label = 'SASP Interceptor',
                minGrade = 1,
                livery = 1,
            },
        },
        fib = {
            {
                model = 'fbi',
                label = 'FIB Buffalo',
                minGrade = 0,
                livery = 0,
            },
            {
                model = 'fbi2',
                label = 'FIB Granger',
                minGrade = 1,
                livery = 0,
            },
        },
    },

    --- Zone mécanique police (PHASE 8)
    mechanic = {
        enabled = true,
        repairEngine = true,
        repairBody = true,
        repairTyres = true,
        allowMods = false, -- intégration tuning externe
        duration = 6000,
    },

    --- Fourrière (PHASE 7) — intégration externe via Config.Integrations.garage
    impound = {
        enabled = true,
        deleteFallback = true, -- si pas de garage externe : DeleteVehicle propre
        requireOnDuty = true,
    },

    --- Ouverture forcée (PHASE 9+)
    lockForce = {
        enabled = true,
        duration = 5000,
        anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer' },
    },
}
