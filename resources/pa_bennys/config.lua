Config = {}

Config.CompanyName = "Benny's Original"
Config.SocietyAccount = 'society_bennys'
Config.Jobs = { bennys = true, mechanic = true }
Config.RequireDuty = false

Config.Workshop = {
    blip = { sprite = 446, color = 27, scale = 0.85, label = "Benny's — Atelier" },
    zones = {
        { coords = vec3(-211.0, -1324.0, 30.9), radius = 8.0, label = "Benny's — Atelier" },
        { coords = vec3(-337.0, -136.5, 39.0), radius = 8.0, label = 'LS Customs — Atelier' },
    },
}

Config.CustomShop = {
    blip = { sprite = 72, color = 27, scale = 0.85, label = "Benny's — Custom" },
    coords = vec3(-205.5, -1308.5, 31.3),
    radius = 6.0,
}

Config.Garage = {
    coords = vec3(-194.0, -1290.0, 31.3),
    spawn = vec4(-188.0, -1295.0, 31.3, 270.0),
    vehicles = {
        { model = 'flatbed', label = 'Dépanneuse Flatbed' },
        { model = 'towtruck2', label = 'Dépanneuse lourde' },
        { model = 'slamvan3', label = 'Van intervention' },
    },
}

Config.Repair = {
    diagnosticDuration = 5000,
    maxDistance = 5.0,
    openHoodFor = { engine = true, tank = true, full = true },
    engine = { duration = 12000, label = 'Réparation moteur', anim = { dict = 'mini@repair', clip = 'fixing_a_ped' } },
    body = { duration = 10000, label = 'Carrosserie', anim = { dict = 'mini@repair', clip = 'fixing_a_ped' } },
    tank = { duration = 8000, label = 'Réservoir', anim = { dict = 'mini@repair', clip = 'fixing_a_ped' } },
    tires = { duration = 6000, label = 'Changement pneus', anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer' } },
    clean = { duration = 4000, label = 'Nettoyage', anim = { dict = 'timetable@floyd@clean_kitchen@base', clip = 'base' } },
    full = { duration = 18000, label = 'Révision complète', anim = { dict = 'mini@repair', clip = 'fixing_a_ped' } },
}

Config.Prices = {
    engine = 450, body = 380, tank = 280, tires = 220, clean = 80, full = 950,
    customNeon = 350, customColor = 200, customWheels = 400, customTint = 150,
}
Config.EmployeeCut = 0.15

Config.CustomMods = {
    neonColors = {
        { label = 'Blanc', r = 222, g = 222, b = 255 }, { label = 'Bleu', r = 2, g = 21, b = 255 },
        { label = 'Bleu électrique', r = 3, g = 83, b = 255 }, { label = 'Vert menthe', r = 0, g = 255, b = 140 },
        { label = 'Vert lime', r = 94, g = 255, b = 1 }, { label = 'Jaune', r = 255, g = 255, b = 0 },
        { label = 'Orange', r = 255, g = 62, b = 0 }, { label = 'Rouge', r = 255, g = 1, b = 1 },
        { label = 'Rose', r = 255, g = 5, b = 190 }, { label = 'Violet', r = 153, g = 0, b = 153 },
    },
    windowTints = {
        { label = 'Aucune', index = 0 }, { label = 'Légère', index = 3 },
        { label = 'Fumée', index = 2 }, { label = 'Noir', index = 1 },
    },
    wheelTypes = {
        { label = 'Sport', type = 0 }, { label = 'Muscle', type = 1 }, { label = 'Lowrider', type = 2 },
        { label = 'SUV', type = 3 }, { label = 'Offroad', type = 4 }, { label = 'Tuner', type = 5 },
    },
}

Config.Bipeur = {
    command = 'bipeur',
    keybind = 'F6',
    sound = true,
    blipSprite = 446,
    blipColor = 5,
    blipTime = 120,
}

Config.Missions = {
    enabled = true,
    interval = { min = 120, max = 300 },
    maxActive = 3,
    payout = { min = 600, max = 1200 },
    societyShare = 0.70,
    employeeBonus = { min = 150, max = 350 },
    completeRadius = 12.0,
    types = {
        { id = 'engine', label = 'Panne moteur', message = 'Véhicule en panne moteur — intervention requise', damage = { engine = 150.0, body = 600.0 } },
        { id = 'flat', label = 'Crevaison', message = 'Crevaison signalée — changement de pneu', burstTires = true, damage = { engine = 900.0, body = 850.0 } },
        { id = 'accident', label = 'Accident léger', message = 'Accident de la route — véhicule immobilisé', damage = { engine = 400.0, body = 350.0 } },
        { id = 'battery', label = 'Batterie à plat', message = 'Démarrage impossible — batterie déchargée', damage = { engine = 200.0, body = 950.0 } },
    },
    vehicles = { 'blista', 'asea', 'primo', 'fugitive', 'stanier', 'ingot', 'surge', 'premier' },
    locations = {
        vec4(120.0, -1030.0, 29.3, 0.0), vec4(-515.0, -260.0, 35.5, 90.0), vec4(825.0, -1035.0, 26.5, 180.0),
        vec4(-1100.0, -1500.0, 4.5, 270.0), vec4(2550.0, 385.0, 108.5, 0.0), vec4(-3040.0, 590.0, 7.5, 90.0),
        vec4(1700.0, 3580.0, 35.5, 180.0), vec4(-220.0, 6200.0, 31.5, 45.0), vec4(170.0, -1700.0, 29.3, 270.0),
        vec4(-700.0, -920.0, 19.0, 0.0), vec4(1135.0, 2650.0, 38.0, 90.0), vec4(-1480.0, -660.0, 28.5, 180.0),
    },
}
