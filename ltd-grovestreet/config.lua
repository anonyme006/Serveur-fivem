Config = {}

-- =============================================================================
-- FRAMEWORK
-- 'esx' ou 'qbcore' — détection automatique si 'auto'
-- =============================================================================
Config.Framework = 'auto'

-- =============================================================================
-- GÉNÉRAL
-- =============================================================================
Config.JobName = 'ltd'
Config.SocietyName = 'society_ltd'
Config.Locale = 'fr'

-- Distance max pour les interactions (anti-cheat)
Config.InteractDistance = 2.5
Config.DeliveryValidateDistance = 8.0

-- Item ticket de caisse (doit exister dans ox_inventory)
Config.ReceiptItem = 'receipt'

-- =============================================================================
-- BLIP
-- =============================================================================
Config.Blip = {
    enabled = true,
    coords = vector3(-47.42, -1758.67, 29.42),
    sprite = 52,
    color = 2,
    scale = 0.8,
    label = 'LTD Grove Street',
}

-- =============================================================================
-- PED (optionnel — vendeur NPC décoratif)
-- =============================================================================
Config.Ped = {
    enabled = false,
    model = 'mp_m_shopkeep_01',
    coords = vector4(-46.58, -1757.89, 29.42, 50.0),
    scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
}

-- =============================================================================
-- GRADES
-- index = grade ESX (0 = recrue, etc.)
-- =============================================================================
Config.Grades = {
    [0] = { label = 'Recrue',       salary = 150,  canBoss = false, canRegister = true,  canStock = true,  canDelivery = true  },
    [1] = { label = 'Employé',      salary = 250,  canBoss = false, canRegister = true,  canStock = true,  canDelivery = true  },
    [2] = { label = 'Chef d\'équipe', salary = 350,  canBoss = false, canRegister = true,  canStock = true,  canDelivery = true  },
    [3] = { label = 'Manager',      salary = 450,  canBoss = true,  canRegister = true,  canStock = true,  canDelivery = true  },
    [4] = { label = 'Patron',       salary = 600,  canBoss = true,  canRegister = true,  canStock = true,  canDelivery = true  },
}

-- Grade minimum requis pour le menu patron
Config.BossMinGrade = 3

-- =============================================================================
-- POSITIONS D'INTERACTION (ox_target)
-- =============================================================================
Config.Locations = {
    -- Caisse enregistreuse
    register = {
        coords = vector3(-47.24, -1757.65, 29.42),
        size = vector3(0.6, 0.8, 1.0),
        rotation = 320.0,
        label = 'Utiliser la caisse',
        icon = 'fas fa-cash-register',
    },

    -- Menu patron
    boss = {
        coords = vector3(-44.58, -1749.35, 29.42),
        size = vector3(0.8, 0.8, 1.0),
        rotation = 0.0,
        label = 'Menu patron',
        icon = 'fas fa-briefcase',
    },

    -- Coffre partagé employés
    stash = {
        coords = vector3(-43.95, -1748.08, 29.42),
        size = vector3(1.2, 1.0, 1.5),
        rotation = 0.0,
        label = 'Coffre employés',
        icon = 'fas fa-box',
        stashId = 'ltd_grove_stash',
        slots = 50,
        weight = 100000,
    },

    -- Stock arrière (réserve)
    stockroom = {
        coords = vector3(-42.15, -1749.62, 29.42),
        size = vector3(1.5, 1.5, 1.5),
        rotation = 0.0,
        label = 'Réserve du magasin',
        icon = 'fas fa-warehouse',
    },

    -- Point de validation livraison
    deliveryValidate = {
        coords = vector3(-55.82, -1747.91, 29.42),
        size = vector3(4.0, 6.0, 3.0),
        rotation = 0.0,
        label = 'Valider la livraison',
        icon = 'fas fa-truck-loading',
    },

    -- Commande de marchandises (bureau)
    deliveryOrder = {
        coords = vector3(-44.10, -1748.70, 29.42),
        size = vector3(0.8, 0.8, 1.0),
        rotation = 0.0,
        label = 'Commander des marchandises',
        icon = 'fas fa-clipboard-list',
    },

    -- Pointeuse (prise / fin de service employés)
    clockIn = {
        coords = vector3(-43.30, -1749.90, 29.42),
        size = vector3(0.6, 0.6, 1.0),
        rotation = 0.0,
        label = 'Pointeuse',
        icon = 'fas fa-clock',
    },

    -- APU — caisse automatique (clients, magasin sans employé en service)
    apu = {
        coords = vector3(-46.90, -1758.90, 29.42),
        size = vector3(0.8, 0.6, 1.0),
        rotation = 320.0,
        label = 'Caisse automatique (APU)',
        icon = 'fas fa-desktop',
    },
}

