--[[--------------------------------------------------------------------------
    core_garage — Configuration complète
    ESX Legacy 1.12+ | ox_lib | ox_target | oxmysql | OneSync Infinity
---------------------------------------------------------------------------]]

Config = {}

Config.Locale = 'fr'
Config.Debug = false

--[[--------------------------------------------------------------------------
    Général
---------------------------------------------------------------------------]]
Config.General = {
    -- Compte de paiement (fourrière, etc.)
    payAccount = 'bank', -- 'bank' | 'money'
    -- Distance max interactions serveur (anti-cheat)
    maxDistance = 12.0,
    -- Distance ox_target rangement
    storeTargetDistance = 3.5,
    -- Moteur doit être coupé pour ranger
    requireEngineOff = true,
    -- Donner les clés à la sortie (event configurable)
    giveKeys = true,
    keysExport = nil, -- ex: 'wasabi_carlock' | nil = event générique
    keysEvent = 'core_garage:client:giveKeys',
    -- Statebag propriétaire
    ownerStatebag = 'garageOwner',
    plateStatebag = 'garagePlate',
    -- Sync owned_vehicles ESX (optionnel, miroir)
    syncOwnedVehicles = true,
    ownedVehiclesTable = 'owned_vehicles',
    -- Kilométrage
    mileageEnabled = true,
    mileageInterval = 5000, -- ms tick quand conduit
    -- Véhicule détruit → fourrière auto
    autoImpoundOnDestroy = true,
    destroyHealthThreshold = 50.0,
    -- Image véhicule NUI (docs.fivem / local)
    vehicleImageUrl = 'https://docs.fivem.net/vehicles/%s.webp',
}

--[[--------------------------------------------------------------------------
    Progress bars (ox_lib)
---------------------------------------------------------------------------]]
Config.Progress = {
    takeOut = {
        duration = 3500,
        label = nil, -- locales
        anim = { dict = 'anim@mp_player_intmenu@key_fob@', clip = 'fob_click' },
        disable = { move = true, car = true, combat = true },
    },
    store = {
        duration = 4000,
        label = nil,
        anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
        disable = { move = true, car = true, combat = true },
    },
    impound = {
        duration = 4500,
        label = nil,
        anim = { dict = 'mp_common', clip = 'givetake1_a' },
        disable = { move = true, car = true, combat = true },
    },
    gate = {
        duration = 2000,
        label = nil,
        anim = nil,
        disable = { move = true, car = true, combat = true },
    },
}

--[[--------------------------------------------------------------------------
    Animations portail (sortie)
---------------------------------------------------------------------------]]
Config.Gate = {
    enabled = true,
    -- Scenario optionnel à la place de l'anim progress
    useScenario = false,
    scenario = 'WORLD_HUMAN_CLIPBOARD',
}

--[[--------------------------------------------------------------------------
    Blips par défaut selon type
---------------------------------------------------------------------------]]
Config.DefaultBlips = {
    public      = { sprite = 357, color = 3,  scale = 0.75, display = 4, shortRange = true },
    personal    = { sprite = 357, color = 2,  scale = 0.70, display = 4, shortRange = true },
    company     = { sprite = 357, color = 5,  scale = 0.75, display = 4, shortRange = true },
    job         = { sprite = 357, color = 46, scale = 0.75, display = 4, shortRange = true },
    impound     = { sprite = 67,  color = 1,  scale = 0.80, display = 4, shortRange = true },
    boat        = { sprite = 410, color = 3,  scale = 0.75, display = 4, shortRange = true },
    plane       = { sprite = 423, color = 3,  scale = 0.75, display = 4, shortRange = true },
    helicopter  = { sprite = 43,  color = 3,  scale = 0.75, display = 4, shortRange = true },
}

