Config = {}

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
    -- Colonnes owned_vehicles (compat pa_garage / esx_vehicleshop)
    columns = {
        table = 'owned_vehicles',
        owner = 'owner',
        plate = 'plate',
        vehicle = 'vehicle',
        stored = 'stored',
        parking = 'parking',
        pound = 'pound',
        type = 'type',
    },
}

--[[--------------------------------------------------------------------------
    Fourrière automatique au reboot
    Les véhicules sortis (stored = 0) sont envoyés en fourrière au démarrage.
---------------------------------------------------------------------------]]
Config.AutoImpound = {
    enabled = true,
    -- Id fourrière (doit correspondre à pa_garage Config.Impounds si présent)
    impoundId = 'impound_public',
    -- Aussi écrire la colonne pound
    setPoundColumn = true,
    -- Message console
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
    giveOnPurchase = true,      -- esx_concessionnaire (+ hooks génériques)
    notifyOnGive = true,        -- notification « clés reçues »

    --[[ Inventaire : la clé devient un item (ox_inventory ou ESX) ]]
    inventory = {
        enabled = true,
        item = 'vehicle_key',
        -- À l'achat du véhicule → ajoute l'item dans l'inventaire
        giveItemOnPurchase = true,
        -- À la sortie garage : si le proprio n'a plus l'item, le redonner (false = doit racheter au serrurier)
        giveMissingOnGarage = false,
        -- Verrouillage : exiger l'item (ou une clé DB temporaire). false = proprio owned_vehicles suffit
        requireItemToLock = true,
        -- Inventaire cible : 'auto' | 'ox' | 'esx'
        system = 'auto',
    },
}

--[[--------------------------------------------------------------------------
    Serrurier — racheter / dupliquer une clé de véhicule owned
---------------------------------------------------------------------------]]
Config.KeyShop = {
    enabled = true,
    label = 'Serrurier',
    price = 750,
    account = 'bank', -- 'bank' | 'money'
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
    -- Commande / touche (F4 par défaut)
    command = 'portefeuille',
    key = 'F4',
    -- Comptes ESX affichés
    accounts = { 'money', 'bank' },
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
    Alertes essence / faim / soif
---------------------------------------------------------------------------]]
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
    -- Groupes ESX autorisés pour /weather /time /blackout
    adminGroups = { admin = true, superadmin = true, god = true },
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
