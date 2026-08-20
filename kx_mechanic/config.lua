Config = {}

Config.Framework = 'qbox'
Config.Target = 'ox_target'
Config.Inventory = 'ox_inventory'
Config.Database = 'oxmysql'

Config.Locale = 'fr'
Config.Debug = false

Config.Job = 'mechanic'
Config.JobLabel = 'Los Santos Customs'

Config.RequireOnDuty = true
Config.ActionCooldown = 1500 -- ms between sensitive actions
Config.MaxRepairDistance = 5.0

Config.EnableBilling = true
Config.EnablePerformance = true
Config.EnableMaintenance = true
Config.EnableLifts = true
Config.EnableOrders = true
Config.EnableDashboard = true
Config.EnableWearSimulation = true

Config.SocietyAccount = 'mechanic'
Config.UseSocietyFunds = true
Config.InvoiceTimeout = 120 -- seconds

Config.BossGrades = { 4 }
Config.ManagementMinGrade = 3
Config.OrdersMinGrade = 3
Config.StockManageMinGrade = 2

Config.Grades = {
    [0] = { name = 'stagiaire', label = 'Stagiaire', salary = 50 },
    [1] = { name = 'mechanic', label = 'Mécanicien', salary = 100 },
    [2] = { name = 'senior', label = 'Mécanicien confirmé', salary = 150 },
    [3] = { name = 'chief', label = 'Chef d\'équipe', salary = 200 },
    [4] = { name = 'boss', label = 'Patron', salary = 250 },
}

Config.Permissions = {
    diagnose = 0,
    repair = 0,
    clean = 0,
    tires = 0,
    maintenance = 1,
    body = 1,
    performance = 2,
    billing = 1,
    stock = 1,
    orders = 3,
    employees = 4,
    dashboard = 3,
    management = 4,
    lift = 0,
}

Config.Blips = {
    enabled = true,
    label = 'Los Santos Customs',
    sprite = 446,
    color = 5,
    scale = 0.85,
    shortRange = true,
    coords = vector3(-339.78, -136.21, 39.01),
}

Config.Locations = {
    shop = {
        coords = vector3(-339.78, -136.21, 39.01),
        radius = 45.0,
    },
    duty = {
        coords = vector3(-341.55, -161.98, 44.59),
        size = vec3(1.2, 1.2, 2.0),
        rotation = 0.0,
    },
    boss = {
        coords = vector3(-339.56, -157.35, 44.59),
        size = vec3(1.4, 1.4, 2.0),
        rotation = 0.0,
    },
    stash = {
        coords = vector3(-345.88, -133.15, 39.01),
        size = vec3(1.5, 1.5, 2.0),
        rotation = 70.0,
        id = 'kx_mechanic_stash',
        label = 'Stock Los Santos Customs',
        slots = 100,
        weight = 500000,
    },
    craft = {
        coords = vector3(-322.35, -129.45, 39.01),
        size = vec3(1.6, 1.6, 2.0),
        rotation = 70.0,
    },
    tools = {
        coords = vector3(-326.12, -144.88, 39.01),
        size = vec3(1.4, 1.4, 2.0),
        rotation = 70.0,
    },
}

Config.Lifts = {
    {
        id = 'lsc_lift_1',
        label = 'Pont hydraulique 1',
        coords = vector3(-332.15, -133.60, 39.01),
        heading = 250.0,
        type = 'hydraulic',
        raiseHeight = 2.2,
        raiseDuration = 4000,
        lowerDuration = 3500,
        radius = 3.5,
    },
    {
        id = 'lsc_lift_2',
        label = 'Pont hydraulique 2',
        coords = vector3(-324.80, -136.10, 39.01),
        heading = 250.0,
        type = 'hydraulic',
        raiseHeight = 2.2,
        raiseDuration = 4000,
        lowerDuration = 3500,
        radius = 3.5,
    },
}

Config.StashItems = {
    'engine_part',
    'brake_part',
    'transmission_part',
    'suspension_part',
    'repair_kit',
    'tire',
    'oil',
    'battery',
    'radiator',
    'spark_plug',
    'cleaning_kit',
    'body_kit',
    'clutch_part',
}

Config.LowStockThreshold = 5