-- =============================================================================
-- RAYONS (étagères client)
-- Chaque rayon ouvre un menu ox_lib avec les articles disponibles
-- =============================================================================
Config.Shelves = {
    boissons = {
        label = 'Boissons',
        icon = 'fas fa-bottle-water',
        coords = vector3(-48.52, -1759.35, 29.42),
        size = vector3(1.5, 0.6, 1.2),
        rotation = 320.0,
        items = {
            { item = 'water',       label = 'Eau',            price = 5   },
            { item = 'cola',        label = 'Cola',           price = 8   },
            { item = 'sprunk',      label = 'Sprunk',         price = 8   },
            { item = 'energy_drink', label = 'Boisson énergisante', price = 12 },
            { item = 'coffee',      label = 'Café',           price = 6   },
        },
    },

    snacks = {
        label = 'Snacks',
        icon = 'fas fa-cookie',
        coords = vector3(-49.85, -1758.50, 29.42),
        size = vector3(1.5, 0.6, 1.2),
        rotation = 320.0,
        items = {
            { item = 'bread',       label = 'Pain',           price = 4   },
            { item = 'sandwich',    label = 'Sandwich',       price = 10  },
            { item = 'chips',       label = 'Chips',          price = 6   },
            { item = 'chocolate',   label = 'Chocolat',       price = 7   },
            { item = 'donut',       label = 'Donut',          price = 5   },
        },
    },

    alcool = {
        label = 'Alcool',
        icon = 'fas fa-wine-bottle',
        coords = vector3(-51.10, -1757.65, 29.42),
        size = vector3(1.2, 0.6, 1.2),
        rotation = 320.0,
        items = {
            { item = 'beer',        label = 'Bière',          price = 15  },
            { item = 'whiskey',     label = 'Whisky',         price = 45  },
            { item = 'vodka',       label = 'Vodka',          price = 40  },
            { item = 'wine',        label = 'Vin',            price = 35  },
        },
    },

    cigarettes = {
        label = 'Cigarettes',
        icon = 'fas fa-smoking',
        coords = vector3(-52.35, -1756.80, 29.42),
        size = vector3(0.8, 0.6, 1.2),
        rotation = 320.0,
        items = {
            { item = 'cigarette',   label = 'Cigarette',      price = 12  },
            { item = 'cigarette_pack', label = 'Paquet de cigarettes', price = 80 },
            { item = 'lighter',     label = 'Briquet',        price = 5   },
        },
    },

    telephone = {
        label = 'Téléphone',
        icon = 'fas fa-mobile-alt',
        coords = vector3(-45.80, -1756.20, 29.42),
        size = vector3(0.8, 0.6, 1.2),
        rotation = 320.0,
        items = {
            { item = 'phone',       label = 'Téléphone',      price = 500 },
            { item = 'radio',       label = 'Radio',          price = 250 },
        },
    },

    divers = {
        label = 'Divers',
        icon = 'fas fa-shopping-basket',
        coords = vector3(-46.95, -1755.40, 29.42),
        size = vector3(1.0, 0.6, 1.2),
        rotation = 320.0,
        items = {
            { item = 'bandage',     label = 'Bandage',        price = 20  },
            { item = 'repairkit',   label = 'Kit de réparation', price = 150 },
            { item = 'lockpick',    label = 'Crochet',        price = 100 },
            { item = 'umbrella',    label = 'Parapluie',      price = 30  },
        },
    },
}

