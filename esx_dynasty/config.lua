Config = {}

Config.Locale = 'fr'
Config.Currency = '$'
Config.CloseWithEscape = true

-- Job Dynasty 8
Config.JobName = 'realestateagent'

-- Grades (doivent correspondre au SQL)
Config.Grades = {
    recruit   = { grade = 0, label = 'Recrue',          salary = 150 },
    agent     = { grade = 1, label = 'Agent',           salary = 250 },
    experienc = { grade = 2, label = 'Agent senior',    salary = 350 },
    boss      = { grade = 3, label = 'Patron',          salary = 500 },
}

-- Permissions par grade minimum
Config.Permissions = {
    openCompanyPanel  = 0,
    openHousingPanel  = 0,
    createProperty    = 1,
    editProperty      = 1,
    deleteProperty    = 2,
    sellProperty      = 1,
    rentProperty      = 1,
    manageEmployees   = 3,
    manageVehicles    = 2,
    postNews          = 1,
    manageBillboard   = 2,
}

-- Agence Dynasty 8 (Rockford Hills)
Config.Office = {
    name = 'Dynasty 8',
    coords = vector3(-716.11, -272.96, 36.82),
    heading = 30.0,
    blip = {
        enabled = true,
        sprite = 374,
        colour = 43,
        scale = 0.9,
        label = 'Dynasty 8',
    },
    marker = {
        type = 1,
        size = vector3(1.6, 1.6, 0.5),
        color = { r = 46, g = 160, b = 90, a = 130 },
    },
    drawDistance = 22.0,
    interactDistance = 2.0,
}

-- Garage / flotte entreprise
Config.Garage = {
    coords = vector3(-709.45, -280.12, 36.78),
    spawn = { coords = vector3(-705.20, -284.55, 36.70), heading = 30.0 },
    storeDistance = 8.0,
    vehicles = {
        { model = 'baller2',  label = 'Baller',      minGrade = 0 },
        { model = 'oracle2',  label = 'Oracle XS',   minGrade = 1 },
        { model = 'exemplar', label = 'Exemplar',    minGrade = 2 },
        { model = 'rebla',    label = 'Rebla GTS',   minGrade = 3 },
    },
}

-- Commission sur ventes / locations (part société)
Config.Commission = {
    salePercent = 10,
    rentPercent = 15,
}

-- Blips logements sur carte (agents uniquement)
Config.ShowPropertyBlips = true
Config.PropertyBlip = {
    free = { sprite = 40, colour = 2 },
    sale = { sprite = 40, colour = 5 },
    rent = { sprite = 40, colour = 3 },
    owned = { sprite = 40, colour = 1 },
}

-- Intervalles de loyer (minutes RP simulées côté serveur = heures IRL optionnelles)
Config.RentBillingHours = 24

-- Catalogue d'intérieurs (shells / IPLs courants)
Config.Interiors = {
    {
        id = 'apartment_low',
        label = 'Appartement Bas de Gamme',
        type = 'appartement',
        image = 'apartment_low',
        entry = vector3(266.12, -1007.28, -101.01),
        heading = 0.0,
        stash = vector3(265.89, -999.32, -99.01),
        wardrobe = vector3(259.79, -1003.95, -99.01),
    },
    {
        id = 'apartment_mid',
        label = 'Appartement Moderne',
        type = 'appartement',
        image = 'apartment_mid',
        entry = vector3(346.55, -1012.79, -99.20),
        heading = 0.0,
        stash = vector3(351.98, -998.80, -99.20),
        wardrobe = vector3(350.84, -993.59, -99.20),
    },
    {
        id = 'apartment_high',
        label = 'Appartement Haut de Gamme',
        type = 'appartement',
        image = 'apartment_high',
        entry = vector3(-1459.17, -520.58, 56.93),
        heading = 30.0,
        stash = vector3(-1457.30, -530.90, 56.94),
        wardrobe = vector3(-1467.60, -537.20, 55.53),
    },
    {
        id = 'apartment_modern7',
        label = 'Appartement Moderne 7',
        type = 'appartement',
        image = 'apartment_modern7',
        entry = vector3(-859.85, -693.80, 114.00),
        heading = 320.0,
        stash = vector3(-858.20, -690.50, 114.00),
        wardrobe = vector3(-855.40, -687.10, 114.00),
    },
    {
        id = 'house_mid',
        label = 'Maison Moyenne',
        type = 'maison',
        image = 'house_mid',
        entry = vector3(346.61, -1012.97, -99.20),
        heading = 0.0,
        stash = vector3(351.98, -998.80, -99.20),
        wardrobe = vector3(350.84, -993.59, -99.20),
    },
    {
        id = 'mansion',
        label = 'Villa de Luxe',
        type = 'maison',
        image = 'mansion',
        entry = vector3(-174.33, 497.53, 137.67),
        heading = 190.0,
        stash = vector3(-167.40, 487.85, 133.84),
        wardrobe = vector3(-167.36, 487.80, 137.44),
    },
    {
        id = 'farmhouse',
        label = 'Ferme Rustique',
        type = 'maison',
        image = 'farmhouse',
        entry = vector3(151.45, -1007.81, -99.00),
        heading = 0.0,
        stash = vector3(151.45, -1004.20, -99.00),
        wardrobe = vector3(154.20, -1003.10, -99.00),
    },
    {
        id = 'motel',
        label = 'Chambre Motel',
        type = 'motel',
        image = 'motel',
        entry = vector3(151.45, -1007.81, -99.00),
        heading = 0.0,
        stash = vector3(151.45, -1004.20, -99.00),
        wardrobe = vector3(154.20, -1003.10, -99.00),
    },
    {
        id = 'office',
        label = 'Bureau',
        type = 'bureau',
        image = 'office',
        entry = vector3(-141.29, -620.97, 168.82),
        heading = 280.0,
        stash = vector3(-130.50, -633.80, 168.82),
        wardrobe = vector3(-133.10, -632.50, 168.82),
    },
    {
        id = 'warehouse',
        label = 'Entrepôt',
        type = 'entrepot',
        image = 'warehouse',
        entry = vector3(1048.51, -3097.08, -39.00),
        heading = 90.0,
        stash = vector3(1052.40, -3096.50, -39.00),
        wardrobe = vector3(1055.10, -3095.20, -39.00),
    },
    {
        id = 'mlo',
        label = 'MLO / Extérieur',
        type = 'mlo',
        image = 'mlo',
        entry = nil, -- pas de téléport, porte locale
        heading = 0.0,
        stash = nil,
        wardrobe = nil,
    },
}

-- Statuts possibles d'un bien
Config.Statuses = {
    'libre',
    'vente',
    'location',
    'occupe',
}

-- Actualités entreprise (max affichées)
Config.MaxNews = 30

-- Commandes
Config.Commands = {
    openPanel   = 'dynasty',
    openHousing = 'housing',
    giveKeys    = 'cleslogement',
}
