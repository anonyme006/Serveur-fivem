Config = Config or {}

-- =============================================================================
-- 1. ENTREPRISE
-- =============================================================================

Config.Company = {
    name = 'San Andreas Taxi Corporation',
    shortName = 'SA Taxi',
    job = 'taxi',
    headquarters = 'Grapeseed',
    formerHeadquarters = 'Los Santos',
    logo = 'web/assets/logo.png',
    slogan = 'Los Santos a fermé ses portes. Les taxis, eux, ont simplement changé de point de départ.',
}

--- Entreprise sous tutelle de l'État (true) ou privée (false).
--- Ne pas coder en dur : lire cette valeur partout.
Config.CompanyStateOwned = true

-- =============================================================================
-- 2. MENU PRINCIPAL (MenuV)
-- =============================================================================

Config.Menu = {
    command = 'taximenu',
    key = 'F6',
    enabled = true,
    position = 'topleft',
    requireJob = true,
    requireAlive = true,
    openCooldown = 500, -- ms anti-spam
}

--- Paramètres visuels MenuV (CreateMenu)
--- API : MenuV:CreateMenu(title, subtitle, position, r, g, b, ...)
Config.MenuV = {
    title = 'San Andreas Taxi Corporation',
    subtitle = 'Service de transport de San Andreas',
    position = 'topleft',
    color = {
        r = 255,
        g = 200,
        b = 0,
    },
    namespace = 'qbx_taxi',
    theme = 'default',
    dictionary = 'menuv',
    texture = 'default',
    size = 'size-125',
    --- Logo : MenuV supporte texture/dictionary si configuré côté MenuV.
    --- Sinon le logo reste disponible via Config.Company.logo pour interfaces complémentaires.
    useLogoTexture = false,
    logoDictionary = 'qbx_taxi',
    logoTexture = 'logo',
}

-- =============================================================================
-- 3. GRADES
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
            employees = false,
            hire = false,
            fire = false,
            promote = false,
            demote = false,
            manageSalaries = false,
            manageVehicles = false,
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
            employees = false,
            hire = false,
            fire = false,
            promote = false,
            demote = false,
            manageSalaries = false,
            manageVehicles = false,
            viewStats = true,
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
            employees = false,
            hire = false,
            fire = false,
            promote = false,
            demote = false,
            manageSalaries = false,
            manageVehicles = false,
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
            employees = false,
            hire = false,
            fire = false,
            promote = false,
            demote = false,
            manageSalaries = false,
            manageVehicles = false,
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
            employees = true,
            hire = true,
            fire = true,
            promote = true,
            demote = true,
            manageSalaries = true,
            manageVehicles = true,
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
            employees = true,
            hire = true,
            fire = true,
            promote = true,
            demote = true,
            manageSalaries = true,
            manageVehicles = true,
            viewStats = true,
            viewRevenue = true,
        },
    },
}

-- =============================================================================
-- 4. VÉHICULES
-- =============================================================================

Config.Vehicles = {
    {
        model = 'taxi',
        label = 'Vapid Taxi',
        minGrade = 0,
        category = 'standard',
        livery = 0,
    },
    {
        model = 'taxi',
        label = 'Taxi Premium',
        minGrade = 2,
        category = 'premium',
        livery = 1,
    },
    {
        model = 'speedo',
        label = 'Taxi Van',
        minGrade = 2,
        category = 'van',
        livery = 0,
    },
    {
        model = 'baller',
        label = 'Véhicule Responsable',
        minGrade = 4,
        category = 'supervisor',
        livery = 0,
    },
}

Config.VehicleSettings = {
    spawnInside = true,
    warpIntoVehicle = true,
    giveKeys = true,
    setFuelOnSpawn = true,
    defaultFuel = 100.0,
    fuelResource = 'ox_fuel',
    platePrefix = 'TAXI',
    deleteOnStore = true,
    repairCost = 250,
    cleanCost = 50,
    refuelCost = 100,
    allowedModels = {}, -- vide = Config.Vehicles uniquement
    lockDistance = 5.0,
    storeDistance = 8.0,
}

-- =============================================================================
-- 5. GARAGE
-- =============================================================================

Config.Garage = {
    enabled = true,
    label = 'Garage SA Taxi',
    coords = vec4(1703.15, 4918.62, 42.08, 55.0),
    spawn = vec4(1708.42, 4912.35, 42.08, 55.0),
    store = vec3(1703.15, 4918.62, 42.08),
    interactRadius = 3.0,
    storeRadius = 5.0,
    requireDuty = true,
    requireJob = true,
    confirmSpawn = true,
    maxActiveVehicles = 1,
}