Config.Prices = {
    diagnose = 50,
    repair_engine = 750,
    repair_body = 500,
    repair_brakes = 350,
    repair_transmission = 600,
    repair_suspension = 450,
    repair_clutch = 400,
    repair_radiator = 300,
    repair_lights = 150,
    repair_doors = 200,
    repair_hood = 180,
    repair_trunk = 180,
    repair_bumpers = 220,
    repair_windows = 160,
    repair_tire = 80,
    replace_tire = 150,
    oil_change = 150,
    battery_change = 250,
    spark_plugs = 120,
    clean = 75,
    tire_sport = 400,
    tire_drift = 450,
    tire_offroad = 420,
    tire_race = 600,
    engine_1 = 2500,
    engine_2 = 4500,
    engine_3 = 7000,
    engine_4 = 10000,
    brakes_sport = 2000,
    brakes_race = 4000,
    transmission_sport = 3000,
    transmission_race = 5500,
    suspension_sport = 2200,
    suspension_race = 4200,
    turbo = 5000,
    armor_1 = 1500,
    armor_2 = 3000,
    armor_3 = 5000,
    paint_primary = 350,
    paint_secondary = 300,
    wheels = 500,
}

Config.RepairTimes = {
    diagnose = 5000,
    repair_engine = 15000,
    repair_body = 12000,
    repair_brakes = 10000,
    repair_transmission = 14000,
    repair_suspension = 11000,
    repair_clutch = 10000,
    repair_radiator = 9000,
    repair_lights = 6000,
    repair_doors = 7000,
    repair_hood = 6000,
    repair_trunk = 6000,
    repair_bumpers = 7000,
    repair_windows = 5000,
    repair_tire = 5000,
    replace_tire = 8000,
    oil_change = 10000,
    battery_change = 8000,
    spark_plugs = 7000,
    clean = 6000,
    tire_sport = 9000,
    tire_drift = 9000,
    tire_offroad = 9000,
    tire_race = 10000,
    engine_1 = 20000,
    engine_2 = 25000,
    engine_3 = 30000,
    engine_4 = 35000,
    brakes_sport = 15000,
    brakes_race = 18000,
    transmission_sport = 18000,
    transmission_race = 22000,
    suspension_sport = 15000,
    suspension_race = 18000,
    turbo = 20000,
    armor_1 = 12000,
    armor_2 = 15000,
    armor_3 = 18000,
    paint_primary = 8000,
    paint_secondary = 7000,
    wheels = 8000,
}

Config.RequiredItems = {
    diagnose = {},
    repair_engine = { { item = 'engine_part', count = 1 }, { item = 'repair_kit', count = 2 } },
    repair_body = { { item = 'body_kit', count = 1 }, { item = 'repair_kit', count = 1 } },
    repair_brakes = { { item = 'brake_part', count = 1 }, { item = 'repair_kit', count = 1 } },
    repair_transmission = { { item = 'transmission_part', count = 1 }, { item = 'repair_kit', count = 1 } },
    repair_suspension = { { item = 'suspension_part', count = 1 }, { item = 'repair_kit', count = 1 } },
    repair_clutch = { { item = 'clutch_part', count = 1 }, { item = 'repair_kit', count = 1 } },
    repair_radiator = { { item = 'radiator', count = 1 } },
    repair_lights = { { item = 'repair_kit', count = 1 } },
    repair_doors = { { item = 'body_kit', count = 1 } },
    repair_hood = { { item = 'body_kit', count = 1 } },
    repair_trunk = { { item = 'body_kit', count = 1 } },
    repair_bumpers = { { item = 'body_kit', count = 1 } },
    repair_windows = { { item = 'repair_kit', count = 1 } },
    repair_tire = { { item = 'repair_kit', count = 1 } },
    replace_tire = { { item = 'tire', count = 1 } },
    oil_change = { { item = 'oil', count = 1 } },
    battery_change = { { item = 'battery', count = 1 } },
    spark_plugs = { { item = 'spark_plug', count = 4 } },
    clean = { { item = 'cleaning_kit', count = 1 } },
    tire_sport = { { item = 'tire', count = 4 } },
    tire_drift = { { item = 'tire', count = 4 } },
    tire_offroad = { { item = 'tire', count = 4 } },
    tire_race = { { item = 'tire', count = 4 } },
    engine_1 = { { item = 'engine_part', count = 2 }, { item = 'repair_kit', count = 1 } },
    engine_2 = { { item = 'engine_part', count = 3 }, { item = 'repair_kit', count = 2 } },
    engine_3 = { { item = 'engine_part', count = 4 }, { item = 'repair_kit', count = 2 } },
    engine_4 = { { item = 'engine_part', count = 5 }, { item = 'repair_kit', count = 3 } },
    brakes_sport = { { item = 'brake_part', count = 2 } },
    brakes_race = { { item = 'brake_part', count = 3 } },
    transmission_sport = { { item = 'transmission_part', count = 2 } },
    transmission_race = { { item = 'transmission_part', count = 3 } },
    suspension_sport = { { item = 'suspension_part', count = 2 } },
    suspension_race = { { item = 'suspension_part', count = 3 } },
    turbo = { { item = 'engine_part', count = 2 }, { item = 'repair_kit', count = 1 } },
    armor_1 = { { item = 'body_kit', count = 2 } },
    armor_2 = { { item = 'body_kit', count = 3 } },
    armor_3 = { { item = 'body_kit', count = 4 } },
    paint_primary = {},
    paint_secondary = {},
    wheels = {},
}

