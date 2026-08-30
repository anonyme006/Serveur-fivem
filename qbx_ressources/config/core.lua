--[[ Core RP (ex qbx_rp_core) ]]
Config.Locale = 'fr'

--[[--------------------------------------------------------------------------
    Persistance des véhicules
---------------------------------------------------------------------------]]
Config.Persistence = {
    enabled = true,
    -- Intervalle de sauvegarde (ms) des props véhicule (moteur, carrosserie, essence, coords)
    saveInterval = 60000,
    -- Sauvegarder aussi à la sortie du véhicule / déconnexion
    saveOnExit = true,
    -- Distance max pour considérer un véhicule "suivi" par le joueur
    trackDistance = 80.0,
    -- Colonnes player_vehicles (QBox / qbx_vehicles)
    -- state : 0 = sorti, 1 = garage, 2 = fourrière
    columns = {
        table = 'player_vehicles',
        owner = 'citizenid',
        plate = 'plate',
        vehicle = 'mods', -- JSON props (certains forks utilisent "vehicle")
        stored = 'state',  -- numérique QBox (voir AutoImpound)
        parking = 'garage',
        pound = 'garage',  -- fourrière = garage id spécial
        type = nil,        -- pas toujours présent sur QBox
    },
    -- Valeurs state QBox
    state = {
        out = 0,
        garaged = 1,
        impound = 2,
    },
}

--[[--------------------------------------------------------------------------
    Fourrière automatique au reboot
    Les véhicules sortis (stored = 0) sont envoyés en fourrière au démarrage.
---------------------------------------------------------------------------]]
Config.AutoImpound = {
    enabled = true,
    -- Garage / id fourrière (qbx_garages / custom)
    impoundId = 'impound',
    -- state = 2 (impound) sur player_vehicles
    setPoundColumn = true,
    log = true,
}

--[[--------------------------------------------------------------------------
    Dégâts d'accident
---------------------------------------------------------------------------]]
Config.Damage = {
    enabled = true,
    -- Seuil de vitesse (km/h) pour compter un choc
    minSpeed = 35.0,
    -- Multiplicateur de dégâts moteur / carrosserie appliqués en plus du natif
    engineMultiplier = 1.15,
    bodyMultiplier = 1.10,
    -- Chance (%) que le moteur cale après un gros choc (body < seuil)
    stallChance = 35,
    stallBodyThreshold = 450.0,
    -- Notification joueur
    notify = true,
}

--[[--------------------------------------------------------------------------
    Clés véhicules & habitations
---------------------------------------------------------------------------]]
Config.Keys = {
    enabled = true,
    -- Touche verrouillage véhicule (défaut U)
    lockCommand = 'vehiclelock',
    lockKey = 'U',
    lockDistance = 6.0,
    -- Animation + son
    useAnim = true,
    -- Clés temporaires (minutes max)
    maxTempMinutes = 10080,
    -- Distance interaction porte habitation
    houseDistance = 2.5,
    -- Donner automatiquement les clés (DB + item)
    giveOnGarageTakeOut = true, -- assure la clé DB ; item seulement si perdu (voir inventory.giveMissingOnGarage)
    giveOnPurchase = true,      -- qbx_vehicleshop / concessionnaire
    notifyOnGive = true,

    inventory = {
        enabled = true,
        item = 'vehicle_key',
        giveItemOnPurchase = true,
        giveMissingOnGarage = false,
        requireItemToLock = true,
        -- 'auto' | 'ox' (QBox = ox_inventory)
        system = 'ox',
    },
}

--[[--------------------------------------------------------------------------
    Serrurier — racheter / dupliquer une clé de véhicule owned
---------------------------------------------------------------------------]]
Config.KeyShop = {
    enabled = true,
    label = 'Serrurier',
    price = 100,
    account = 'bank', -- 'bank' | 'cash' (money → cash)
    -- Nombre max de clés item en inventaire par plaque
    maxKeysPerPlate = 3,
    blip = { enabled = true, sprite = 186, color = 5, scale = 0.75 },
    -- Point(s) d'achat
    locations = {
        {
            coords = vec3(170.12, -1799.45, 29.32),
            heading = 140.0,
            ped = 's_m_m_autoshop_01', -- nil = marker seulement
        },
    },
}

--[[--------------------------------------------------------------------------
    Portefeuille & trousseau de clés
---------------------------------------------------------------------------]]
Config.Wallet = {
    enabled = true,
    command = 'portefeuille',
    key = 'F4',
    -- Comptes QBox affichés
    accounts = { 'cash', 'bank' },
}