-- =============================================================================
-- 6. POSITIONS GÉNÉRALES
-- =============================================================================

Config.Locations = {
    headquarters = {
        label = 'Siège SA Taxi — Grapeseed',
        coords = vec4(1698.42, 4923.01, 42.08, 326.0),
        radius = 2.5,
    },
    duty = {
        label = 'Point de service',
        coords = vec4(1695.88, 4925.74, 42.08, 145.0),
        radius = 1.5,
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
    companyStash = {
        label = 'Coffre entreprise',
        coords = vec4(1690.50, 4926.80, 42.08, 235.0),
        radius = 1.5,
        minimumGrade = 4,
        stashId = 'sataxi_stash',
        slots = 50,
        weight = 100000,
    },
}

Config.ClosedLocations = {
    losSantosHQ = {
        label = 'Ancien siège — Los Santos (fermé)',
        coords = vec3(-1246.91, -277.53, 37.71),
        blip = { enabled = false, sprite = 198, color = 1, scale = 0.7 },
    },
}

-- =============================================================================
-- 7. DUTY (qbx-duty — intégration Étape 7)
-- =============================================================================

Config.Duty = {
    resource = 'qbx-duty',
    useGlobalDuty = true,
    exportIsOnDuty = 'IsOnDuty',
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
-- 8. TARIFICATION
-- =============================================================================

Config.Fares = {
    base = 25,
    perKm = 15,
    perMinute = 2,
    minimum = 50,
    rounding = 5,
    paymentAccount = 'cash', -- 'cash' | 'bank'
    allowBankFallback = true,
    driverSharePercent = 65,
    companySharePercent = 35,
}

-- =============================================================================
-- 9. DISPATCH
-- =============================================================================

Config.Dispatch = {
    enabled = true,
    maxActiveRequests = 25,
    requestTimeout = 120,
    autoAssign = false,
    showCustomerName = true,
    showEstimatedFare = true,
    acceptDistanceCheck = true,
    maxAcceptDistance = 15000.0,
    refreshInterval = 5000,
    notifySound = true,
}

-- =============================================================================
-- 10. DEMANDE CLIENT (/taxi)
-- =============================================================================

Config.ClientRequest = {
    enabled = true,
    command = 'taxi',
    cancelCommand = 'canceltaxi',
    cooldown = 60,
    allowComment = true,
    maxCommentLength = 120,
    destinationMode = 'waypoint', -- 'waypoint' | 'preset'
    presetDestinations = {
        { label = 'Sandy Shores', coords = vec3(1960.69, 3740.56, 32.34) },
        { label = 'Paleto Bay', coords = vec3(-275.52, 6635.84, 7.42) },
        { label = 'Aéroport LSIA', coords = vec3(-1037.12, -2737.71, 20.17) },
        { label = 'Centre-ville LS', coords = vec3(215.76, -810.12, 30.73) },
    },
}

-- =============================================================================
-- 11. STATUTS DE COURSE
-- =============================================================================

Config.RideStatuses = {
    WAITING = 'WAITING',
    DRIVER_ASSIGNED = 'DRIVER_ASSIGNED',
    DRIVER_ARRIVED = 'DRIVER_ARRIVED',
    PASSENGER_ON_BOARD = 'PASSENGER_ON_BOARD',
    RIDE_ACTIVE = 'RIDE_ACTIVE',
    COMPLETED = 'COMPLETED',
    CANCELLED = 'CANCELLED',
}

Config.Rides = {
    meterUpdateInterval = 1000,
    pickupRadius = 15.0,
    dropoffRadius = 20.0,
    cancelPenalty = 25,
    noShowTimeout = 180,
    ratingEnabled = true,
    ratingTimeout = 60,
    historyLimit = 50,
}

-- =============================================================================
-- 12. BLIPS
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
        managedByDutySystem = true,
        resource = 'qbx-duty',
    },
}

-- =============================================================================
-- 13. VESTIAIRE
-- =============================================================================

Config.Vestiaire = {
    enabled = true,
    useNativeClothing = true,
    outfits = {
        civil = {
            label = 'Civil',
            restorePlayerSkin = true,
        },
        driver = {
            label = 'Chauffeur',
            minGrade = 0,
            male = {},
            female = {},
        },
        senior = {
            label = 'Chauffeur senior',
            minGrade = 3,
            male = {},
            female = {},
        },
        manager = {
            label = 'Responsable',
            minGrade = 4,
            male = {},
            female = {},
        },
        director = {
            label = 'Directeur',
            minGrade = 5,
            male = {},
            female = {},
        },
    },
}

-- =============================================================================
-- 14. BOSS / GESTION ENTREPRISE
-- =============================================================================