-- =============================================================================
-- LIVRAISONS
-- =============================================================================
Config.Delivery = {
    -- Véhicule de livraison
    vehicle = 'mule3',

    -- Point de spawn du camion (dépôt)
    spawnPoint = vector4(-424.52, -2789.82, 6.0, 315.0),

    -- Modèle du ped livreur (optionnel)
    driverModel = 's_m_m_trucker_01',

    -- Délai minimum entre deux commandes (secondes)
    cooldown = 600,

    -- Catalogue de commandes disponibles
    catalog = {
        { item = 'water',          label = 'Eau (x50)',           amount = 50,  cost = 150  },
        { item = 'cola',           label = 'Cola (x50)',          amount = 50,  cost = 200  },
        { item = 'sprunk',         label = 'Sprunk (x50)',        amount = 50,  cost = 200  },
        { item = 'bread',          label = 'Pain (x30)',          amount = 30,  cost = 80   },
        { item = 'sandwich',       label = 'Sandwich (x30)',      amount = 30,  cost = 180  },
        { item = 'chips',          label = 'Chips (x40)',         amount = 40,  cost = 120  },
        { item = 'beer',           label = 'Bière (x24)',         amount = 24,  cost = 200  },
        { item = 'whiskey',        label = 'Whisky (x12)',        amount = 12,  cost = 300  },
        { item = 'cigarette_pack', label = 'Paquets cigarettes (x20)', amount = 20, cost = 400 },
        { item = 'phone',          label = 'Téléphones (x5)',     amount = 5,   cost = 1500 },
        { item = 'bandage',        label = 'Bandages (x20)',      amount = 20,  cost = 200  },
    },
}

-- =============================================================================
-- STOCK INITIAL (réserve au démarrage du serveur)
-- =============================================================================
Config.InitialStock = {
    water = 100,
    cola = 80,
    sprunk = 80,
    energy_drink = 40,
    coffee = 60,
    bread = 50,
    sandwich = 40,
    chips = 60,
    chocolate = 50,
    donut = 40,
    beer = 48,
    whiskey = 24,
    vodka = 24,
    wine = 24,
    cigarette = 100,
    cigarette_pack = 30,
    lighter = 50,
    phone = 10,
    radio = 15,
    bandage = 30,
    repairkit = 10,
    lockpick = 15,
    umbrella = 20,
}

-- =============================================================================
-- NOTIFICATIONS (clés de traduction internes)
-- =============================================================================
Config.Notifications = {
    noJob          = 'Vous devez être employé LTD pour faire cela.',
    noGrade        = 'Votre grade ne permet pas cette action.',
    tooFar         = 'Vous êtes trop loin.',
    noStock        = 'Stock insuffisant.',
    noShelfStock   = 'Article indisponible en rayon.',
    purchaseSuccess = 'Achat effectué : %s x%d — $%d',
    chargeSuccess  = 'Paiement encaissé : $%d',
    chargeFailed   = 'Le client n\'a pas assez d\'argent.',
    receiptGiven   = 'Ticket de caisse remis au client.',
    stockFilled    = 'Rayon rempli : %s x%d',
    deliveryOrdered = 'Commande passée — récupérez le camion au dépôt.',
    deliveryActive  = 'Une livraison est déjà en cours.',
    deliveryCooldown = 'Veuillez patienter avant une nouvelle commande.',
    deliveryValidated = 'Livraison validée — marchandises ajoutées au stock.',
    deliveryNotReady  = 'Aucune livraison en attente de validation.',
    societyDeposit  = 'Dépôt effectué : $%d',
    societyWithdraw = 'Retrait effectué : $%d',
    notEnoughMoney  = 'Fonds insuffisants.',
    employeeHired   = 'Employé recruté.',
    employeeFired   = 'Employé licencié.',
    gradeUpdated    = 'Grade mis à jour.',
    clockInSuccess  = 'Prise de service enregistrée. Bon travail !',
    clockOutSuccess = 'Fin de service enregistrée.',
    notOnDuty       = 'Vous devez pointer à la pointeuse pour prendre votre service.',
    alreadyOnDuty   = 'Vous êtes déjà en service.',
    notClockedIn    = 'Vous n\'êtes pas en service.',
    apuUnavailable  = 'Caisse automatique indisponible — un employé est en service. Passez en caisse.',
    shopClosed      = 'Magasin fermé — aucun employé en service. Utilisez la caisse automatique (APU).',
    apuPurchaseSuccess = 'Paiement APU accepté — $%d. Merci de votre visite !',
    apuEmptyCart    = 'Votre panier est vide.',
}