--[[--------------------------------------------------------------------------
    Markers par défaut
---------------------------------------------------------------------------]]
Config.DefaultMarkers = {
    type = 36,
    size = vec3(0.8, 0.8, 0.8),
    color = { r = 56, g = 189, b = 248, a = 180 },
    bobUpAndDown = false,
    faceCamera = true,
    rotate = true,
    drawDistance = 18.0,
    interactDistance = 2.0,
}

--[[--------------------------------------------------------------------------
    Fourrière
---------------------------------------------------------------------------]]
Config.Impound = {
    defaultPrice = 1500,
    defaultTimeMinutes = 0, -- délai avant récupération possible
    notifyOwner = true,
    -- Réduction assurance (%)
    insuranceDiscount = 50,
    -- Types de garage fourrière autorisés pour récupération
    garageType = 'impound',
}

--[[--------------------------------------------------------------------------
    Entreprises
---------------------------------------------------------------------------]]
Config.Company = {
    -- Historique max affiché
    maxLogs = 50,
    -- Logs serveur (console)
    consoleLog = false,
}

--[[--------------------------------------------------------------------------
    Admin
---------------------------------------------------------------------------]]
Config.Admin = {
    command = 'garageadmin',
    -- Groupes ESX autorisés
    groups = { 'admin', 'superadmin', 'god' },
    -- ACE permission alternative
    acePermission = 'core_garage.admin',
}

--[[--------------------------------------------------------------------------
    Catégories véhicules (tri NUI)
---------------------------------------------------------------------------]]
Config.Categories = {
    compact = 'Compact',
    sedan = 'Berline',
    suv = 'SUV',
    coupe = 'Coupé',
    muscle = 'Muscle',
    sports = 'Sport',
    super = 'Super',
    motorcycle = 'Moto',
    offroad = 'Tout-terrain',
    industrial = 'Industriel',
    utility = 'Utilitaire',
    van = 'Van',
    service = 'Service',
    emergency = 'Urgence',
    military = 'Militaire',
    commercial = 'Commercial',
    boat = 'Bateau',
    heli = 'Hélicoptère',
    plane = 'Avion',
    other = 'Autre',
}

--[[--------------------------------------------------------------------------
    Mapping type garage → type véhicule ESX
---------------------------------------------------------------------------]]
Config.GarageVehicleTypes = {
    public     = 'car',
    personal   = 'car',
    company    = 'car',
    job        = 'car',
    impound    = 'car',
    boat       = 'boat',
    plane      = 'plane',
    helicopter = 'heli',
}

--[[--------------------------------------------------------------------------
    Jobs / gangs (exemples — utilisés si garage.job / garage.gang défini)
---------------------------------------------------------------------------]]
Config.Jobs = {
    -- ['police'] = true,
}

Config.Gangs = {
    -- Si vous utilisez un script gang avec player.gang
    -- ['ballas'] = true,
}

--[[--------------------------------------------------------------------------
    Notifications (ox_lib)
---------------------------------------------------------------------------]]
Config.Notify = {
    position = 'top-right',
    duration = 5000,
}

--[[--------------------------------------------------------------------------
    Couleurs NUI (CSS variables injectées)
---------------------------------------------------------------------------]]
Config.UI = {
    accent = '#38bdf8',
    accentSoft = 'rgba(56, 189, 248, 0.15)',
    bg = '#0b1220',
    panel = '#121a2b',
    text = '#e8eef7',
    muted = '#8b9bb4',
    success = '#34d399',
    warning = '#fbbf24',
    danger = '#f87171',
    radius = '14px',
}

