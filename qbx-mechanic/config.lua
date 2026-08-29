Config = {}

-- =============================================================================
-- GÉNÉRAL
-- =============================================================================

Config.Debug = false
Config.Locale = 'fr'
Config.ResourceName = 'qbx-mechanic'

--- Distance maximale pour ox_target (véhicules & entités)
Config.TargetDistance = 2.5

--- Distance maximale serveur pour valider une action sur véhicule
Config.MaxActionDistance = 6.0

--- Cooldown entre actions sensibles (ms)
Config.ActionCooldown = 1500

--- Le mécanicien doit être en service (duty)
Config.RequireOnDuty = true

--- Symbole monétaire affiché dans la NUI
Config.CurrencySymbol = '$'

-- =============================================================================
-- FRAMEWORK & INTÉGRATIONS
-- =============================================================================

Config.Framework = {
    name = 'qbox',
    resource = 'qbx_core',
}

--- Intégrations optionnelles — laisser `enabled = false` si non installé
Config.Integrations = {
    inventory = {
        enabled = true,
        resource = 'ox_inventory',
    },
    fuel = {
        enabled = true,
        resource = 'ox_fuel',
        --- Export client pour lire le carburant (nil = natives GTA)
        getFuelExport = nil,
    },
    billing = {
        --- auto | internal | renewed | qb-banking | okok | custom
        provider = 'auto',
        resource = nil,
    },
    society = {
        --- auto | renewed | qb-banking | qbx_management | internal
        provider = 'auto',
        resource = nil,
    },
    appearance = {
        enabled = true,
        --- illenium-appearance | qb-clothing | ox_appearance
        resource = 'illenium-appearance',
    },
    management = {
        enabled = true,
        resource = 'qbx_management',
    },
}

-- =============================================================================
-- JOB & GRADES
-- =============================================================================

Config.Job = {
    name = 'mechanic',
    label = 'Mécanicien',
}

Config.Grades = {
    [0] = { name = 'stagiaire', label = 'Stagiaire', salary = 50 },
    [1] = { name = 'mecanicien', label = 'Mécanicien', salary = 100 },
    [2] = { name = 'senior', label = 'Mécanicien confirmé', salary = 150 },
    [3] = { name = 'chef', label = 'Chef d\'équipe', salary = 200 },
    [4] = { name = 'boss', label = 'Boss', salary = 250, isboss = true },
}

--- Permissions minimales par grade (0-4)
Config.Permissions = {
    diagnose = 0,
    repair = 0,
    clean = 0,
    tires = 0,
    body = 1,
    engine = 1,
    billing = 1,
    tuning = 2,
    performance = 2,
    stock = 2,
    lift = 0,
    garage = 0,
    wardrobe = 0,
    boss = 4,
    management = 3,
}

-- =============================================================================
-- SOCIÉTÉS MÉCANIQUES
-- =============================================================================

