Config = {}

--[[
    Sky Driving School — Master configuration
    Adapt schools, routes and prices without touching core scripts.
]]

Config.Locale = 'en' -- 'en' | 'fr'
Config.Debug = false

-- Framework: 'auto' | 'qbox' | 'qbcore' | 'esx'
Config.Framework = 'auto'

-- License backend: 'auto' | 'qbox' | 'qbcore' | 'esx_license' | 'qbx_licenses' | 'custom'
Config.LicenseSystem = 'auto'

-- Inventory: 'ox_inventory' | 'none'
Config.Inventory = 'ox_inventory'

-- Interaction: 'ox_target' | 'marker' | 'both'
Config.Interaction = 'both'

Config.TargetDistance = 2.5
Config.MarkerDrawDistance = 25.0
Config.MarkerInteractDistance = 2.0

-- Payment: prefer bank, allow cash fallback
Config.Payment = {
    allowBank = true,
    allowCash = true,
    preferBank = true,
    societyAccount = nil, -- e.g. 'drivingschool' if Renewed-Banking / qb-management present
}

-- Anti-cheat / rate limits
Config.AntiCheat = {
    eventCooldownMs = 750,
    maxEventsPerMinute = 60,
    zoneGraceMeters = 35.0,
    disconnectFailExam = true,
    deathFailExam = true,
    vehicleSwapFailExam = true,
    logSuspicious = true,
}

-- Retake delay after failure (seconds). 0 = immediate.
Config.RetakeDelay = {
    theory = 300,
    practical = 600,
}

-- Require theory before practical
Config.RequireTheoryBeforePractical = true

-- Give ox_inventory item on license grant
Config.GiveLicenseItem = true

-- Show NUI license card after grant
Config.ShowCardOnGrant = true

--------------------------------------------------------------------
-- Admin / instructor / police permissions
--------------------------------------------------------------------
Config.AdminAce = 'sky_drivingschool.admin'

Config.InstructorJobs = {
    drivingschool = 0,
    dmv = 0,
}

Config.PoliceJobs = {
    police = 0,
    sheriff = 0,
    highway = 0,
}

Config.RequireOnDuty = true
Config.AdminMinGrade = {
    viewCandidates = 0,
    viewStats = 0,
    cancelExam = 1,
    editPrices = 2,
    revokeLicense = 2,
    managePoints = 0,
    restoreLicense = 2,
    viewLogs = 1,
}

--------------------------------------------------------------------
-- Points system (per category)
--------------------------------------------------------------------
Config.Points = {
    enabled = true,
    defaultMax = 12,
    suspendAt = 0,          -- status becomes suspended when points <= this
    revokeAtZero = true,    -- fully revoke when points hit 0
    recovery = {
        enabled = true,
        pointsPerPeriod = 1,
        periodHours = 168,  -- weekly recovery of 1 point (admin can also restore)
        requireAdminForManual = true,
    },
    infractions = {
        speeding = { label = 'Speeding', points = 2, categories = { 'class_c', 'class_m', 'class_a', 'cdl', 'boat' } },
        reckless = { label = 'Reckless driving', points = 4, categories = { 'class_c', 'class_m', 'class_a', 'cdl', 'boat', 'pilot' } },
        no_license = { label = 'Driving without valid license', points = 6, categories = { 'class_c', 'class_m', 'class_a', 'cdl', 'boat', 'pilot' } },
        collision_hitrun = { label = 'Collision / hit and run', points = 5, categories = { 'class_c', 'class_m', 'class_a', 'cdl', 'boat' } },
        red_light = { label = 'Running a red light', points = 3, categories = { 'class_c', 'class_m', 'class_a', 'cdl' } },
        commercial = { label = 'Commercial vehicle violation', points = 4, categories = { 'class_a', 'cdl' } },
        airspace = { label = 'Airspace / flight violation', points = 5, categories = { 'pilot' } },
        maritime = { label = 'Maritime safety violation', points = 3, categories = { 'boat' } },
    },
}

