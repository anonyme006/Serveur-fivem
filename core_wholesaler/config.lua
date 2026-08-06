--[[
    core_wholesaler — Configuration
    Tout est configurable : positions, PNJ, blips, prix, catégories,
    produits, entreprises, grades, taxes, TVA, temps de préparation.
]]

Config = {}

-- Langue (fr / en)
Config.Locale = 'fr'

-- Debug (logs supplémentaires)
Config.Debug = false

--------------------------------------------------------------------------------
-- Entreprise grossiste
--------------------------------------------------------------------------------
Config.Job = {
    name = 'wholesaler',
    label = 'Grossiste Central',
    grades = {
        [0] = { name = 'employee',   label = 'Employé',     boss = false },
        [1] = { name = 'preparer',   label = 'Préparateur', boss = false },
        [2] = { name = 'manager',    label = 'Manager',     boss = false },
        [3] = { name = 'boss',       label = 'Patron',      boss = true  },
    },
}

-- Grade minimum pour certaines actions
Config.Permissions = {
    prepareOrders   = 1, -- préparer une commande
    manageStock     = 2, -- ajouter / retirer stock
    managePrices    = 3, -- modifier les prix
    bossMenu        = 3, -- menu patron
    adminBypass     = true, -- ACE permission core_wholesaler.admin
}

--------------------------------------------------------------------------------
-- PNJ vendeur (hors service)
-- Actif uniquement quand aucun employé grossiste n'est en service (onduty).
--------------------------------------------------------------------------------
Config.NpcVendor = {
    enabled = true,
    -- Majoration de prix hors service (1.0 = prix normal)
    priceMultiplier = 1.15,
    -- true = paie et reçoit les items immédiatement (boutique PNJ)
    -- false = crée une commande avec préparation accélérée
    instantGive = true,
    -- Temps de préparation si instantGive = false (secondes)
    prepareBase = 15,
    preparePerItem = 1,
    -- Position du PNJ vendeur
    coords = vec4(1006.50, -3102.0, -39.0, 180.0),
    ped = {
        model = 's_m_m_linecook',
        scenario = 'WORLD_HUMAN_CLIPBOARD',
    },
    targetLabel = 'Acheter (hors service)',
    targetIcon = 'fas fa-store',
}

--------------------------------------------------------------------------------
-- Paiement
--------------------------------------------------------------------------------
Config.Payment = {
    -- Modes autorisés : 'society' | 'bank' | 'cash'
    methods = {
        society = true, -- compte société (Renewed-Banking / qb-banking)
        bank    = true, -- banque personnelle
        cash    = true, -- argent liquide
    },
    -- Ressource banking : 'renewed' | 'qb-banking' | 'qbx_management'
    banking = 'renewed',
    -- Compte société du grossiste (revenus)
    wholesalerAccount = 'wholesaler',
}

--------------------------------------------------------------------------------
-- Taxes & TVA
--------------------------------------------------------------------------------
Config.Tax = {
    enabled = true,
    vatRate = 0.20,      -- TVA 20 %
    companyTax = 0.05,   -- taxe entreprise 5 % (ajoutée au HT)
}

--------------------------------------------------------------------------------
-- Commandes — cycle de vie
--------------------------------------------------------------------------------
Config.Orders = {
    -- Temps de préparation de base (secondes) + (qty * perItem)
    prepareBase = 60,
    preparePerItem = 2,
    -- Statuts : pending → prepared → available → withdrawn | delivered
    statuses = {
        pending    = 'pending',
        prepared   = 'prepared',
        available  = 'available',
        withdrawn  = 'withdrawn',
        delivered  = 'delivered',
        cancelled  = 'cancelled',
    },
    -- Quantité max par ligne de commande
    maxQtyPerLine = 100,
    -- Nombre max de lignes par commande
    maxLines = 20,
}

--------------------------------------------------------------------------------
-- Livraison (transporteurs)
--------------------------------------------------------------------------------
Config.Delivery = {
    enabled = true,
    -- Jobs autorisés à livrer
    jobs = { 'trucker', 'delivery', 'logistics' },
    -- Récompense de base + % du montant commande
    rewardBase = 500,
    rewardPercent = 0.05,
    -- Véhicule de livraison (spawn optionnel)
    vehicle = 'mule',
    -- Distance max pour déposer
    dropoffDistance = 8.0,
}