Config.Mechanics = {
    bennys = {
        label = 'Benny\'s Original Motor Works',
        job = 'mechanic',
        societyAccount = 'bennys',

        bossGrades = {
            [4] = true,
        },

        managementMinGrade = 3,

        blip = {
            enabled = true,
            coords = vector3(-205.76, -1308.24, 31.29),
            sprite = 446,
            color = 5,
            scale = 0.85,
            shortRange = true,
            label = 'Benny\'s Motor Works',
        },

        locations = {
            --- Zone principale du garage (poly ou sphere)
            shop = {
                coords = vector3(-205.76, -1308.24, 31.29),
                radius = 40.0,
            },

            duty = {
                coords = vector3(-219.43, -1337.69, 31.30),
                size = vec3(1.2, 1.2, 2.0),
                rotation = 0.0,
                label = 'Prise / fin de service',
            },

            boss = {
                coords = vector3(-216.05, -1337.97, 31.30),
                size = vec3(1.4, 1.4, 2.0),
                rotation = 0.0,
                label = 'Menu patron',
            },

            wardrobe = {
                coords = vector3(-212.55, -1339.05, 31.30),
                size = vec3(1.5, 1.5, 2.0),
                rotation = 0.0,
                label = 'Vestiaire',
            },

            garage = {
                coords = vector3(-190.58, -1290.63, 31.30),
                size = vec3(3.0, 3.0, 2.5),
                rotation = 270.0,
                label = 'Garage véhicules de service',
                spawn = vector4(-182.42, -1289.61, 31.30, 90.0),
            },

            stashes = {
                personal = {
                    coords = vector3(-199.58, -1314.65, 31.30),
                    size = vec3(1.5, 1.5, 2.0),
                    rotation = 0.0,
                    id = 'bennys_personal',
                    label = 'Casier personnel',
                    slots = 50,
                    weight = 100000,
                    minGrade = 0,
                },
                company = {
                    coords = vector3(-196.85, -1315.38, 31.30),
                    size = vec3(1.8, 1.8, 2.0),
                    rotation = 0.0,
                    id = 'bennys_company',
                    label = 'Coffre entreprise',
                    slots = 100,
                    weight = 500000,
                    minGrade = 1,
                },
                parts = {
                    coords = vector3(-194.12, -1316.10, 31.30),
                    size = vec3(2.0, 2.0, 2.0),
                    rotation = 0.0,
                    id = 'bennys_parts',
                    label = 'Stock pièces',
                    slots = 150,
                    weight = 750000,
                    minGrade = 1,
                },
            },

            repairZones = {
                {
                    id = 'bennys_bay_1',
                    label = 'Poste 1',
                    coords = vector3(-211.55, -1324.55, 31.30),
                    size = vec3(5.0, 8.0, 3.0),
                    rotation = 0.0,
                },
                {
                    id = 'bennys_bay_2',
                    label = 'Poste 2',
                    coords = vector3(-221.55, -1324.55, 31.30),
                    size = vec3(5.0, 8.0, 3.0),
                    rotation = 0.0,
                },
            },

            tuningZones = {
                {
                    id = 'bennys_tune_1',
                    label = 'Zone tuning',
                    coords = vector3(-215.55, -1330.55, 31.30),
                    size = vec3(6.0, 10.0, 3.0),
                    rotation = 0.0,
                    selfService = false,
                },
            },
        },

        lifts = {
            {
                id = 'bennys_lift_1',
                label = 'Pont 1',
                coords = vector3(-211.55, -1324.55, 31.30),
                heading = 0.0,
                raiseHeight = 2.2,
                raiseDuration = 4000,
                lowerDuration = 3500,
                radius = 3.5,
            },
        },

        serviceVehicles = {
            { model = 'towtruck', label = 'Dépanneuse', minGrade = 0 },
            { model = 'flatbed', label = 'Plateau', minGrade = 1 },
            { model = 'slamvan3', label = 'Slamvan', minGrade = 2 },
            { model = 'utility', label = 'Utility', minGrade = 0 },
        },

        outfits = {
            civilian = {
                label = 'Tenue civile',
                restore = true,
            },
            mechanic = {
                label = 'Tenue mécanicien',
                minGrade = 0,
                --- Compatible illenium-appearance / qb-clothing (configurable étape 11)
                components = {},
                props = {},
            },
            chief = {
                label = 'Tenue chef',
                minGrade = 3,
                components = {},
                props = {},
            },
            boss = {
                label = 'Tenue boss',
                minGrade = 4,
                components = {},
                props = {},
            },
        },
    },

    lscustoms = {
        label = 'Los Santos Customs',
        job = 'mechanic',
        societyAccount = 'lscustoms',

        bossGrades = {
            [4] = true,
        },

        managementMinGrade = 3,

        blip = {
            enabled = true,
            coords = vector3(-339.78, -136.21, 39.01),
            sprite = 446,
            color = 3,
            scale = 0.85,
            shortRange = true,
            label = 'LS Customs',
        },

        locations = {
            shop = {
                coords = vector3(-339.78, -136.21, 39.01),
                radius = 45.0,
            },

            duty = {
                coords = vector3(-341.55, -161.98, 44.59),
                size = vec3(1.2, 1.2, 2.0),
                rotation = 0.0,
                label = 'Prise / fin de service',
            },

            boss = {
                coords = vector3(-339.56, -157.35, 44.59),
                size = vec3(1.4, 1.4, 2.0),
                rotation = 0.0,
                label = 'Menu patron',
            },

            wardrobe = {
                coords = vector3(-344.55, -158.98, 44.59),
                size = vec3(1.5, 1.5, 2.0),
                rotation = 0.0,
                label = 'Vestiaire',
            },

            garage = {
                coords = vector3(-370.55, -108.98, 38.68),
                size = vec3(3.0, 3.0, 2.5),
                rotation = 70.0,
                label = 'Garage véhicules de service',
                spawn = vector4(-365.55, -110.98, 38.68, 70.0),
            },

            stashes = {
                personal = {
                    coords = vector3(-345.88, -133.15, 39.01),
                    size = vec3(1.5, 1.5, 2.0),
                    rotation = 70.0,
                    id = 'lsc_personal',
                    label = 'Casier personnel',
                    slots = 50,
                    weight = 100000,
                    minGrade = 0,
                },
                company = {
                    coords = vector3(-348.88, -131.15, 39.01),
                    size = vec3(1.8, 1.8, 2.0),
                    rotation = 70.0,
                    id = 'lsc_company',
                    label = 'Coffre entreprise',
                    slots = 100,
                    weight = 500000,
                    minGrade = 1,
                },
                parts = {
                    coords = vector3(-322.35, -129.45, 39.01),
                    size = vec3(2.0, 2.0, 2.0),
                    rotation = 70.0,
                    id = 'lsc_parts',
                    label = 'Stock pièces',
                    slots = 150,
                    weight = 750000,
                    minGrade = 1,
                },
            },

            repairZones = {
                {
                    id = 'lsc_bay_1',
                    label = 'Poste 1',
                    coords = vector3(-332.15, -133.60, 39.01),
                    size = vec3(5.0, 8.0, 3.0),
                    rotation = 250.0,
                },
            },

            tuningZones = {
                {
                    id = 'lsc_tune_1',
                    label = 'Zone tuning',
                    coords = vector3(-324.80, -136.10, 39.01),
                    size = vec3(6.0, 10.0, 3.0),
                    rotation = 250.0,
                    selfService = false,
                },
            },
        },

        lifts = {
            {
                id = 'lsc_lift_1',
                label = 'Pont hydraulique',
                coords = vector3(-332.15, -133.60, 39.01),
                heading = 250.0,
                raiseHeight = 2.2,
                raiseDuration = 4000,
                lowerDuration = 3500,
                radius = 3.5,
            },
        },

        serviceVehicles = {
            { model = 'towtruck', label = 'Dépanneuse', minGrade = 0 },
            { model = 'flatbed', label = 'Plateau', minGrade = 1 },
        },

        outfits = {
            civilian = { label = 'Tenue civile', restore = true },
            mechanic = { label = 'Tenue mécanicien', minGrade = 0, components = {}, props = {} },
            chief = { label = 'Tenue chef', minGrade = 3, components = {}, props = {} },
            boss = { label = 'Tenue boss', minGrade = 4, components = {}, props = {} },
        },
    },
}