Config.Boss = {
    enabled = true,
    minimumGrade = 4,
    companyAccount = 'taxi',
    features = {
        employees = true,
        vehicles = true,
        account = true,
        stats = true,
        salaries = true,
        history = true,
        companyInfo = true,
    },
}

-- =============================================================================
-- 15. FACTURATION
-- =============================================================================

Config.Billing = {
    enabled = true,
    minAmount = 25,
    maxAmount = 5000,
    maxDistance = 10.0,
    requireDuty = true,
    requireReason = false,
    maxReasonLength = 160,
    services = {
        ride = { label = 'Course taxi', enabled = true },
        private = { label = 'Transport privé', enabled = true },
        longDistance = { label = 'Longue distance', enabled = true },
        special = { label = 'Service spécial', enabled = true },
    },
}

-- =============================================================================
-- 16. OX_TARGET
-- =============================================================================

Config.Target = {
    enabled = true,
    distance = 2.0,
    icon = 'fa-solid fa-taxi',
    options = {
        duty = true,
        garage = true,
        vehicleMenu = true,
        locker = true,
        companyStash = true,
    },
}

-- =============================================================================
-- 17. NOTIFICATIONS
-- =============================================================================

Config.Notifications = {
    provider = 'ox_lib',
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
        clientArrived = 'Client arrivé.',
        rideStarted = 'Course démarrée.',
        rideCompleted = 'Course terminée : %s.',
        rideCancelled = 'Course annulée.',
        paymentFailed = 'Paiement refusé : fonds insuffisants.',
        vehicleStored = 'Véhicule rangé.',
        vehicleSpawned = 'Véhicule sorti.',
        insufficientGrade = 'Grade insuffisant.',
        menuDenied = 'Accès refusé.',
    },
}

-- =============================================================================
-- 18. WEBHOOKS DISCORD
-- =============================================================================

Config.Webhooks = {
    enabled = false,
    botName = 'SA Taxi Logs',
    avatarUrl = '',
    urls = {
        duty = '',
        rides = '',
        billing = '',
        management = '',
        vehicles = '',
        security = '',
    },
    colors = {
        dutyOn = 3066993,
        dutyOff = 15158332,
        rideAccepted = 3447003,
        clientPickedUp = 10181046,
        rideCompleted = 15844367,
        payment = 5763719,
        invoice = 10181046,
        hire = 2067276,
        fire = 15548997,
        promote = 9807270,
        demote = 15105570,
        vehicleSpawn = 16776960,
    },
    events = {
        dutyOn = true,
        dutyOff = true,
        rideAccepted = true,
        clientPickedUp = true,
        rideCompleted = true,
        payment = true,
        invoice = true,
        hire = true,
        fire = true,
        promote = true,
        demote = true,
        vehicleSpawn = true,
    },
}

-- =============================================================================
-- 19. SQL
-- =============================================================================

Config.SQL = {
    autoRun = true,
    file = 'sql/taxi.sql',
    tables = {
        rides = 'taxi_rides',
        ratings = 'taxi_ratings',
        transactions = 'taxi_transactions',
        dutyLogs = 'taxi_duty_logs',
        employeeStats = 'taxi_employee_stats',
    },
}

-- =============================================================================
-- 20. SÉCURITÉ
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
}

-- =============================================================================
-- 21. UNITÉS & DEBUG
-- =============================================================================

Config.Units = {
    distance = 'km',
    locale = 'fr',
}

Config.Debug = {
    enabled = false,
    drawZones = false,
    printCallbacks = false,
    printPayments = false,
    command = 'taxidebug',
}

-- =============================================================================
-- VALIDATION AU CHARGEMENT
-- =============================================================================

local function validateConfig()
    assert(Config.Company.job == 'taxi', '[qbx-taxi] Config.Company.job doit être "taxi"')
    assert(Config.Grades[0], '[qbx-taxi] Config.Grades[0] est requis')
    assert(Config.Menu.command ~= '', '[qbx-taxi] Config.Menu.command est requis')
    assert(Config.Fares.companySharePercent + Config.Fares.driverSharePercent == 100,
        '[qbx-taxi] Config.Fares : companySharePercent + driverSharePercent doit totaliser 100')

    for index, vehicle in ipairs(Config.Vehicles) do
        assert(vehicle.model, ('[qbx-taxi] Config.Vehicles[%s].model manquant'):format(index))
        assert(vehicle.minGrade ~= nil, ('[qbx-taxi] Config.Vehicles[%s].minGrade manquant'):format(index))
    end

    if Config.Debug.enabled then
        print(('[qbx-taxi] Configuration chargée : %s'):format(Config.Company.name))
    end
end

validateConfig()