--------------------------------------------------------------------------------
-- Export (cargaisons vers Port / Gare / Aéroport)
--------------------------------------------------------------------------------
Config.Export = {
    enabled = true,
    -- Grade minimum employé grossiste pour lancer un export
    minGrade = 1,
    vehicle = 'packer',
    trailer = 'trailers',
    rewardMultiplier = 1.8, -- paiement élevé
    destinations = {
        {
            id = 'port',
            label = 'Port de Los Santos',
            coords = vec3(1182.0, -2983.0, 5.9),
            heading = 180.0,
            blip = { sprite = 356, color = 3 },
        },
        {
            id = 'station',
            label = 'Gare de Los Santos',
            coords = vec3(467.0, -620.0, 28.5),
            heading = 90.0,
            blip = { sprite = 795, color = 5 },
        },
        {
            id = 'airport',
            label = 'Aéroport LSIA',
            coords = vec3(-1043.0, -2746.0, 21.4),
            heading = 330.0,
            blip = { sprite = 307, color = 4 },
        },
    },
}

--------------------------------------------------------------------------------
-- Entreprises autorisées à commander (job name → catégories autorisées)
-- nil / '*' = toutes les catégories
--------------------------------------------------------------------------------
Config.AllowedCompanies = {
    ['burgershot']  = { 'food', 'restaurant' },
    ['uwu']         = { 'food', 'restaurant' },
    ['pizza']       = { 'food', 'restaurant' },
    ['mechanic']    = { 'mechanic' },
    ['bennys']      = { 'mechanic' },
    ['ambulance']   = { 'ems' },
    ['police']      = { 'police' },
    ['sheriff']     = { 'police' },
    ['fueler']      = { 'gasstation' },
    ['construction']= { 'construction' },
    ['builder']     = { 'construction' },
    -- Accès total (ex. gouvernement)
    ['government']  = '*',
}

-- Grade minimum chez le client pour passer commande
Config.BuyerMinGrade = 0

--------------------------------------------------------------------------------
-- Positions entrepôt (Grand entrepôt centralisé)
--------------------------------------------------------------------------------
Config.Warehouse = {
    -- Blip carte
    blip = {
        enabled = true,
        coords = vec3(1005.0, -3103.0, -39.0),
        sprite = 478,
        color = 5,
        scale = 0.85,
        label = 'Grossiste Central',
    },

    -- Accueil
    reception = {
        coords = vec4(1005.25, -3100.50, -39.0, 270.0),
        ped = {
            model = 'a_m_m_business_01',
            scenario = 'WORLD_HUMAN_CLIPBOARD',
        },
        targetLabel = 'Accueil Grossiste',
        targetIcon = 'fas fa-warehouse',
    },

    -- Zone de commande
    orderZone = {
        coords = vec3(1008.0, -3098.0, -39.0),
        size = vec3(3.0, 3.0, 2.5),
        rotation = 0.0,
        targetLabel = 'Passer commande',
        targetIcon = 'fas fa-cart-shopping',
    },

    -- Zone de retrait
    pickupZone = {
        coords = vec3(1012.0, -3102.0, -39.0),
        size = vec3(4.0, 3.0, 2.5),
        rotation = 0.0,
        targetLabel = 'Retirer une commande',
        targetIcon = 'fas fa-box-open',
    },

    -- Quai de chargement
    loadingDock = {
        coords = vec3(1000.0, -3110.0, -39.0),
        size = vec3(8.0, 6.0, 3.0),
        rotation = 0.0,
        spawn = vec4(995.0, -3115.0, -39.0, 180.0),
        targetLabel = 'Quai de chargement',
        targetIcon = 'fas fa-truck-loading',
    },

    -- Bureau du responsable
    bossOffice = {
        coords = vec4(1015.50, -3095.0, -39.0, 90.0),
        ped = {
            model = 'a_m_y_business_02',
            scenario = 'WORLD_HUMAN_STAND_MOBILE',
        },
        targetLabel = 'Bureau du responsable',
        targetIcon = 'fas fa-briefcase',
    },
}