--[[--------------------------------------------------------------------------
    Bâche voiture
---------------------------------------------------------------------------]]
Config.Cover = {
    enabled = true,
    command = 'bache',
    -- Prop bâche optionnel (laisser '' pour véhicule gelé seul).
    -- Exemples stream custom : prop_cover_car_01 — sinon le véhicule reste visible, sale et verrouillé.
    prop = '',
    offset = vec3(0.0, 0.0, 0.05),
    -- Distance pour poser / retirer
    distance = 4.0,
    -- Durée progress (ms)
    progress = 4000,
    -- Véhicule doit être à l'arrêt et verrouillé
    requireLocked = false,
}

--[[--------------------------------------------------------------------------
    Parking véhicules d'occasion
---------------------------------------------------------------------------]]
Config.UsedParking = {
    enabled = true,
    blip = { enabled = true, sprite = 225, color = 46, scale = 0.8, label = 'Parking Occasions' },
    -- Zone principale (Los Santos — parking près de Strawberry)
    zone = {
        coords = vec3(173.10, -1736.55, 29.30),
        radius = 35.0,
    },
    -- Emplacements de vente (véhicule spawné + panneau)
    slots = {
        vec4(166.55, -1728.90, 28.90, 140.0),
        vec4(171.20, -1732.40, 28.90, 140.0),
        vec4(175.85, -1735.90, 28.90, 140.0),
        vec4(180.50, -1739.40, 28.90, 140.0),
        vec4(161.90, -1725.40, 28.90, 140.0),
        vec4(185.15, -1742.90, 28.90, 140.0),
    },
    -- Commission vendeur (%) prélevée à la vente
    commission = 5,
    -- Prix min / max
    minPrice = 500,
    maxPrice = 5000000,
    -- Compte de paiement acheteur
    payAccount = 'bank',
    -- Interaction
    targetRadius = 2.5,
}

--[[--------------------------------------------------------------------------
    Carte en main à l'Échap (pause menu)
---------------------------------------------------------------------------]]
Config.Map = {
    enabled = true,
    -- Prop carte
    prop = 'prop_tourist_map_01',
    bone = 57005, -- main droite
    pos = vec3(0.12, 0.02, -0.02),
    rot = vec3(15.0, 110.0, 120.0),
    -- Animation
    dict = 'amb@world_human_tourist_map@male@base',
    anim = 'base',
}

--[[--------------------------------------------------------------------------
    Alertes essence / faim / soif (metadata QBox 0–100)
---------------------------------------------------------------------------]]
Config.Alerts = {
    fuel = {
        enabled = true,
        threshold = 15,      -- %
        cooldown = 90000,    -- ms entre alertes
        -- 'auto' | 'ox_fuel' | 'LegacyFuel' | 'native'
        resource = 'auto',
    },
    needs = {
        enabled = true,
        hungerThreshold = 20,
        thirstThreshold = 20,
        cooldown = 120000,
        -- clés metadata PlayerData.metadata
        hunger = 'hunger',
        thirst = 'thirst',
    },
}

