Config = Config or {}

-- =============================================================================
-- ENTREPRISE
-- =============================================================================

Config.Company = {
    name = 'San Andreas Taxi Corporation',
    shortName = 'SA Taxi',
    job = 'taxi',
    headquarters = 'Grapeseed',
    logo = 'assets/logo.png',
    slogan = 'Los Santos a fermé ses portes. Les taxis, eux, ont simplement changé de point de départ.',
}

--- Entreprise publique sous tutelle de l'État (true) ou privée (false).
--- Ne pas coder en dur la logique métier : utiliser cette valeur partout.
Config.CompanyStateOwned = true

-- =============================================================================
-- UNITÉS & LOCALISATION
-- =============================================================================

Config.Units = {
    distance = 'km', -- 'km' | 'mi'
    locale = 'fr',
}

-- =============================================================================
-- GRADES & PERMISSIONS
-- =============================================================================

Config.Grades = {
    [0] = {
        label = 'Chauffeur stagiaire',
        payment = 50,
        isBoss = false,
        permissions = {
            dispatch = true,
            garage = true,
            meter = true,
            billing = false,
            bossMenu = false,
            hire = false,
            fire = false,
            promote = false,
            demote = false,
            manageSalaries = false,
            manageVehicles = false,
            manageStock = false,
            viewStats = false,
            viewRevenue = false,
        },
    },
    [1] = {
        label = 'Chauffeur',
        payment = 75,
        isBoss = false,
        permissions = {
            dispatch = true,
            garage = true,
            meter = true,
            billing = true,
            bossMenu = false,
            hire = false,
            fire = false,
            promote = false,
            demote = false,
            manageSalaries = false,
            manageVehicles = false,
            manageStock = false,
            viewStats = false,
            viewRevenue = false,
        },
    },
    [2] = {
        label = 'Chauffeur confirmé',
        payment = 100,
        isBoss = false,
        permissions = {
            dispatch = true,
            garage = true,
            meter = true,
            billing = true,
            bossMenu = false,
            hire = false,
            fire = false,
            promote = false,
            demote = false,
            manageSalaries = false,
            manageVehicles = false,
            manageStock = false,
            viewStats = true,
            viewRevenue = false,
        },
    },
    [3] = {
        label = 'Chauffeur senior',
        payment = 125,
        isBoss = false,
        permissions = {
            dispatch = true,
            garage = true,
            meter = true,
            billing = true,
            bossMenu = false,
            hire = false,
            fire = false,
            promote = false,
            demote = false,
            manageSalaries = false,
            manageVehicles = false,
            manageStock = false,
            viewStats = true,
            viewRevenue = false,
        },
    },
    [4] = {
        label = 'Responsable Taxi',
        payment = 175,
        isBoss = true,
        permissions = {
            dispatch = true,
            garage = true,
            meter = true,
            billing = true,
            bossMenu = true,
            hire = true,
            fire = true,
            promote = true,
            demote = true,
            manageSalaries = true,
            manageVehicles = true,
            manageStock = true,
            viewStats = true,
            viewRevenue = true,
        },
    },
    [5] = {
        label = 'Directeur',
        payment = 250,
        isBoss = true,
        permissions = {
            dispatch = true,
            garage = true,
            meter = true,
            billing = true,
            bossMenu = true,
            hire = true,
            fire = true,
            promote = true,
            demote = true,
            manageSalaries = true,
            manageVehicles = true,
            manageStock = true,
            viewStats = true,
            viewRevenue = true,
        },
    },
}

Config.Permissions = {
    minimumBossGrade = 4,
    minimumDispatchGrade = 0,
    minimumGarageGrade = 0,
    minimumBillingGrade = 1,
}

-- =============================================================================
-- VÉHICULES
-- =============================================================================

Config.Vehicles = {
    {
        model = 'taxi',
        label = 'Vapid Taxi',
        grade = 0,
        category = 'standard',
        livery = 0,
    },
    {
        model = 'taxi',
        label = 'Vapid Taxi Premium',
        grade = 2,
        category = 'premium',
        livery = 1,
    },
    {
        model = 'stretch',
        label = 'Albany Stretch',
        grade = 3,
        category = 'premium',
        livery = 0,
    },
    {
        model = 'baller',
        label = 'Véhicule superviseur',
        grade = 4,
        category = 'supervisor',
        livery = 0,
    },
    {
        model = 'speedo',
        label = 'Véhicule de service',
        grade = 4,
        category = 'service',
        livery = 0,
    },
}