Config.Services = {
    {
        id = 'diagnose',
        category = 'diagnostic',
        label = 'Diagnostic véhicule',
        description = 'Analyse complète de l\'état mécanique du véhicule.',
        icon = 'stethoscope',
    },
    {
        id = 'repair_engine',
        category = 'repair',
        label = 'Réparation moteur',
        description = 'Remise en état du bloc moteur et des composants associés.',
        icon = 'gears',
    },
    {
        id = 'repair_body',
        category = 'body',
        label = 'Réparation carrosserie',
        description = 'Répare les déformations et dégâts de carrosserie.',
        icon = 'car',
    },
    {
        id = 'repair_brakes',
        category = 'repair',
        label = 'Réparation freins',
        description = 'Remplacement des plaquettes et révision du circuit de freinage.',
        icon = 'circle-stop',
    },
    {
        id = 'repair_transmission',
        category = 'repair',
        label = 'Réparation transmission',
        description = 'Révision de la boîte de vitesses et des trains.',
        icon = 'gears',
    },
    {
        id = 'repair_suspension',
        category = 'repair',
        label = 'Réparation suspension',
        description = 'Remise en état des amortisseurs et ressorts.',
        icon = 'car-side',
    },
    {
        id = 'repair_clutch',
        category = 'repair',
        label = 'Réparation embrayage',
        description = 'Remplacement et réglage de l\'embrayage.',
        icon = 'cog',
    },
    {
        id = 'repair_radiator',
        category = 'maintenance',
        label = 'Réparation radiateur',
        description = 'Répare le système de refroidissement.',
        icon = 'temperature-high',
    },
    {
        id = 'repair_lights',
        category = 'repair',
        label = 'Réparation phares',
        description = 'Remise en état de l\'éclairage du véhicule.',
        icon = 'lightbulb',
    },
    {
        id = 'repair_doors',
        category = 'body',
        label = 'Réparation portes',
        description = 'Répare et aligne les portes du véhicule.',
        icon = 'door-open',
    },
    {
        id = 'repair_hood',
        category = 'body',
        label = 'Réparation capot',
        description = 'Répare le capot et ses charnières.',
        icon = 'car',
    },
    {
        id = 'repair_trunk',
        category = 'body',
        label = 'Réparation coffre',
        description = 'Répare le hayon / coffre.',
        icon = 'box',
    },
    {
        id = 'repair_bumpers',
        category = 'body',
        label = 'Réparation pare-chocs',
        description = 'Remise en état des pare-chocs avant et arrière.',
        icon = 'car-burst',
    },
    {
        id = 'repair_windows',
        category = 'body',
        label = 'Réparation vitres',
        description = 'Remplacement des vitres endommagées.',
        icon = 'window-maximize',
    },
    {
        id = 'repair_tire',
        category = 'tires',
        label = 'Réparer pneu',
        description = 'Répare un pneu crevé ou usé.',
        icon = 'circle',
    },
    {
        id = 'replace_tire',
        category = 'tires',
        label = 'Changer pneu',
        description = 'Remplace complètement un pneu.',
        icon = 'circle-dot',
    },
    {
        id = 'oil_change',
        category = 'maintenance',
        label = 'Vidange',
        description = 'Remplacement de l\'huile moteur.',
        icon = 'oil-can',
    },
    {
        id = 'battery_change',
        category = 'maintenance',
        label = 'Changer batterie',
        description = 'Installation d\'une batterie neuve.',
        icon = 'car-battery',
    },
    {
        id = 'spark_plugs',
        category = 'maintenance',
        label = 'Changer bougies',
        description = 'Remplacement des bougies d\'allumage.',
        icon = 'bolt',
    },
    {
        id = 'clean',
        category = 'maintenance',
        label = 'Nettoyer véhicule',
        description = 'Nettoyage complet intérieur / extérieur.',
        icon = 'spray-can-sparkles',
    },
    {
        id = 'tire_sport',
        category = 'tires',
        label = 'Pneus sport',
        description = 'Monte un train de pneus sport.',
        icon = 'circle',
    },
    {
        id = 'tire_drift',
        category = 'tires',
        label = 'Pneus drift',
        description = 'Monte un train de pneus drift.',
        icon = 'circle',
    },
    {
        id = 'tire_offroad',
        category = 'tires',
        label = 'Pneus tout-terrain',
        description = 'Monte un train de pneus tout-terrain.',
        icon = 'circle',
    },
    {
        id = 'tire_race',
        category = 'tires',
        label = 'Pneus course',
        description = 'Monte un train de pneus course.',
        icon = 'circle',
    },
    {
        id = 'engine_1',
        category = 'performance',
        label = 'Moteur niveau 1',
        description = 'Amélioration moteur niveau 1.',
        icon = 'gauge-high',
    },
    {
        id = 'engine_2',
        category = 'performance',
        label = 'Moteur niveau 2',
        description = 'Amélioration moteur niveau 2.',
        icon = 'gauge-high',
    },
    {
        id = 'engine_3',
        category = 'performance',
        label = 'Moteur niveau 3',
        description = 'Amélioration moteur niveau 3.',
        icon = 'gauge-high',
    },
    {
        id = 'engine_4',
        category = 'performance',
        label = 'Moteur niveau 4',
        description = 'Amélioration moteur niveau 4.',
        icon = 'gauge-high',
    },
    {
        id = 'brakes_sport',
        category = 'performance',
        label = 'Freins sport',
        description = 'Installation de freins sport.',
        icon = 'circle-stop',
    },
    {
        id = 'brakes_race',
        category = 'performance',
        label = 'Freins race',
        description = 'Installation de freins course.',
        icon = 'circle-stop',
    },
    {
        id = 'transmission_sport',
        category = 'performance',
        label = 'Transmission sport',
        description = 'Boîte de vitesses sport.',
        icon = 'gears',
    },
    {
        id = 'transmission_race',
        category = 'performance',
        label = 'Transmission race',
        description = 'Boîte de vitesses course.',
        icon = 'gears',
    },
    {
        id = 'suspension_sport',
        category = 'performance',
        label = 'Suspension sport',
        description = 'Kit suspension sport.',
        icon = 'car-side',
    },
    {
        id = 'suspension_race',
        category = 'performance',
        label = 'Suspension race',
        description = 'Kit suspension course.',
        icon = 'car-side',
    },
    {
        id = 'turbo',
        category = 'performance',
        label = 'Turbo',
        description = 'Installation d\'un turbo.',
        icon = 'wind',
    },
    {
        id = 'armor_1',
        category = 'performance',
        label = 'Blindage niveau 1',
        description = 'Renforcement carrosserie niveau 1.',
        icon = 'shield',
    },
    {
        id = 'armor_2',
        category = 'performance',
        label = 'Blindage niveau 2',
        description = 'Renforcement carrosserie niveau 2.',
        icon = 'shield',
    },
    {
        id = 'armor_3',
        category = 'performance',
        label = 'Blindage niveau 3',
        description = 'Renforcement carrosserie niveau 3.',
        icon = 'shield',
    },
    {
        id = 'paint_primary',
        category = 'body',
        label = 'Peinture principale',
        description = 'Change la couleur principale.',
        icon = 'palette',
    },
    {
        id = 'paint_secondary',
        category = 'body',
        label = 'Peinture secondaire',
        description = 'Change la couleur secondaire.',
        icon = 'palette',
    },
    {
        id = 'wheels',
        category = 'body',
        label = 'Changer jantes',
        description = 'Installation de nouvelles jantes.',
        icon = 'dharmachakra',
    },
}

