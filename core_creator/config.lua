Config = {}

------------------------------------------------------------
-- Core
------------------------------------------------------------
Config.Locale = 'fr'
Config.Debug = false
Config.ResourceName = 'core_creator'

-- auto | esx | qbcore | qbox | standalone
Config.Framework = 'auto'

-- auto | ox_inventory | qb-inventory | qs-inventory | esx | none
Config.Inventory = 'auto'

-- auto | ox_target | qb-target | marker | none
Config.Target = 'auto'

-- auto | ox_lib | esx | qb | native
Config.Notify = 'auto'
Config.Progressbar = 'auto'

-- auto | ps-dispatch | cd_dispatch | qs-dispatch | none
Config.Dispatch = 'auto'

-- auto | ox_fuel | LegacyFuel | cdn-fuel | none
Config.Fuel = 'auto'

-- auto | wasabi_carlock | qs-vehiclekeys | qb-vehiclekeys | core_creator | none
Config.VehicleKeys = 'auto'

------------------------------------------------------------
-- Modules (enable / disable)
------------------------------------------------------------
Config.Modules = {
    shops = true,
    blips = true,
    vehicles = true,
    farms = true,
    jobs = true,
    garages = true,
    gangs = true,
    apartments = true,
    robberies = true,
}

------------------------------------------------------------
-- Commands
------------------------------------------------------------
Config.Commands = {
    open = 'corecreator',
    reload = 'corecreator_reload',
    debug = 'corecreator_debug',
    teleport = 'corecreator_tp',
    export = 'corecreator_export',
    import = 'corecreator_import',
}

------------------------------------------------------------
-- Permissions
-- ACE examples:
--   add_ace group.admin core_creator.admin allow
--   add_ace group.admin core_creator.module.shops allow
------------------------------------------------------------
Config.Permissions = {
    -- ACE permission required for opening the panel
    ace = 'core_creator.admin',
    -- Module-specific ACE (checked in addition to admin)
    modules = {
        shops = 'core_creator.module.shops',
        blips = 'core_creator.module.blips',
        vehicles = 'core_creator.module.vehicles',
        farms = 'core_creator.module.farms',
        jobs = 'core_creator.module.jobs',
        garages = 'core_creator.module.garages',
        gangs = 'core_creator.module.gangs',
        apartments = 'core_creator.module.apartments',
        robberies = 'core_creator.module.robberies',
    },
    -- Framework admin groups / jobs used as fallback when ACE is not set
    frameworkGroups = {
        esx = { 'admin', 'superadmin' },
        qbcore = { 'admin', 'god' },
        qbox = { 'admin', 'god' },
    },
    -- If true, ACE alone is enough (framework group not required)
    aceOnly = false,
    -- If true, framework admin group alone is enough (ACE not required)
    frameworkOnly = false,
}

------------------------------------------------------------
-- Distances / performance
------------------------------------------------------------
Config.Distances = {
    interaction = 2.0,
    markerDraw = 25.0,
    stream = 80.0,
    placementSnap = 0.05,
    robberyCancel = 35.0,
}

Config.Tick = {
    nearbyScan = 750,
    markerDraw = 0,
    idleSleep = 1000,
}

Config.Limits = {
    name = 64,
    label = 128,
    jsonPayload = 250000,
    itemsPerShop = 100,
    farmStages = 20,
    robberyStages = 30,
    garageSpawns = 12,
    apartmentsPerBuilding = 80,
    apartmentsPerPlayer = 3,
    gradesPerJob = 20,
    gradesPerGang = 15,
    stringMax = 255,
    arrayMax = 200,
    importBatch = 50,
}

Config.Cooldowns = {
    nuiAction = 250,
    farmAction = 1500,
    robberyStart = 5000,
    garageStore = 2000,
    garageSpawn = 2000,
    shopBuy = 1000,
    adminMutate = 400,
}

------------------------------------------------------------
-- Placement tool
------------------------------------------------------------
Config.Placement = {
    cameraSpeed = 0.35,
    cameraFastMultiplier = 3.0,
    rotateSpeed = 1.5,
    confirmControl = 191, -- ENTER
    cancelControl = 202,  -- BACKSPACE
    fineControl = 21,     -- LEFT SHIFT
}

------------------------------------------------------------
-- Defaults for creators
------------------------------------------------------------
Config.Defaults = {
    blip = {
        sprite = 1,
        colour = 0,
        scale = 0.85,
        shortRange = true,
        display = 4,
    },
    marker = {
        type = 1,
        size = { x = 1.0, y = 1.0, z = 0.6 },
        color = { r = 66, g = 135, b = 245, a = 140 },
        bobUpAndDown = false,
        faceCamera = false,
        rotate = false,
    },
    ped = {
        model = 'a_m_y_business_01',
        scenario = 'WORLD_HUMAN_CLIPBOARD',
    },
}

------------------------------------------------------------
-- Logging
------------------------------------------------------------
Config.Logs = {
    console = true,
    database = true,
    discord = false,
    webhooks = {
        admin = '',
        shops = '',
        vehicles = '',
        farms = '',
        jobs = '',
        gangs = '',
        apartments = '',
        robberies = '',
    },
}

------------------------------------------------------------
-- Auto-save (NUI drafts)
------------------------------------------------------------
Config.AutoSave = {
    enabled = true,
    intervalMs = 30000,
}

------------------------------------------------------------
-- Currency labels (UI)
------------------------------------------------------------
Config.Currencies = {
    money = 'cash',
    bank = 'bank',
    black_money = 'black_money',
}

------------------------------------------------------------
-- Robbery police defaults
------------------------------------------------------------
Config.Robbery = {
    defaultPoliceJobs = { 'police', 'sheriff' },
    defaultMinPolice = 2,
}

------------------------------------------------------------
-- Apartment routing buckets
------------------------------------------------------------
Config.Apartments = {
    bucketBase = 5000,
    bucketRange = 20000,
}