Config.VehicleSettings = {
    spawnInside = true,
    warpIntoVehicle = true,
    giveKeys = true,
    setFuelOnSpawn = true,
    defaultFuel = 100.0,
    fuelResource = 'ox_fuel', -- ignoré si la ressource n'est pas démarrée
    lockOnSpawn = false,
    platePrefix = 'SATAXI',
    deleteOnStore = true,
    repairCost = 250,
    repairUsesCompanyAccount = true,
}

-- =============================================================================
-- POSITIONS — GRAPESEED
-- =============================================================================

Config.Locations = {
    headquarters = {
        label = 'Siège SA Taxi — Grapeseed',
        coords = vec4(1698.42, 4923.01, 42.08, 326.0),
        radius = 2.5,
    },
    duty = {
        label = 'Prise de service',
        coords = vec4(1695.88, 4925.74, 42.08, 145.0),
        radius = 1.5,
        useGlobalDuty = true, -- qbx-duty (Étape 3)
    },
    garage = {
        label = 'Garage Taxi',
        coords = vec4(1703.15, 4918.62, 42.08, 55.0),
        spawn = vec4(1708.42, 4912.35, 42.08, 55.0),
        store = vec3(1703.15, 4918.62, 42.08),
        radius = 3.0,
        storeRadius = 5.0,
    },
    locker = {
        label = 'Vestiaire Taxi',
        coords = vec4(1692.35, 4927.18, 42.08, 235.0),
        radius = 1.5,
    },
    boss = {
        label = 'Bureau direction',
        coords = vec4(1689.74, 4929.55, 42.08, 235.0),
        radius = 1.5,
        minimumGrade = 4,
    },
    tablet = {
        label = 'Tablette chauffeur',
        useItem = false,
        item = 'taxi_tablet',
        command = 'taxitablet',
        keybind = false,
        defaultKey = 'F6',
    },
}

-- Siège historique Los Santos (fermé — lore / futur)
Config.ClosedLocations = {
    losSantosHQ = {
        label = 'Ancien siège — Los Santos (fermé)',
        coords = vec3(-1246.91, -277.53, 37.71),
        blip = {
            enabled = false,
            sprite = 198,
            color = 1,
            scale = 0.7,
        },
    },
}

-- =============================================================================
-- BLIPS
-- =============================================================================

Config.Blips = {
    headquarters = {
        enabled = true,
        sprite = 198,
        color = 5,
        scale = 0.85,
        shortRange = true,
        label = 'San Andreas Taxi Corporation',
    },
    garage = {
        enabled = true,
        sprite = 357,
        color = 5,
        scale = 0.75,
        shortRange = true,
        label = 'Garage SA Taxi',
    },
    driver = {
        managedByDutySystem = true, -- qbx-duty gère les blips chauffeurs
        resource = 'qbx-duty',
    },
}

-- =============================================================================
-- COULEURS NUI
-- =============================================================================

Config.Colors = {
    primary = '#FFC700',
    primaryDark = '#E6B300',
    secondary = '#111111',
    background = '#0A0A0A',
    surface = '#151515',
    surfaceAlt = '#1E1E1E',
    text = '#FFFFFF',
    textMuted = '#B3B3B3',
    success = '#2ECC71',
    danger = '#E74C3C',
    warning = '#F1C40F',
    info = '#3498DB',
}

-- =============================================================================
-- TARIFICATION
-- =============================================================================

Config.Fares = {
    categories = {
        standard = {
            label = 'Standard',
            base = 25,
            perKm = 15,
            perMinute = 2,
            minimumFare = 50,
            multiplier = 1.0,
        },
        premium = {
            label = 'Premium',
            base = 40,
            perKm = 22,
            perMinute = 3,
            minimumFare = 75,
            multiplier = 1.35,
        },
        longDistance = {
            label = 'Longue distance',
            base = 50,
            perKm = 12,
            perMinute = 1.5,
            minimumFare = 100,
            multiplier = 0.95,
            minimumDistanceKm = 5.0,
        },
    },
    defaultCategory = 'standard',
    rounding = 5, -- arrondi au multiple de 5
    paymentAccount = 'cash', -- 'cash' | 'bank'
    allowBankFallback = true,
}

-- =============================================================================
-- ÉCONOMIE & COMMISSIONS
-- =============================================================================