--------------------------------------------------------------------------------
-- Catégories & Produits
-- image : nom d'item ox_inventory (nui://ox_inventory/web/images/<item>.png)
--------------------------------------------------------------------------------
Config.Categories = {
    food = {
        label = 'Alimentation',
        icon = 'fas fa-apple-whole',
        products = {
            { item = 'water',        label = 'Eau',           price = 5,    stock = 500, image = 'water' },
            { item = 'soda',         label = 'Soda',          price = 8,    stock = 400, image = 'soda' },
            { item = 'bread',        label = 'Pain',          price = 6,    stock = 300, image = 'bread' },
            { item = 'meat',         label = 'Viande',        price = 25,   stock = 200, image = 'meat' },
            { item = 'fruit',        label = 'Fruits',        price = 12,   stock = 250, image = 'fruit' },
            { item = 'vegetable',    label = 'Légumes',       price = 10,   stock = 250, image = 'vegetable' },
            { item = 'flour',        label = 'Farine',        price = 8,    stock = 200, image = 'flour' },
            { item = 'sugar',        label = 'Sucre',         price = 7,    stock = 200, image = 'sugar' },
            { item = 'coffee_beans', label = 'Café',          price = 15,   stock = 180, image = 'coffee' },
            { item = 'milk',         label = 'Lait',          price = 9,    stock = 220, image = 'milk' },
        },
    },

    restaurant = {
        label = 'Restaurant',
        icon = 'fas fa-utensils',
        products = {
            { item = 'ingredients',  label = 'Ingrédients',   price = 30,   stock = 300, image = 'ingredients' },
            { item = 'drinks_crate', label = 'Boissons',      price = 45,   stock = 200, image = 'drinks' },
            { item = 'packaging',    label = 'Emballages',    price = 20,   stock = 350, image = 'packaging' },
        },
    },

    mechanic = {
        label = 'Mécano',
        icon = 'fas fa-wrench',
        products = {
            { item = 'tyre',            label = 'Pneus',           price = 150,  stock = 100, image = 'tyre' },
            { item = 'engine_part',     label = 'Moteurs',         price = 800,  stock = 40,  image = 'engine' },
            { item = 'brakes',          label = 'Freins',          price = 200,  stock = 80,  image = 'brakes' },
            { item = 'car_battery',     label = 'Batteries',       price = 180,  stock = 60,  image = 'battery' },
            { item = 'repairkit',       label = 'Kits réparation', price = 250,  stock = 100, image = 'repairkit' },
            { item = 'engine_oil',      label = 'Huile moteur',    price = 50,   stock = 150, image = 'oil' },
        },
    },

    ems = {
        label = 'EMS',
        icon = 'fas fa-briefcase-medical',
        products = {
            { item = 'medicine',       label = 'Médicaments',    price = 40,   stock = 200, image = 'medicine' },
            { item = 'bandage',        label = 'Bandages',       price = 15,   stock = 300, image = 'bandage' },
            { item = 'medikit',        label = 'Kits médicaux',  price = 120,  stock = 100, image = 'medikit' },
            { item = 'defibrillator',  label = 'Défibrillateur', price = 500,  stock = 30,  image = 'defib' },
            { item = 'iv_bag',         label = 'Perfusions',     price = 80,   stock = 80,  image = 'ivbag' },
        },
    },

    police = {
        label = 'Police',
        icon = 'fas fa-shield-halved',
        -- Munitions : requiresAmmoAuth = true → vérifié côté serveur
        products = {
            { item = 'cone',           label = 'Cônes',          price = 20,   stock = 150, image = 'cone' },
            { item = 'barrier',        label = 'Barrières',      price = 50,   stock = 100, image = 'barrier' },
            { item = 'flashlight',     label = 'Lampes',         price = 35,   stock = 80,  image = 'flashlight' },
            { item = 'armor',          label = 'Gilets',         price = 200,  stock = 60,  image = 'armor' },
            { item = 'ammo-9',         label = 'Munitions 9mm',  price = 5,    stock = 500, image = 'ammo-9',  requiresAmmoAuth = true },
            { item = 'ammo-rifle',     label = 'Munitions rifle',price = 8,    stock = 300, image = 'ammo-rifle', requiresAmmoAuth = true },
        },
    },

    gasstation = {
        label = 'Station-service',
        icon = 'fas fa-gas-pump',
        products = {
            { item = 'fuel_tank',      label = 'Cuves',          price = 1200, stock = 20,  image = 'fueltank' },
            { item = 'fuel_pump',      label = 'Pompes',         price = 2500, stock = 10,  image = 'fuelpump' },
            { item = 'ox_fuel_part',   label = 'Pièces ox_fuel', price = 350,  stock = 50,  image = 'fuelpart' },
            { item = 'fuel_canister',  label = 'Carburant',      price = 80,   stock = 200, image = 'fuel' },
        },
    },

    construction = {
        label = 'Chantier',
        icon = 'fas fa-hard-hat',
        products = {
            { item = 'wood',           label = 'Bois',           price = 40,   stock = 200, image = 'wood' },
            { item = 'metal',          label = 'Métal',          price = 60,   stock = 180, image = 'metal' },
            { item = 'concrete',       label = 'Béton',          price = 50,   stock = 150, image = 'concrete' },
            { item = 'tools',          label = 'Outils',         price = 100,  stock = 100, image = 'tools' },
        },
    },
}

--------------------------------------------------------------------------------
-- Munitions (autorisation)
--------------------------------------------------------------------------------
Config.AmmoAuth = {
    enabled = true,
    -- Jobs autorisés à acheter des munitions
    jobs = { 'police', 'sheriff' },
    -- Grade minimum
    minGrade = 2,
}

--------------------------------------------------------------------------------
-- Notifications
--------------------------------------------------------------------------------
Config.Notify = {
    position = 'top-right',
    duration = 5000,
}