--[[--------------------------------------------------------------------------
    Garages par défaut (chargés si table SQL vide)
    Types: public | personal | company | job | impound | boat | plane | helicopter
---------------------------------------------------------------------------]]
Config.DefaultGarages = {
    {
        name = 'legion_public',
        label = 'Garage Légion Square',
        type = 'public',
        coords = vec3(215.12, -809.78, 30.73),
        spawn = vec4(222.20, -801.70, 30.65, 250.0),
        store = vec3(214.50, -793.80, 30.80),
        blip = { enabled = true },
        marker = { enabled = true },
        job = nil,
        gang = nil,
        minGrade = 0,
        vehicleType = 'car',
        enabled = true,
    },
    {
        name = 'pillbox_public',
        label = 'Garage Pillbox',
        type = 'public',
        coords = vec3(273.0, -343.85, 44.92),
        spawn = vec4(270.75, -340.50, 44.92, 160.0),
        store = vec3(276.50, -339.80, 44.92),
        blip = { enabled = true },
        marker = { enabled = true },
        vehicleType = 'car',
        enabled = true,
    },
    {
        name = 'impound_public',
        label = 'Fourrière Centrale',
        type = 'impound',
        coords = vec3(409.15, -1623.05, 29.29),
        spawn = vec4(401.70, -1631.90, 29.29, 230.0),
        store = vec3(409.15, -1623.05, 29.29),
        blip = { enabled = true },
        marker = { enabled = true },
        vehicleType = 'car',
        impoundPrice = 1500,
        impoundTime = 0,
        enabled = true,
    },
    {
        name = 'boat_la_puerta',
        label = 'Port La Puerta',
        type = 'boat',
        coords = vec3(-795.15, -1510.85, 1.60),
        spawn = vec4(-800.50, -1505.20, -0.45, 110.0),
        store = vec3(-795.15, -1510.85, 1.60),
        blip = { enabled = true },
        marker = { enabled = true },
        vehicleType = 'boat',
        enabled = true,
    },
    {
        name = 'heli_hospital',
        label = 'Héliport Pillbox',
        type = 'helicopter',
        coords = vec3(351.85, -588.10, 74.15),
        spawn = vec4(351.85, -588.10, 74.15, 250.0),
        store = vec3(351.85, -588.10, 74.15),
        blip = { enabled = true },
        marker = { enabled = true },
        vehicleType = 'heli',
        job = 'ambulance',
        minGrade = 0,
        enabled = true,
    },
    {
        name = 'plane_lsia',
        label = 'Hangar LSIA',
        type = 'plane',
        coords = vec3(-1650.20, -3140.50, 13.99),
        spawn = vec4(-1645.0, -3130.0, 13.99, 330.0),
        store = vec3(-1650.20, -3140.50, 13.99),
        blip = { enabled = true },
        marker = { enabled = true },
        vehicleType = 'plane',
        enabled = true,
    },
    {
        name = 'police_job',
        label = 'Garage Police',
        type = 'job',
        coords = vec3(457.50, -1017.30, 28.35),
        spawn = vec4(446.70, -1025.50, 28.55, 5.0),
        store = vec3(452.50, -1017.80, 28.45),
        blip = { enabled = true },
        marker = { enabled = true },
        job = 'police',
        minGrade = 0,
        vehicleType = 'car',
        enabled = true,
    },
    {
        name = 'mechanic_company',
        label = 'Garage Benny\'s',
        type = 'company',
        coords = vec3(-192.80, -1290.50, 31.30),
        spawn = vec4(-185.50, -1290.20, 31.30, 270.0),
        store = vec3(-192.80, -1290.50, 31.30),
        blip = { enabled = true },
        marker = { enabled = true },
        job = 'mechanic',
        minGrade = 0,
        vehicleType = 'car',
        enabled = true,
    },
}

--[[--------------------------------------------------------------------------
    Entreprises par défaut (si table vide)
---------------------------------------------------------------------------]]
Config.DefaultCompanies = {
    {
        job = 'mechanic',
        garage = 'mechanic_company',
        label = 'Benny\'s Shared Fleet',
        minGradeOut = 0,
        minGradeStore = 0,
        minGradeManage = 2,
        maxOut = 5,
        shared = true,
    },
    {
        job = 'police',
        garage = 'police_job',
        label = 'LSPD Fleet',
        minGradeOut = 0,
        minGradeStore = 0,
        minGradeManage = 3,
        maxOut = 10,
        shared = true,
    },
}