-- =============================================================================
-- COMMANDES
-- =============================================================================

Config.Commands = {
    mechanic = {
        enabled = true,
        name = 'mechanic',
        description = 'Ouvrir le menu mécanicien',
    },
    diagnostic = {
        enabled = true,
        name = 'diagnostic',
        description = 'Lancer un diagnostic véhicule',
    },
    repair = {
        enabled = true,
        name = 'repair',
        description = 'Menu réparation rapide',
    },
}

-- =============================================================================
-- RÉPARATIONS
-- =============================================================================

Config.Repairs = {
    quick = {
        label = 'Réparation rapide',
        services = { 'engine', 'body', 'tires' },
    },
    full = {
        label = 'Réparation complète',
        services = { 'engine', 'body', 'tires', 'clean' },
    },
}

Config.RepairDurations = {
    engine = 10000,
    body = 8000,
    tires = 6000,
    clean = 5000,
    full = 20000,
    diagnostic = 4000,
}

Config.RepairAnimations = {
    default = {
        dict = 'mini@repair',
        clip = 'fixing_a_player',
        flag = 49,
    },
    engine = {
        dict = 'mini@repair',
        clip = 'fixing_a_player',
        flag = 49,
    },
    body = {
        dict = 'amb@world_human_welding@male@base',
        clip = 'base',
        flag = 49,
    },
    tires = {
        dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
        clip = 'machinic_loop_mechandplayer',
        flag = 49,
    },
    clean = {
        dict = 'timetable@floyd@clean_kitchen@base',
        clip = 'base',
        flag = 49,
    },
}