--------------------------------------------------------------------
-- License categories
--------------------------------------------------------------------
Config.Categories = {
    class_c = {
        enabled = true,
        label = 'Class C — Car',
        short = 'Class C',
        icon = 'car',
        description = 'Standard passenger vehicle license for cars and light trucks.',
        licenseKey = 'driver',          -- metadata.licences key (Qbox default)
        qbxLicensesKey = 'driver',      -- qbx_licenses type if present
        esxLicense = 'drive',
        item = 'driver_license',
        maxPoints = 12,
        theoryPrice = 150,
        practicalPrice = 350,
        theoryQuestions = 15,
        theoryPassPercent = 80,
        theoryTimeSeconds = 600,
        theoryFile = 'data/questions_class_c.json',
        practicalVehicle = 'blista',
        vehicleType = 'land',           -- land | bike | boat | air
        blipSprite = 225,
        color = '#1e5aab',
    },
    class_m = {
        enabled = true,
        label = 'Class M — Motorcycle',
        short = 'Class M',
        icon = 'motorcycle',
        description = 'Motorcycle and scooter endorsement.',
        licenseKey = 'motorcycle',
        qbxLicensesKey = 'motorcycle',
        esxLicense = 'drive_bike',
        item = 'motorcycle_license',
        maxPoints = 12,
        theoryPrice = 120,
        practicalPrice = 280,
        theoryQuestions = 12,
        theoryPassPercent = 80,
        theoryTimeSeconds = 480,
        theoryFile = 'data/questions_class_m.json',
        practicalVehicle = 'pcj',
        vehicleType = 'bike',
        blipSprite = 226,
        color = '#0ea5e9',
    },
    class_a = {
        enabled = true,
        label = 'Class A — Heavy Vehicle',
        short = 'Class A',
        icon = 'truck',
        description = 'Heavy truck and combination vehicle license.',
        licenseKey = 'truck',
        qbxLicensesKey = 'truck',
        esxLicense = 'drive_truck',
        item = 'truck_license',
        maxPoints = 12,
        theoryPrice = 250,
        practicalPrice = 550,
        theoryQuestions = 15,
        theoryPassPercent = 85,
        theoryTimeSeconds = 720,
        theoryFile = 'data/questions_class_a.json',
        practicalVehicle = 'packer',
        vehicleType = 'land',
        blipSprite = 477,
        color = '#f59e0b',
    },
    cdl = {
        enabled = true,
        label = 'CDL — Commercial Driver',
        short = 'CDL',
        icon = 'bus',
        description = 'Commercial Driver License for professional transport.',
        licenseKey = 'cdl',
        qbxLicensesKey = 'cdl',
        esxLicense = 'cdl',
        item = 'cdl_license',
        maxPoints = 12,
        theoryPrice = 400,
        practicalPrice = 800,
        theoryQuestions = 20,
        theoryPassPercent = 85,
        theoryTimeSeconds = 900,
        theoryFile = 'data/questions_cdl.json',
        practicalVehicle = 'bus',
        vehicleType = 'land',
        blipSprite = 513,
        color = '#8b5cf6',
        requires = { 'class_c' }, -- must already hold Class C
    },
    boat = {
        enabled = true,
        label = 'Boat License',
        short = 'Boat',
        icon = 'ship',
        description = 'Recreational and commercial vessel operation.',
        licenseKey = 'boat',
        qbxLicensesKey = 'boat',
        esxLicense = 'boat',
        item = 'boat_license',
        maxPoints = 12,
        theoryPrice = 180,
        practicalPrice = 400,
        theoryQuestions = 12,
        theoryPassPercent = 80,
        theoryTimeSeconds = 480,
        theoryFile = 'data/questions_boat.json',
        practicalVehicle = 'speeder',
        vehicleType = 'boat',
        blipSprite = 427,
        color = '#14b8a6',
    },
    pilot = {
        enabled = true,
        label = 'Pilot License',
        short = 'Pilot',
        icon = 'plane',
        description = 'Aircraft and helicopter operation certificate.',
        licenseKey = 'aircraft',
        qbxLicensesKey = 'aircraft',
        esxLicense = 'aircraft',
        item = 'aircraft_license',
        maxPoints = 12,
        theoryPrice = 600,
        practicalPrice = 1500,
        theoryQuestions = 15,
        theoryPassPercent = 90,
        theoryTimeSeconds = 900,
        theoryFile = 'data/questions_pilot.json',
        practicalVehicle = 'havok',
        vehicleType = 'air',
        blipSprite = 307,
        color = '#6366f1',
    },
}