--[[--------------------------------------------------------------------------
    Offroad — adhérence / vitesse réduite sur sable, boue, herbe, etc.
---------------------------------------------------------------------------]]
Config.Offroad = {
    enabled = true,
    -- Notifier quand on entre sur un sol difficile
    notify = true,
    -- Intervalle de check (ms) — bas = plus réactif
    interval = 150,
    -- Classes GTA exemptées (9 = Off-road, 8 = Motos, 13 = Cycles, 14 = Bateaux, 15 = Hélicos, 16 = Avions)
    exemptClasses = {
        [8] = true,  -- motos
        [9] = true,  -- off-road (Léger pénalité via offroadMultiplier)
        [13] = true, -- vélos
        [14] = true,
        [15] = true,
        [16] = true,
        [21] = true, -- trains
    },
    -- Les vrais 4x4 (classe 9) gardent une partie de la traction
    offroadClassMultiplier = 0.85, -- 1.0 = aucune pénalité, 0.0 = pénalité pleine
    -- Modèles whitelist (aucun effet) — hash ou nom
    whitelist = {
        -- 'sandking', 'trophytruck',
    },
    -- Modèles plus pénalisés (berlines, supersport) — hash ou nom → multiplicateur extra (0.5 = encore plus lent)
    softMultiplier = {
        -- ['adder'] = 0.7,
    },
    --[[
        Surfaces (GetVehicleWheelSurfaceMaterial)
        traction  = couple moteur (0.0–1.0), 1 = normal
        maxKmh    = vitesse max plafonnée (nil = pas de plafond dédié)
        grip      = true → SetVehicleReduceGrip
        label     = texte notif
    ]]
    surfaces = {
        -- Sable
        [9]  = { traction = 0.45, maxKmh = 55,  grip = true,  label = 'sable' },
        [10] = { traction = 0.55, maxKmh = 65,  grip = true,  label = 'sable' },
        [11] = { traction = 0.40, maxKmh = 45,  grip = true,  label = 'sable mouillé' },
        [12] = { traction = 0.50, maxKmh = 60,  grip = true,  label = 'piste sable' },
        [13] = { traction = 0.30, maxKmh = 35,  grip = true,  label = 'sable' },
        [14] = { traction = 0.28, maxKmh = 30,  grip = true,  label = 'sable profond' },
        [15] = { traction = 0.25, maxKmh = 28,  grip = true,  label = 'sable profond' },
        -- Neige / glace
        [16] = { traction = 0.35, maxKmh = 50,  grip = true,  label = 'glace' },
        [17] = { traction = 0.45, maxKmh = 70,  grip = true,  label = 'verglas' },
        [18] = { traction = 0.40, maxKmh = 50,  grip = true,  label = 'neige' },
        [19] = { traction = 0.50, maxKmh = 60,  grip = true,  label = 'neige' },
        [20] = { traction = 0.30, maxKmh = 35,  grip = true,  label = 'neige profonde' },
        -- Herbe
        [21] = { traction = 0.70, maxKmh = 90,  grip = false, label = 'herbe' },
        [22] = { traction = 0.60, maxKmh = 75,  grip = false, label = 'herbe haute' },
        -- Graviers
        [23] = { traction = 0.65, maxKmh = 80,  grip = false, label = 'gravier' },
        [24] = { traction = 0.55, maxKmh = 70,  grip = false, label = 'gravier' },
        [25] = { traction = 0.45, maxKmh = 55,  grip = true,  label = 'gravier profond' },
        [26] = { traction = 0.60, maxKmh = 75,  grip = false, label = 'gravier' },
        -- Terre / boue / marécage
        [27] = { traction = 0.55, maxKmh = 70,  grip = false, label = 'terre' },
        [28] = { traction = 0.40, maxKmh = 45,  grip = true,  label = 'boue' },
        [29] = { traction = 0.35, maxKmh = 40,  grip = true,  label = 'boue' },
        [30] = { traction = 0.30, maxKmh = 35,  grip = true,  label = 'boue molle' },
        [31] = { traction = 0.25, maxKmh = 30,  grip = true,  label = 'boue' },
        [32] = { traction = 0.22, maxKmh = 25,  grip = true,  label = 'boue profonde' },
        [33] = { traction = 0.28, maxKmh = 30,  grip = true,  label = 'marécage' },
        [34] = { traction = 0.20, maxKmh = 22,  grip = true,  label = 'marécage' },
        [35] = { traction = 0.50, maxKmh = 65,  grip = false, label = 'terre' },
        [36] = { traction = 0.55, maxKmh = 70,  grip = false, label = 'argile' },
        [37] = { traction = 0.35, maxKmh = 40,  grip = true,  label = 'argile molle' },
        -- Divers (sols meubles fréquents)
        [40] = { traction = 0.50, maxKmh = 60,  grip = false, label = 'terrain' },
        [41] = { traction = 0.45, maxKmh = 55,  grip = true,  label = 'terrain' },
        [46] = { traction = 0.40, maxKmh = 50,  grip = true,  label = 'sable' },
        [47] = { traction = 0.35, maxKmh = 40,  grip = true,  label = 'sable' },
        [48] = { traction = 0.45, maxKmh = 55,  grip = true,  label = 'sable' },
    },
}


--[[--------------------------------------------------------------------------
    Météo & heure synchronisées (tous les joueurs)
---------------------------------------------------------------------------]]
Config.Weather = {
    enabled = true,
    -- Changer la météo automatiquement
    dynamic = true,
    -- Intervalle entre changements (minutes réelles)
    changeMinutes = 20,
    -- Transition douce (secondes côté client)
    transitionSeconds = 45.0,
    -- Météo de départ (nil = tirage aléatoire)
    startWeather = 'CLEAR',
    -- Blackout (lumières ville)
    blackout = false,
    -- Notifier les joueurs au changement
    notifyPlayers = false,
    -- Permissions qbx_core / ACE (HasPermission + group.<name>)
    adminGroups = { admin = true, god = true },
    -- Pondération des types (plus haut = plus fréquent)
    types = {
        CLEAR = 25,
        EXTRASUNNY = 20,
        CLOUDS = 15,
        OVERCAST = 10,
        FOGGY = 6,
        CLEARING = 5,
        RAIN = 8,
        THUNDER = 4,
        SMOG = 3,
        NEUTRAL = 2,
        SNOW = 1,
        BLIZZARD = 0,
        SNOWLIGHT = 1,
        XMAS = 0,
        HALLOWEEN = 0,
    },
}