Config.RepairSounds = {
    enabled = true,
    name = 'CHECKPOINT_PERFECT',
    set = 'HUD_MINI_GAME_SOUNDSET',
}

-- =============================================================================
-- PRIX & FACTURATION
-- =============================================================================

Config.Prices = {
    diagnostic = 150,
    engine = 750,
    body = 500,
    tires = 300,
    clean = 200,
    full = 1500,
    paint = 800,
    performance = 1000,
    customization = 1000,
}

Config.Billing = {
    enabled = true,
    invoiceTimeout = 120,
    allowCustomAmount = false,
    societyCut = 1.0,
    services = {
        { id = 'engine', label = 'Réparation moteur', price = 750 },
        { id = 'body', label = 'Carrosserie', price = 500 },
        { id = 'tires', label = 'Pneus', price = 300 },
        { id = 'clean', label = 'Nettoyage', price = 200 },
        { id = 'full', label = 'Réparation complète', price = 1500 },
        { id = 'customization', label = 'Customisation', price = 1000 },
        { id = 'performance', label = 'Performance', price = 1000 },
        { id = 'diagnostic', label = 'Diagnostic', price = 150 },
    },
}

-- =============================================================================
-- PIÈCES & INVENTAIRE
-- =============================================================================

Config.Items = {
    engine_oil = { label = 'Huile moteur', weight = 500 },
    brake_pads = { label = 'Plaquettes de frein', weight = 800 },
    spark_plug = { label = 'Bougie d\'allumage', weight = 200 },
    car_battery = { label = 'Batterie', weight = 5000 },
    tire = { label = 'Pneu', weight = 10000 },
    repair_kit = { label = 'Kit de réparation', weight = 3000 },
    body_parts = { label = 'Pièces carrosserie', weight = 4000 },
}

Config.RequiredItems = {
    engine = {
        { item = 'engine_oil', count = 2 },
        { item = 'spark_plug', count = 1 },
    },
    body = {
        { item = 'body_parts', count = 1 },
    },
    tires = {
        { item = 'tire', count = 1 },
    },
    brakes = {
        { item = 'brake_pads', count = 1 },
    },
}

Config.RequireItems = true

-- =============================================================================
-- TUNING
-- =============================================================================