Config.Economy = {
    currencySymbol = '$',
    companyAccount = 'taxi',
    useSocietyAccount = true,
    societyResource = 'Renewed-Banking', -- adapté selon le serveur
    driverPayoutMode = 'split', -- 'split' | 'salary_plus_bonus' | 'full_to_driver'
    driverSharePercent = 65,
    companySharePercent = 35,
    invoiceTaxPercent = 0,
    stateOwnedRevenueToTreasury = true,
}

Config.Commissions = {
    ride = {
        company = 35,
        driver = 65,
    },
    invoice = {
        company = 20,
        driver = 80,
    },
    longDistanceBonus = {
        driver = 10,
        company = 0,
    },
}

-- =============================================================================
-- DISPATCH
-- =============================================================================

Config.Dispatch = {
    enabled = true,
    maxActiveRequests = 25,
    requestTimeout = 120, -- secondes
    autoAssign = false,
    showCustomerName = true,
    showEstimatedFare = true,
    refreshInterval = 5000, -- ms (UI uniquement)
    acceptDistanceCheck = true,
    maxAcceptDistance = 15000.0, -- mètres
    notifySound = true,
}

-- =============================================================================
-- DEMANDE CLIENT (/taxi)
-- =============================================================================

Config.ClientRequest = {
    enabled = true,
    command = 'taxi',
    useTarget = false,
    targetModels = {},
    requireOnFoot = false,
    cooldown = 60, -- secondes
    cancelCommand = 'canceltaxi',
    allowComment = true,
    maxCommentLength = 120,
    destinationMode = 'waypoint', -- 'waypoint' | 'preset' | 'free'
    presetDestinations = {
        { label = 'Sandy Shores', coords = vec3(1960.69, 3740.56, 32.34) },
        { label = 'Paleto Bay', coords = vec3(-275.52, 6635.84, 7.42) },
        { label = 'Aéroport LSIA', coords = vec3(-1037.12, -2737.71, 20.17) },
        { label = 'Centre-ville LS', coords = vec3(215.76, -810.12, 30.73) },
    },
}

-- =============================================================================
-- COURSES
-- =============================================================================

Config.Rides = {
    meterUpdateInterval = 1000, -- ms
    pickupRadius = 15.0,
    dropoffRadius = 20.0,
    cancelPenalty = 25,
    noShowTimeout = 180,
    requireVehicleClass = 'automobile',
    allowedVehicleModels = {}, -- vide = véhicules taxi du garage uniquement
    ratingEnabled = true,
    ratingTimeout = 60,
    historyLimit = 50,
}

-- =============================================================================
-- FACTURATION
-- =============================================================================

Config.Billing = {
    enabled = true,
    types = {
        ride = { label = 'Course taxi', enabled = true },
        private = { label = 'Transport privé', enabled = true },
        longDistance = { label = 'Longue distance', enabled = true },
        special = { label = 'Service spécial', enabled = true },
    },
    minAmount = 25,
    maxAmount = 5000,
    requireReason = false,
    maxReasonLength = 160,
}

-- =============================================================================
-- VESTIAIRE
-- =============================================================================

Config.Locker = {
    enabled = true,
    useNativeClothing = true,
    outfits = {
        civil = {
            label = 'Tenue civile',
            restorePlayerSkin = true,
        },
        driver = {
            label = 'Tenue chauffeur',
            grade = 0,
            male = {},
            female = {},
        },
        senior = {
            label = 'Tenue chauffeur senior',
            grade = 3,
            male = {},
            female = {},
        },
        manager = {
            label = 'Tenue responsable',
            grade = 4,
            male = {},
            female = {},
        },
    },
}

-- =============================================================================
-- DUTY (qbx-duty — intégration Étape 3)
-- =============================================================================

Config.Duty = {
    resource = 'qbx-duty',
    useGlobalDuty = true,
    requireDutyFor = {
        dispatch = true,
        garage = true,
        rides = true,
        meter = true,
        billing = true,
        driverBlip = true,
    },
}

-- =============================================================================
-- NOTIFICATIONS
-- =============================================================================