--------------------------------------------------------------------
-- Practical exam scoring (points deducted per infraction)
--------------------------------------------------------------------
Config.PracticalScoring = {
    startingScore = 100,
    passScore = 70,
    maxErrors = 8,
    timeLimitSeconds = 600,
    deductions = {
        speeding = 8,
        vehicle_collision = 12,
        object_collision = 6,
        vehicle_damage = 5,
        out_of_zone = 15,
        missed_checkpoint = 10,
        abandon = 100,
        death = 100,
        left_vehicle = 20,
        overtime = 15,
        reckless = 10,
        -- air / boat specific
        crash_landing = 25,
        hard_landing = 8,
        water_collision = 15,
    },
    speedToleranceMph = 5, -- grace over posted limit before penalty
    damageCheckIntervalMs = 500,
    checkpointRadius = 8.0,
    airCheckpointRadius = 25.0,
    boatCheckpointRadius = 12.0,
}

--------------------------------------------------------------------
-- Driving schools (multiple locations)
--------------------------------------------------------------------
Config.Schools = {
    {
        id = 'ls_dmv',
        label = 'Los Santos DMV',
        blip = { sprite = 408, color = 3, scale = 0.85, label = 'DMV Driving School' },
        reception = vector4(240.75, -1379.58, 33.74, 140.0),
        ped = { model = 'a_m_y_business_02', scenario = 'WORLD_HUMAN_CLIPBOARD' },
        theorySpot = vector4(238.12, -1381.90, 33.74, 320.0),
        categories = { 'class_c', 'class_m', 'class_a', 'cdl', 'boat', 'pilot' },
        spawn = {
            class_c = vector4(222.50, -1387.80, 30.50, 270.0),
            class_m = vector4(220.10, -1391.20, 30.50, 270.0),
            class_a = vector4(215.40, -1395.60, 30.55, 270.0),
            cdl     = vector4(210.80, -1400.10, 30.55, 270.0),
            boat    = vector4(-805.30, -1496.50, 0.50, 110.0),
            pilot   = vector4(-979.50, -2995.80, 13.95, 60.0),
        },
        routes = {
            class_c = {
                speedLimitMph = 45,
                zoneRadius = 450.0,
                zoneCenter = vector3(200.0, -1400.0, 30.0),
                checkpoints = {
                    vector3(205.20, -1405.40, 30.45),
                    vector3(175.80, -1448.20, 29.20),
                    vector3(120.40, -1490.60, 29.10),
                    vector3(55.20, -1440.80, 29.25),
                    vector3(40.60, -1360.40, 29.20),
                    vector3(95.80, -1288.60, 29.20),
                    vector3(165.40, -1310.20, 29.20),
                    vector3(215.60, -1355.80, 30.40),
                    vector3(222.50, -1387.80, 30.50),
                },
            },
            class_m = {
                speedLimitMph = 50,
                zoneRadius = 480.0,
                zoneCenter = vector3(200.0, -1400.0, 30.0),
                checkpoints = {
                    vector3(205.20, -1405.40, 30.45),
                    vector3(150.40, -1460.20, 29.15),
                    vector3(80.60, -1505.40, 29.20),
                    vector3(20.40, -1420.80, 29.25),
                    vector3(70.20, -1300.40, 29.20),
                    vector3(180.60, -1295.20, 29.20),
                    vector3(220.10, -1391.20, 30.50),
                },
            },
            class_a = {
                speedLimitMph = 40,
                zoneRadius = 600.0,
                zoneCenter = vector3(180.0, -1450.0, 30.0),
                checkpoints = {
                    vector3(200.40, -1410.20, 30.45),
                    vector3(140.60, -1500.80, 29.10),
                    vector3(40.20, -1550.40, 29.20),
                    vector3(-40.80, -1480.60, 31.20),
                    vector3(-20.40, -1360.20, 29.40),
                    vector3(80.60, -1280.40, 29.20),
                    vector3(215.40, -1395.60, 30.55),
                },
            },
            cdl = {
                speedLimitMph = 35,
                zoneRadius = 650.0,
                zoneCenter = vector3(180.0, -1450.0, 30.0),
                checkpoints = {
                    vector3(195.40, -1415.20, 30.45),
                    vector3(130.20, -1520.60, 29.10),
                    vector3(20.40, -1580.80, 29.20),
                    vector3(-80.60, -1500.40, 32.10),
                    vector3(-50.20, -1380.60, 29.50),
                    vector3(100.40, -1260.80, 29.20),
                    vector3(210.80, -1400.10, 30.55),
                },
            },
            boat = {
                speedLimitMph = 40,
                zoneRadius = 500.0,
                zoneCenter = vector3(-850.0, -1550.0, 0.0),
                checkpoints = {
                    vector3(-830.40, -1520.60, 0.20),
                    vector3(-900.20, -1580.40, 0.20),
                    vector3(-980.60, -1620.80, 0.20),
                    vector3(-1050.40, -1550.20, 0.20),
                    vector3(-960.80, -1480.60, 0.20),
                    vector3(-860.40, -1500.20, 0.20),
                    vector3(-805.30, -1496.50, 0.50),
                },
            },
            pilot = {
                speedLimitMph = 120,
                zoneRadius = 1200.0,
                zoneCenter = vector3(-1200.0, -3000.0, 50.0),
                requireTakeoff = true,
                requireLanding = true,
                minAltitude = 15.0,
                checkpoints = {
                    vector3(-1100.40, -3050.60, 45.0),
                    vector3(-1300.20, -3100.40, 80.0),
                    vector3(-1500.60, -2950.80, 100.0),
                    vector3(-1400.40, -2750.20, 80.0),
                    vector3(-1200.80, -2850.60, 50.0),
                    vector3(-1000.40, -2950.20, 25.0),
                    vector3(-979.50, -2995.80, 13.95),
                },
            },
        },
    },
    {
        id = 'paleto_dmv',
        label = 'Paleto Bay DMV',
        blip = { sprite = 408, color = 3, scale = 0.75, label = 'DMV Driving School' },
        reception = vector4(-234.85, 6310.40, 31.48, 315.0),
        ped = { model = 'a_f_y_business_01', scenario = 'WORLD_HUMAN_CLIPBOARD' },
        theorySpot = vector4(-232.40, 6312.80, 31.48, 135.0),
        categories = { 'class_c', 'class_m', 'boat' },
        spawn = {
            class_c = vector4(-248.60, 6295.40, 31.45, 220.0),
            class_m = vector4(-252.20, 6298.80, 31.45, 220.0),
            boat    = vector4(-1605.40, 5258.60, 0.50, 25.0),
        },
        routes = {
            class_c = {
                speedLimitMph = 40,
                zoneRadius = 400.0,
                zoneCenter = vector3(-260.0, 6280.0, 31.0),
                checkpoints = {
                    vector3(-260.40, 6280.20, 31.40),
                    vector3(-320.60, 6220.80, 31.40),
                    vector3(-380.20, 6150.40, 31.40),
                    vector3(-300.80, 6100.60, 31.40),
                    vector3(-220.40, 6180.20, 31.40),
                    vector3(-248.60, 6295.40, 31.45),
                },
            },
            class_m = {
                speedLimitMph = 45,
                zoneRadius = 420.0,
                zoneCenter = vector3(-260.0, 6280.0, 31.0),
                checkpoints = {
                    vector3(-265.40, 6275.20, 31.40),
                    vector3(-340.60, 6200.80, 31.40),
                    vector3(-400.20, 6140.40, 31.40),
                    vector3(-280.80, 6080.60, 31.40),
                    vector3(-200.40, 6200.20, 31.40),
                    vector3(-252.20, 6298.80, 31.45),
                },
            },
            boat = {
                speedLimitMph = 35,
                zoneRadius = 450.0,
                zoneCenter = vector3(-1650.0, 5300.0, 0.0),
                checkpoints = {
                    vector3(-1620.40, 5280.60, 0.20),
                    vector3(-1700.20, 5350.40, 0.20),
                    vector3(-1780.60, 5400.80, 0.20),
                    vector3(-1720.40, 5480.20, 0.20),
                    vector3(-1620.80, 5380.60, 0.20),
                    vector3(-1605.40, 5258.60, 0.50),
                },
            },
        },
    },
}

--------------------------------------------------------------------
-- Markers (used when ox_target is unavailable or Interaction = marker/both)
--------------------------------------------------------------------
Config.Marker = {
    type = 1,
    scale = vector3(0.9, 0.9, 0.6),
    color = { r = 30, g = 90, b = 171, a = 160 },
    bobUpAndDown = false,
    faceCamera = false,
    rotate = false,
}

--------------------------------------------------------------------
-- Notifications
--------------------------------------------------------------------
Config.Notify = {
    position = 'top-right',
    duration = 5000,
}