Config.Tuning = {
    enabled = true,
    requireConfirmation = true,
    previewMode = true,

    categories = {
        { id = 'engine', label = 'Moteur', modType = 11, maxLevel = 3 },
        { id = 'brakes', label = 'Freins', modType = 12, maxLevel = 2 },
        { id = 'transmission', label = 'Transmission', modType = 13, maxLevel = 2 },
        { id = 'suspension', label = 'Suspension', modType = 15, maxLevel = 3 },
        { id = 'turbo', label = 'Turbo', modType = 18, maxLevel = 1, isToggle = true },
        { id = 'armor', label = 'Blindage', modType = 16, maxLevel = 4 },
        { id = 'exhaust', label = 'Échappement', modType = 4, maxLevel = nil },
        { id = 'bumper_f', label = 'Pare-chocs avant', modType = 1, maxLevel = nil },
        { id = 'bumper_r', label = 'Pare-chocs arrière', modType = 2, maxLevel = nil },
        { id = 'hood', label = 'Capot', modType = 7, maxLevel = nil },
        { id = 'spoiler', label = 'Aileron', modType = 0, maxLevel = nil },
        { id = 'wheels', label = 'Jantes', modType = 23, maxLevel = nil },
        { id = 'tires_smoke', label = 'Pneus', modType = 'tiresmoke', maxLevel = nil },
        { id = 'paint', label = 'Peinture', modType = 'paint', maxLevel = nil },
        { id = 'windows', label = 'Vitres', modType = 'windows', maxLevel = nil },
        { id = 'neon', label = 'Néons', modType = 'neon', maxLevel = nil },
        { id = 'xenon', label = 'Xénon', modType = 'xenon', maxLevel = nil },
        { id = 'plate', label = 'Plaques', modType = 25, maxLevel = nil },
    },

    performancePrices = {
        engine = { 0, 5000, 10000, 20000 },
        brakes = { 0, 3000, 6000 },
        transmission = { 0, 4000, 8000 },
        suspension = { 0, 2500, 5000, 7500 },
        turbo = { 0, 15000 },
        armor = { 0, 2000, 4000, 6000, 8000 },
    },

    performanceLabels = {
        engine = { 'Stock', 'Stage 1', 'Stage 2', 'Stage 3' },
        brakes = { 'Stock', 'Sport', 'Race' },
        transmission = { 'Stock', 'Street', 'Race' },
        suspension = { 'Stock', 'Lowered', 'Sport', 'Competition' },
    },
}

-- =============================================================================
-- STOCK ENTREPRISE
-- =============================================================================

Config.Stock = {
    enabled = true,
    lowStockThreshold = 5,
    defaultPrices = {
        engine_oil = 25,
        brake_pads = 80,
        spark_plug = 15,
        car_battery = 120,
        tire = 150,
        repair_kit = 200,
        body_parts = 350,
    },
}

-- =============================================================================
-- LOGS DISCORD
-- =============================================================================

Config.Logs = {
    enabled = true,
    webhook = '',
    botName = 'QBX Mechanic',
    avatar = '',
    colors = {
        repair = 3066993,
        tuning = 3447003,
        invoice = 15844367,
        stock = 10181046,
        management = 15158332,
        security = 15105570,
    },
    events = {
        repair = true,
        tuning = true,
        invoice = true,
        grade = true,
        hire = true,
        fire = true,
        vehicle_mod = true,
        parts = true,
    },
}

-- =============================================================================
-- NUI
-- =============================================================================

Config.NUI = {
    colors = {
        primary = '#3b82f6',
        primaryHover = '#2563eb',
        accent = '#22d3ee',
        background = '#0f1117',
        surface = '#1a1d27',
        surfaceHover = '#252936',
        border = '#2d3348',
        text = '#f1f5f9',
        textMuted = '#94a3b8',
        success = '#22c55e',
        warning = '#f59e0b',
        danger = '#ef4444',
    },
    animations = {
        enabled = true,
        duration = 250,
    },
    keyClose = 'ESCAPE',
}

-- =============================================================================
-- LIFTS (référence globale — chaque société a aussi ses lifts)
-- =============================================================================

Config.Lifts = {
    attachOnRaise = false,
    maxHeight = 2.5,
    interactionDistance = 2.0,
}

-- =============================================================================
-- OX_TARGET — icônes
-- =============================================================================

Config.TargetIcons = {
    vehicle = 'fa-solid fa-wrench',
    diagnose = 'fa-solid fa-stethoscope',
    repair = 'fa-solid fa-screwdriver-wrench',
    tuning = 'fa-solid fa-sliders',
    lift = 'fa-solid fa-arrow-up-from-ground-water',
    stash = 'fa-solid fa-box',
    wardrobe = 'fa-solid fa-shirt',
    garage = 'fa-solid fa-car',
    boss = 'fa-solid fa-briefcase',
    billing = 'fa-solid fa-file-invoice-dollar',
}
