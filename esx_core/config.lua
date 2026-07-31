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
    -- Donner automatiquement les clés
    giveOnGarageTakeOut = true, -- pa_garage / ox_garage (sortie + fourrière)
    giveOnPurchase = true,      -- esx_concessionnaire (+ hooks génériques)
    notifyOnGive = true,        -- notification « clés reçues »
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
Config.Alerts = {
    fuel = {
        enabled = true,
        -- Seuil (%)
        threshold = 15,
        -- Cooldown entre alertes (ms)
        cooldown = 90000,
        -- Ressource carburant : 'auto' | 'ox_fuel' | 'LegacyFuel' | 'native'
        resource = 'auto',
    },
    needs = {
        enabled = true,
        -- Seuil (valeur esx_status typique 0–1000000, on normalise en %)
        hungerThreshold = 20,
        thirstThreshold = 20,
        cooldown = 120000,
        -- Noms des status esx_status
        hunger = 'hunger',
        thirst = 'thirst',
    },
}