Config.Categories = {
    { id = 'repair', label = 'Réparation', icon = 'wrench' },
    { id = 'diagnostic', label = 'Diagnostic', icon = 'stethoscope' },
    { id = 'performance', label = 'Performance', icon = 'gauge-high' },
    { id = 'body', label = 'Carrosserie', icon = 'car' },
    { id = 'tires', label = 'Pneus', icon = 'circle' },
    { id = 'maintenance', label = 'Entretien', icon = 'oil-can' },
    { id = 'stock', label = 'Stock', icon = 'boxes-stacked' },
    { id = 'billing', label = 'Facturation', icon = 'file-invoice-dollar' },
    { id = 'orders', label = 'Commandes', icon = 'clipboard-list' },
    { id = 'employees', label = 'Employés', icon = 'users' },
    { id = 'management', label = 'Gestion entreprise', icon = 'building' },
}

Config.PerformanceMods = {
    engine = {
        label = 'Moteur',
        levels = {
            { id = 'stock', label = 'Stock', modIndex = -1, service = nil },
            { id = 'engine_1', label = 'Niveau 1', modIndex = 0, service = 'engine_1' },
            { id = 'engine_2', label = 'Niveau 2', modIndex = 1, service = 'engine_2' },
            { id = 'engine_3', label = 'Niveau 3', modIndex = 2, service = 'engine_3' },
            { id = 'engine_4', label = 'Niveau 4', modIndex = 3, service = 'engine_4' },
        },
        modType = 11,
    },
    brakes = {
        label = 'Freins',
        levels = {
            { id = 'stock', label = 'Stock', modIndex = -1, service = nil },
            { id = 'brakes_sport', label = 'Sport', modIndex = 0, service = 'brakes_sport' },
            { id = 'brakes_race', label = 'Race', modIndex = 1, service = 'brakes_race' },
        },
        modType = 12,
    },
    transmission = {
        label = 'Transmission',
        levels = {
            { id = 'stock', label = 'Stock', modIndex = -1, service = nil },
            { id = 'transmission_sport', label = 'Sport', modIndex = 0, service = 'transmission_sport' },
            { id = 'transmission_race', label = 'Race', modIndex = 1, service = 'transmission_race' },
        },
        modType = 13,
    },
    suspension = {
        label = 'Suspension',
        levels = {
            { id = 'stock', label = 'Stock', modIndex = -1, service = nil },
            { id = 'suspension_sport', label = 'Sport', modIndex = 0, service = 'suspension_sport' },
            { id = 'suspension_race', label = 'Race', modIndex = 1, service = 'suspension_race' },
        },
        modType = 15,
    },
    turbo = {
        label = 'Turbo',
        levels = {
            { id = 'off', label = 'Désactivé', enabled = false, service = nil },
            { id = 'on', label = 'Activé', enabled = true, service = 'turbo' },
        },
        modType = 18,
    },
    armor = {
        label = 'Blindage',
        levels = {
            { id = 'stock', label = 'Stock', modIndex = -1, service = nil },
            { id = 'armor_1', label = 'Niveau 1', modIndex = 0, service = 'armor_1' },
            { id = 'armor_2', label = 'Niveau 2', modIndex = 1, service = 'armor_2' },
            { id = 'armor_3', label = 'Niveau 3', modIndex = 2, service = 'armor_3' },
        },
        modType = 16,
    },
}