Config.Time = {
    enabled = true,
    -- Heure de départ
    hour = 12,
    minute = 0,
    -- Secondes réelles pour avancer d'1 minute in-game (2 ≈ journée en ~48 min)
    realSecondsPerGameMinute = 2,
    -- Geler l'heure (événements)
    freeze = false,
    -- Sync périodique forcée (ms)
    syncInterval = 30000,
}

--[[--------------------------------------------------------------------------
    Logs Discord — tous les événements serveur
    Mets ton/tes webhook(s) ci-dessous (URL complète).
    Tu peux utiliser 1 seul webhook pour tout (default), ou un par catégorie.
---------------------------------------------------------------------------]]
Config.Discord = {
    enabled = true,
    -- Nom affiché + avatar bot Discord
    botName = 'VIBE QBox Logs',
    botAvatar = '', -- URL optionnelle
    -- Webhook par défaut (utilisé si une catégorie n'a pas le sien)
    defaultWebhook = '', -- EX: 'https://discord.com/api/webhooks/ID/TOKEN'
    -- Couleurs embed (décimal)
    colors = {
        info = 5793266,      -- bleu
        success = 5763719,   -- vert
        warning = 16705372,  -- jaune
        error = 15548997,    -- rouge
        money = 15844367,    -- or
        admin = 10181046,    -- violet
    },
    -- Catégories : enabled + webhook optionnel (sinon defaultWebhook)
    categories = {
        connect     = { enabled = true, webhook = '' }, -- connexions / déconnexions
        chat        = { enabled = true, webhook = '' }, -- messages chat
        death       = { enabled = true, webhook = '' }, -- morts / kills
        explosion   = { enabled = true, webhook = '' }, -- explosions
        admin       = { enabled = true, webhook = '' }, -- commandes admin (/weather, /time…)
        vehicles    = { enabled = true, webhook = '' }, -- fourrière, bâche, occasions, garage
        keys        = { enabled = true, webhook = '' }, -- clés / serrurier
        money       = { enabled = true, webhook = '' }, -- achats clés / occasions
        weather     = { enabled = true, webhook = '' }, -- météo / heure
        resources   = { enabled = true, webhook = '' }, -- start/stop resources
        system      = { enabled = true, webhook = '' }, -- boot, erreurs core
    },
    -- File d'attente (évite le rate-limit Discord)
    queueDelay = 750, -- ms entre chaque envoi
    -- Inclure IDs (license, discord, steam…)
    showIdentifiers = true,
}

--[[--------------------------------------------------------------------------
    Réseau téléphone — antennes à déployer
    Sans couverture : pas d'appels, SMS, ni réseaux sociaux.
---------------------------------------------------------------------------]]
Config.Network = {
    enabled = true,
    -- Item pour déployer une antenne
    antennaItem = 'phone_antenna',
    -- Prop antenne
    prop = 'prop_mast_01',
    fallbackProp = 'prop_telegraph_01a',
    -- Portée (mètres) et niveaux de signal
    range = 180.0,          -- distance max pour un signal faible
    goodRange = 90.0,       -- signal fort
    -- Durée pose / retrait (ms)
    deployProgress = 8000,
    removeProgress = 6000,
    -- Seul le poseur (ou job) peut retirer
    removeJobs = { ['police'] = 0, ['mechanic'] = 0 }, -- grades min ; proprio toujours OK
    -- Max antennes par joueur (0 = illimité)
    maxPerPlayer = 3,
    -- Afficher barre de signal (HUD simple)
    showSignalHud = true,
    -- Intervalle check client (ms)
    checkInterval = 1000,
    -- Blips antennes (pour tous / seulement si signal)
    blip = { enabled = true, sprite = 459, color = 3, scale = 0.65, shortRange = true },
    -- Antennes fixes permanentes (ville) — laisse {} pour forcer le déploiement joueur
    staticAntennas = {
        -- Exemples (décommente pour couverture de base) :
        -- { coords = vec3(215.0, -810.0, 30.7), range = 220.0, label = 'Antenne Legion' },
        -- { coords = vec3(-265.0, -963.0, 31.2), range = 220.0, label = 'Antenne Mairie' },
        -- { coords = vec3(1850.0, 3683.0, 34.2), range = 250.0, label = 'Antenne Sandy' },
        -- { coords = vec3(-448.0, 6010.0, 31.7), range = 250.0, label = 'Antenne Paleto' },
    },
    -- Ponts téléphone (désactive appels/SMS/social sans signal)
    phones = {
        npwd = true,           -- exports.npwd:setPhoneDisabled
        lbphone = true,        -- lb-phone
        gksphone = true,
        qsmartphone = true,    -- qs-smartphone / qs-smartphone-pro
        notifyOnBlock = true,  -- notif si tentative sans réseau
    },
}
