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

Config.RentBillingHours = 24

--[[
    Intérieurs GTA réels (coords natives / IPL DLC).
    entry     = spawn intérieur
    heading   = orientation
    ipl       = string ou table d'IPL à charger (nil = déjà en mémoire)
    tier      = low | mid | high | special
]]
Config.Interiors = {
    -- ── Appartements ─────────────────────────────────────────
    {
        id = 'apt_low',
        label = 'Appartement Bas de Gamme',
        description = 'Petit studio GTA (Low End Apartment)',
        type = 'appartement',
        tier = 'low',
        image = 'apt_low',
        entry = vector3(266.178, -1007.416, -101.009),
        heading = 0.0,
        stash = vector3(265.894, -999.392, -99.009),
        wardrobe = vector3(259.994, -1003.898, -99.009),
        ipl = nil,
    },
    {
        id = 'apt_mid',
        label = 'Appartement Moyen Standing',
        description = 'Appartement Mid-End (4 Integrity Way style)',
        type = 'appartement',
        tier = 'mid',
        image = 'apt_mid',
        entry = vector3(346.607, -1012.892, -99.196),
        heading = 0.0,
        stash = vector3(351.945, -998.749, -99.196),
        wardrobe = vector3(351.354, -993.473, -99.196),
        ipl = nil,
    },
    {
        id = 'apt_high_dellperro',
        label = 'Appartement Dell Perro Heights',
        description = 'Haut standing Dell Perro Heights',
        type = 'appartement',
        tier = 'high',
        image = 'apt_high',
        entry = vector3(-1452.291, -540.576, 74.044),
        heading = 33.0,
        stash = vector3(-1466.810, -526.900, 73.444),
        wardrobe = vector3(-1467.736, -537.188, 73.444),
        ipl = nil,
    },
    {
        id = 'apt_modern_1',
        label = 'Appartement Moderne 1',
        description = 'Eclipse Towers — Modern (IPL apa_v_mp_h_01_a)',
        type = 'appartement',
        tier = 'high',
        image = 'apt_modern',
        entry = vector3(-786.866, 315.764, 217.638),
        heading = 270.0,
        stash = vector3(-795.580, 326.750, 217.038),
        wardrobe = vector3(-797.770, 328.200, 220.438),
        ipl = { 'apa_v_mp_h_01_a' },
    },
    {
        id = 'apt_modern_2',
        label = 'Appartement Moderne 2',
        description = 'Eclipse Towers — Mody (IPL apa_v_mp_h_02_a)',
        type = 'appartement',
        tier = 'high',
        image = 'apt_modern',
        entry = vector3(-786.956, 315.623, 187.913),
        heading = 270.0,
        stash = vector3(-795.580, 326.750, 187.313),
        wardrobe = vector3(-797.770, 328.200, 190.713),
        ipl = { 'apa_v_mp_h_02_a' },
    },
    {
        id = 'apt_vibrant',
        label = 'Appartement Vibrant',
        description = 'Eclipse Towers — Vibrant (IPL apa_v_mp_h_03_a)',
        type = 'appartement',
        tier = 'high',
        image = 'apt_modern',
        entry = vector3(-774.013, 342.043, 196.686),
        heading = 90.0,
        stash = vector3(-765.200, 330.800, 196.086),
        wardrobe = vector3(-763.100, 329.500, 199.486),
        ipl = { 'apa_v_mp_h_03_a' },
    },
    {
        id = 'apt_sharp',
        label = 'Appartement Sharp',
        description = 'Eclipse Towers — Sharp (IPL apa_v_mp_h_04_a)',
        type = 'appartement',
        tier = 'high',
        image = 'apt_modern',
        entry = vector3(-787.075, 315.820, 217.639),
        heading = 270.0,
        stash = vector3(-795.580, 326.750, 217.038),
        wardrobe = vector3(-797.770, 328.200, 220.438),
        ipl = { 'apa_v_mp_h_04_a' },
    },
    {
        id = 'apt_monochrome',
        label = 'Appartement Monochrome',
        description = 'Eclipse Towers — Monochrome (IPL apa_v_mp_h_05_a)',
        type = 'appartement',
        tier = 'high',
        image = 'apt_modern',
        entry = vector3(-786.866, 315.764, 187.638),
        heading = 270.0,
        stash = vector3(-795.580, 326.750, 187.038),
        wardrobe = vector3(-797.770, 328.200, 190.438),
        ipl = { 'apa_v_mp_h_05_a' },
    },
    {
        id = 'apt_seductive',
        label = 'Appartement Seductive',
        description = 'Eclipse Towers — Seductive (IPL apa_v_mp_h_06_a)',
        type = 'appartement',
        tier = 'high',
        image = 'apt_modern',
        entry = vector3(-787.057, 315.726, 187.913),
        heading = 270.0,
        stash = vector3(-795.580, 326.750, 187.313),
        wardrobe = vector3(-797.770, 328.200, 190.713),
        ipl = { 'apa_v_mp_h_06_a' },
    },
    {
        id = 'apt_moody',
        label = 'Appartement Moody',
        description = 'Eclipse Towers — Moody (IPL apa_v_mp_h_07_a)',
        type = 'appartement',
        tier = 'high',
        image = 'apt_modern',
        entry = vector3(-787.212, 315.749, 187.913),
        heading = 270.0,
        stash = vector3(-795.580, 326.750, 187.313),
        wardrobe = vector3(-797.770, 328.200, 190.713),
        ipl = { 'apa_v_mp_h_07_a' },
    },
    {
        id = 'apt_regal',
        label = 'Appartement Regal',
        description = 'Eclipse Towers — Regal (IPL apa_v_mp_h_08_a)',
        type = 'appartement',
        tier = 'high',
        image = 'apt_modern',
        entry = vector3(-787.057, 315.726, 217.638),
        heading = 270.0,
        stash = vector3(-795.580, 326.750, 217.038),
        wardrobe = vector3(-797.770, 328.200, 220.438),
        ipl = { 'apa_v_mp_h_08_a' },
    },
    {
        id = 'apt_tinsel',
        label = 'Appartement Tinsel Towers',
        description = 'Tinsel Towers — intérieur haut de gamme',
        type = 'appartement',
        tier = 'high',
        image = 'apt_high',
        entry = vector3(-603.711, 59.022, 98.200),
        heading = 90.0,
        stash = vector3(-622.850, 55.120, 97.600),
        wardrobe = vector3(-594.630, 56.150, 97.000),
        ipl = nil,
    },

    -- ── Maisons ──────────────────────────────────────────────
    {
        id = 'house_low',
        label = 'Petite Maison',
        description = 'Maison basique (Lester style / intérieur low)',
        type = 'maison',
        tier = 'low',
        image = 'house_low',
        entry = vector3(266.178, -1007.416, -101.009),
        heading = 0.0,
        stash = vector3(265.894, -999.392, -99.009),
        wardrobe = vector3(259.994, -1003.898, -99.009),
        ipl = nil,
    },
    {
        id = 'house_mid',
        label = 'Maison Moyenne',
        description = 'Maison Mid-End (intérieur appartement moyen)',
        type = 'maison',
        tier = 'mid',
        image = 'house_mid',
        entry = vector3(346.607, -1012.892, -99.196),
        heading = 0.0,
        stash = vector3(351.945, -998.749, -99.196),
        wardrobe = vector3(351.354, -993.473, -99.196),
        ipl = nil,
    },
    {
        id = 'house_franklin',
        label = 'Maison Franklin (Vinewood Hills)',
        description = 'Intérieur villa Franklin — 3671 Whispymound',
        type = 'maison',
        tier = 'high',
        image = 'mansion',
        entry = vector3(7.119, 536.615, 176.028),
        heading = 0.0,
        stash = vector3(3.500, 530.200, 175.400),
        wardrobe = vector3(8.820, 528.450, 170.635),
        ipl = nil,
    },
    {
        id = 'house_michael',
        label = 'Maison Michael',
        description = 'Intérieur villa Michael — Rockford Hills',
        type = 'maison',
        tier = 'high',
        image = 'mansion',
        entry = vector3(-815.281, 178.153, 72.153),
        heading = 110.0,
        stash = vector3(-800.850, 177.320, 72.835),
        wardrobe = vector3(-811.970, 175.080, 76.745),
        ipl = nil,
    },
    {
        id = 'house_trevor',
        label = 'Trailer Trevor',
        description = 'Caravane Trevor — Sandy Shores',
        type = 'maison',
        tier = 'low',
        image = 'trailer',
        entry = vector3(1973.085, 3816.017, 33.428),
        heading = 30.0,
        stash = vector3(1970.300, 3819.100, 33.428),
        wardrobe = vector3(1969.450, 3814.850, 33.428),
        ipl = nil,
    },
    {
        id = 'house_madrazo',
        label = 'Ranch Madrazo',
        description = 'Intérieur ranch (Ferme Rustique)',
        type = 'maison',
        tier = 'mid',
        image = 'farmhouse',
        entry = vector3(1398.050, 1141.840, 114.330),
        heading = 270.0,
        stash = vector3(1402.800, 1146.200, 114.330),
        wardrobe = vector3(1398.900, 1138.200, 114.330),
        ipl = nil,
    },

    -- ── Motel / divers ───────────────────────────────────────
    {
        id = 'motel',
        label = 'Chambre Motel',
        description = 'Chambre motel classique GTA',
        type = 'motel',
        tier = 'low',
        image = 'motel',
        entry = vector3(151.450, -1007.800, -99.000),
        heading = 0.0,
        stash = vector3(151.350, -1003.150, -99.000),
        wardrobe = vector3(152.800, -1001.200, -99.000),
        ipl = nil,
    },
    {
        id = 'biker_clubhouse',
        label = 'Clubhouse Motards',
        description = 'Clubhouse DLC Bikers (petit)',
        type = 'bureau',
        tier = 'mid',
        image = 'clubhouse',
        entry = vector3(1121.017, -3152.694, -37.063),
        heading = 0.0,
        stash = vector3(1116.500, -3162.800, -36.870),
        wardrobe = vector3(1116.500, -3162.800, -36.870),
        ipl = { 'bkr_biker_interior_placement_interior_0_biker_dlc_int_01_milo' },
    },

    -- ── Bureaux / entrepôts ──────────────────────────────────
    {
        id = 'office_arcadius',
        label = 'Bureau Arcadius',
        description = 'Bureau CEO Arcadius (Executive)',
        type = 'bureau',
        tier = 'high',
        image = 'office',
        entry = vector3(-141.198, -620.913, 168.820),
        heading = 275.0,
        stash = vector3(-138.900, -634.200, 168.820),
        wardrobe = vector3(-132.800, -633.600, 168.820),
        ipl = { 'ex_dt1_02_office_02b' },
    },
    {
        id = 'warehouse_small',
        label = 'Petit Entrepôt',
        description = 'Entrepôt CEO small',
        type = 'entrepot',
        tier = 'mid',
        image = 'warehouse',
        entry = vector3(1087.395, -3099.373, -39.000),
        heading = 270.0,
        stash = vector3(1095.200, -3098.500, -39.000),
        wardrobe = vector3(1103.500, -3099.200, -39.000),
        ipl = { 'ex_exec_warehouse_placement_interior_1_int_warehouse_s_dlc' },
    },
    {
        id = 'warehouse_medium',
        label = 'Entrepôt Moyen',
        description = 'Entrepôt CEO medium',
        type = 'entrepot',
        tier = 'mid',
        image = 'warehouse',
        entry = vector3(1048.289, -3097.079, -39.000),
        heading = 90.0,
        stash = vector3(1055.100, -3102.500, -39.000),
        wardrobe = vector3(1060.800, -3102.500, -39.000),
        ipl = { 'ex_exec_warehouse_placement_interior_0_int_warehouse_m_dlc' },
    },
    {
        id = 'warehouse_large',
        label = 'Grand Entrepôt',
        description = 'Entrepôt CEO large',
        type = 'entrepot',
        tier = 'high',
        image = 'warehouse',
        entry = vector3(992.528, -3097.851, -39.000),
        heading = 90.0,
        stash = vector3(1003.200, -3102.500, -39.000),
        wardrobe = vector3(1009.500, -3102.500, -39.000),
        ipl = { 'ex_exec_warehouse_placement_interior_2_int_warehouse_l_dlc' },
    },

    -- ── MLO (pas de téléport intérieur) ──────────────────────
    {
        id = 'mlo',
        label = 'MLO / Extérieur uniquement',
        description = 'Pas de téléport — porte locale au point d\'entrée',
        type = 'mlo',
        tier = 'special',
        image = 'mlo',
        entry = nil,
        heading = 0.0,
        stash = nil,
        wardrobe = nil,
        ipl = nil,
    },
}

-- Statuts possibles d'un bien
Config.Statuses = {
    'libre',
    'vente',
    'location',
    'occupe',
}

Config.MaxNews = 30

-- Placement de points in-game
Config.PointPlacement = {
    timeoutMs = 120000, -- 2 min max
    helpKey = 38,       -- E
    cancelKey = 177,    -- Backspace
}

Config.Commands = {
    openPanel   = 'dynasty',
    openHousing = 'housing',
    giveKeys    = 'cleslogement',
}