Config.TireTypes = {
    stock = { label = 'Stock', traction = 1.0 },
    sport = { label = 'Sport', traction = 1.15 },
    drift = { label = 'Drift', traction = 0.75 },
    offroad = { label = 'Tout-terrain', traction = 1.05 },
    race = { label = 'Course', traction = 1.25 },
}

Config.Wear = {
    tickInterval = 30000,
    mileagePerTick = 0.15,
    baseWear = {
        oil = 0.08,
        battery = 0.03,
        radiator = 0.05,
        spark_plugs = 0.04,
        brakes = 0.06,
        transmission = 0.04,
        suspension = 0.05,
        clutch = 0.05,
        tires = 0.07,
    },
    aggressiveMultiplier = 2.2,
    overheatThreshold = 110.0,
    overheatWearBoost = 1.8,
    minComponentHealth = 5.0,
}

Config.Suppliers = {
    {
        id = 'autozone',
        label = 'AutoZone Parts',
        deliveryMinutes = { min = 2, max = 5 },
    },
    {
        id = 'lsc_wholesale',
        label = 'LSC Wholesale',
        deliveryMinutes = { min = 3, max = 6 },
    },
    {
        id = 'racing_supply',
        label = 'Racing Supply Co.',
        deliveryMinutes = { min = 4, max = 8 },
    },
}