Config.Notifications = {
    provider = 'ox_lib', -- 'ox_lib' | 'qbx_core'
    duration = 5000,
    position = 'top-right',
    messages = {
        onDuty = 'Vous êtes maintenant en service.',
        offDuty = 'Vous avez quitté votre service.',
        notOnDuty = 'Vous devez être en service.',
        notTaxiJob = 'Vous n\'êtes pas employé de la San Andreas Taxi Corporation.',
        newRequest = 'Nouvelle demande de taxi.',
        rideAccepted = 'Course acceptée.',
        clientWaiting = 'Le client vous attend.',
        rideStarted = 'Course démarrée.',
        rideCompleted = 'Course terminée : %s.',
        rideCancelled = 'Course annulée.',
        paymentFailed = 'Paiement refusé : fonds insuffisants.',
        vehicleStored = 'Véhicule rangé.',
        vehicleSpawned = 'Véhicule sorti.',
        insufficientGrade = 'Grade insuffisant.',
        resourceReady = 'SA Taxi initialisé.',
    },
}

-- =============================================================================
-- SONS
-- =============================================================================

Config.Sounds = {
    enabled = true,
    newRequest = {
        name = 'Text_Arrive_Tone',
        ref = 'Phone_SoundSet_Default',
    },
    rideAccepted = {
        name = 'SELECT',
        ref = 'HUD_FRONTEND_DEFAULT_SOUNDSET',
    },
    rideCompleted = {
        name = 'PURCHASE',
        ref = 'HUD_LIQUOR_STORE_SOUNDSET',
    },
}

-- =============================================================================
-- TEMPS & INTERVALLES
-- =============================================================================

Config.Times = {
    startupDelay = 500,
    targetDistance = 2.0,
    garageInteractCooldown = 2000,
    statsRefresh = 30000,
    dutyLogInterval = 60000,
    saveStatsInterval = 120000,
}

-- =============================================================================
-- LOGS DISCORD
-- =============================================================================

Config.DiscordLogs = {
    enabled = false,
    botName = 'SA Taxi Logs',
    avatarUrl = '',
    webhooks = {
        duty = '',
        rides = '',
        billing = '',
        management = '',
        security = '',
    },
    colors = {
        dutyOn = 3066993,
        dutyOff = 15158332,
        rideAccepted = 3447003,
        rideCompleted = 15844367,
        invoice = 10181046,
        payment = 5763719,
        hire = 2067276,
        fire = 15548997,
        promote = 9807270,
        demote = 15105570,
    },
    logEvents = {
        dutyOn = true,
        dutyOff = true,
        rideAccepted = true,
        rideCompleted = true,
        invoice = true,
        payment = true,
        hire = true,
        fire = true,
        promote = true,
        demote = true,
    },
}

-- =============================================================================
-- SQL
-- =============================================================================

Config.SQL = {
    autoRun = true,
    file = 'sql/taxi.sql',
    tables = {
        rides = 'taxi_rides',
        ratings = 'taxi_ratings',
        transactions = 'taxi_transactions',
        dutyLogs = 'taxi_duty_logs',
    },
}

-- =============================================================================
-- SÉCURITÉ
-- =============================================================================

Config.Security = {
    validateDistance = true,
    maxInteractionDistance = 5.0,
    maxRideDistance = 50000.0,
    serverSidePricing = true,
    serverSidePayments = true,
    antiSpam = {
        enabled = true,
        windowMs = 10000,
        maxEvents = 8,
    },
    blockedExploitActions = {
        setFare = true,
        setCommission = true,
        setDistance = true,
        forceComplete = true,
    },
}

-- =============================================================================
-- BOSS MENU
-- =============================================================================

Config.BossMenu = {
    enabled = true,
    minimumGrade = 4,
    useOxLibMenu = true,
    features = {
        employees = true,
        hire = true,
        fire = true,
        promote = true,
        demote = true,
        salaries = true,
        stats = true,
        revenue = true,
        expenses = true,
        vehicles = true,
        stock = false,
    },
}

-- =============================================================================
-- NUI
-- =============================================================================

Config.NUI = {
    focusOnOpen = true,
    closeOnEscape = true,
    tabletCommand = 'taxitablet',
    tabletKey = false,
    animations = true,
    theme = 'sa-taxi-dark',
}

-- =============================================================================
-- OX_TARGET
-- =============================================================================

Config.Target = {
    enabled = true,
    distance = 2.0,
    icon = 'fa-solid fa-taxi',
    groups = {
        taxi = 0,
    },
}

-- =============================================================================
-- DEBUG
-- =============================================================================

Config.Debug = {
    enabled = false,
    drawZones = false,
    printCallbacks = false,
    printPayments = false,
    command = 'taxidebug',
}