Config.OrderCatalog = {
    { item = 'engine_part', label = 'Pièce moteur', unitPrice = 250, supplier = 'autozone' },
    { item = 'brake_part', label = 'Pièce freins', unitPrice = 120, supplier = 'autozone' },
    { item = 'transmission_part', label = 'Pièce transmission', unitPrice = 280, supplier = 'lsc_wholesale' },
    { item = 'suspension_part', label = 'Pièce suspension', unitPrice = 180, supplier = 'lsc_wholesale' },
    { item = 'clutch_part', label = 'Pièce embrayage', unitPrice = 160, supplier = 'autozone' },
    { item = 'repair_kit', label = 'Kit de réparation', unitPrice = 80, supplier = 'autozone' },
    { item = 'tire', label = 'Pneu', unitPrice = 90, supplier = 'racing_supply' },
    { item = 'oil', label = 'Huile moteur', unitPrice = 40, supplier = 'autozone' },
    { item = 'battery', label = 'Batterie', unitPrice = 150, supplier = 'lsc_wholesale' },
    { item = 'radiator', label = 'Radiateur', unitPrice = 200, supplier = 'lsc_wholesale' },
    { item = 'spark_plug', label = 'Bougie', unitPrice = 25, supplier = 'autozone' },
    { item = 'cleaning_kit', label = 'Kit nettoyage', unitPrice = 35, supplier = 'autozone' },
    { item = 'body_kit', label = 'Kit carrosserie', unitPrice = 140, supplier = 'racing_supply' },
}

Config.Animations = {
    diagnose = {
        dict = 'mini@repair',
        clip = 'fixing_a_ped',
        flag = 1,
        prop = nil,
    },
    repair_engine = {
        dict = 'mini@repair',
        clip = 'fixing_a_ped',
        flag = 1,
        openHood = true,
    },
    repair_body = {
        dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
        clip = 'machinic_loop_mechandplayer',
        flag = 1,
    },
    repair_tire = {
        dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
        clip = 'machinic_loop_mechandplayer',
        flag = 1,
    },
    replace_tire = {
        dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
        clip = 'machinic_loop_mechandplayer',
        flag = 1,
    },
    oil_change = {
        dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
        clip = 'machinic_loop_mechandplayer',
        flag = 1,
        underVehicle = true,
    },
    clean = {
        dict = 'timetable@floyd@clean_kitchen@base',
        clip = 'base',
        flag = 49,
    },
    default = {
        dict = 'mini@repair',
        clip = 'fixing_a_ped',
        flag = 1,
    },
}

Config.DefaultVehicleData = {
    engine_health = 1000.0,
    body_health = 1000.0,
    brakes_health = 100.0,
    transmission_health = 100.0,
    suspension_health = 100.0,
    clutch_health = 100.0,
    radiator_level = 100.0,
    oil_level = 100.0,
    battery_level = 100.0,
    spark_plugs = 100.0,
    tire_fl = 100.0,
    tire_fr = 100.0,
    tire_rl = 100.0,
    tire_rr = 100.0,
    tire_type = 'stock',
    fuel = 100.0,
    engine_temp = 90.0,
    mileage = 0.0,
    performance = {
        engine = 'stock',
        brakes = 'stock',
        transmission = 'stock',
        suspension = 'stock',
        turbo = 'off',
        armor = 'stock',
    },
    cosmetics = {
        primary = nil,
        secondary = nil,
        wheels = nil,
    },
}

Config.PaintColors = {
    { id = 0, label = 'Noir métallisé' },
    { id = 27, label = 'Rouge' },
    { id = 64, label = 'Bleu' },
    { id = 88, label = 'Jaune' },
    { id = 53, label = 'Vert' },
    { id = 111, label = 'Blanc' },
    { id = 12, label = 'Noir mat' },
    { id = 38, label = 'Orange' },
    { id = 145, label = 'Violet' },
    { id = 131, label = 'Gris' },
}

Config.WheelOptions = {
    { id = 0, label = 'Sport' },
    { id = 1, label = 'Muscle' },
    { id = 2, label = 'Lowrider' },
    { id = 3, label = 'SUV' },
    { id = 4, label = 'Offroad' },
    { id = 5, label = 'Tuner' },
    { id = 7, label = 'High End' },
}