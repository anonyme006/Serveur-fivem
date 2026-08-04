Config = {}

-- Détection auto si 'auto' (esx | qbcore)
Config.Framework = 'auto'

-- Compte de paiement: 'money' (cash ESX) ou 'bank'
Config.PayAccount = 'money'

-- Cooldown entre deux missions du même métier (secondes)
Config.MissionCooldown = 5

-- =============================================================================
-- PÔLE EMPLOI (agence)
-- =============================================================================
Config.PoleEmploi = {
    blip = {
        enabled = true,
        coords = vector3(-265.0, -963.6, 31.2),
        sprite = 407,
        color = 3,
        scale = 0.85,
        label = 'Pôle Emploi',
    },
    ped = {
        enabled = true,
        model = 'a_f_y_business_01',
        coords = vector4(-265.08, -964.15, 31.22, 205.0),
        scenario = 'WORLD_HUMAN_CLIPBOARD',
    },
    -- Zone ox_target (utilisée aussi si ped désactivé)
    target = {
        coords = vector3(-265.08, -964.15, 31.22),
        radius = 1.8,
        label = 'Parler à Pôle Emploi',
        icon = 'fas fa-briefcase',
    },
    slogan = 'Changez votre avenir avec nous !',
    confirmLabel = 'Choisir ce nouveau métier',
}

-- =============================================================================
-- JOBS INTÉRIM
-- locked = true → cadenas dans le menu (débloquable via Config.Unlock)
-- =============================================================================
Config.Jobs = {
    {
        id = 'electricien',
        label = 'Electricien',
        description = 'Réparez les boîtiers électriques défectueux dans la ville.',
        locked = false,
        icon = 'bolt',
        vehicle = 'utillitruck3',
        vehicleSpawn = vector4(-279.2, -903.5, 31.1, 340.0),
        depot = vector3(-279.2, -903.5, 31.1),
        pay = { min = 180, max = 280 },
        stopsPerRun = { min = 4, max = 6 },
        workDuration = 8000,
        workLabel = 'Réparer le boîtier électrique',
        workAnim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer' },
        blipSprite = 354,
        blipColor = 5,
        locations = {
            vector3(119.3, -1036.2, 29.3),
            vector3(213.5, -809.2, 30.7),
            vector3(-47.5, -1112.8, 26.4),
            vector3(372.8, -1003.5, 29.3),
            vector3(-712.4, -1298.6, 5.4),
            vector3(1151.2, -457.8, 66.9),
            vector3(-1205.3, -899.4, 13.0),
            vector3(808.6, -2159.4, 29.6),
            vector3(-324.2, -1356.8, 31.3),
            vector3(255.1, -305.5, 49.7),
        },
    },
    {
        id = 'eboueur',
        label = 'Éboueur',
        description = 'Collectez les ordures dans les quartiers puis déposez-les à la déchetterie.',
        locked = false,
        icon = 'trash',
        vehicle = 'trash',
        vehicleSpawn = vector4(-350.5, -1568.2, 25.2, 270.0),
        depot = vector3(-350.5, -1568.2, 25.2),
        landfill = vector3(-352.2, -1545.8, 27.7),
        pay = { min = 150, max = 240 },
        stopsPerRun = { min = 5, max = 8 },
        workDuration = 6000,
        workLabel = 'Ramasser les ordures',
        workAnim = { dict = 'anim@move_m@trash', clip = 'pickup' },
        dumpDuration = 7000,
        dumpLabel = 'Décharger les ordures',
        blipSprite = 318,
        blipColor = 2,
        locations = {
            vector3(114.8, -1961.2, 20.9),
            vector3(-12.5, -1434.6, 30.6),
            vector3(295.4, -1448.9, 29.9),
            vector3(428.6, -984.2, 30.7),
            vector3(-561.3, -872.4, 25.3),
            vector3(1224.5, -1389.8, 35.1),
            vector3(-1287.4, -1117.2, 6.9),
            vector3(85.2, -195.5, 54.5),
            vector3(-1037.8, -2737.9, 20.2),
            vector3(1695.4, 4785.2, 41.9),
        },
    },
    {
        id = 'plombier',
        label = 'Plombier',
        description = 'Intervenez chez les particuliers pour réparer fuites et canalisations.',
        locked = false,
        icon = 'wrench',
        vehicle = 'burrito3',
        vehicleSpawn = vector4(724.5, -2022.8, 29.3, 265.0),
        depot = vector3(724.5, -2022.8, 29.3),
        pay = { min = 200, max = 320 },
        stopsPerRun = { min = 3, max = 5 },
        workDuration = 10000,
        workLabel = 'Réparer la plomberie',
        workAnim = { dict = 'mini@repair', clip = 'fixing_a_player' },
        blipSprite = 402,
        blipColor = 3,
        locations = {
            vector3(-174.2, -1538.4, 34.3),
            vector3(312.8, -205.6, 54.1),
            vector3(-1150.4, -1425.6, 4.9),
            vector3(967.5, -143.2, 74.3),
            vector3(-814.6, 178.2, 72.2),
            vector3(1274.2, -1721.5, 54.7),
            vector3(-447.5, 6016.2, 31.7),
            vector3(1961.2, 3740.5, 32.3),
            vector3(-32.8, -1446.5, 31.9),
            vector3(346.5, -998.2, 29.3),
        },
    },
    {
        id = 'mineur',
        label = 'Joaillier',
        description = 'Extrayez des minerais précieux à la carrière puis vendez-les à la joaillerie.',
        locked = false,
        icon = 'gem',
        -- Sous-titre affiché (mineur → joaillerie)
        subtitle = 'Mineur',
        vehicle = 'tiptruck2',
        vehicleSpawn = vector4(2831.5, 2799.8, 57.4, 100.0),
        depot = vector3(2831.5, 2799.8, 57.4),
        sellPoint = vector3(-629.2, -236.5, 38.1),
        pay = { min = 220, max = 380 },
        -- Paiement par minerai vendu
        orePay = { min = 90, max = 160 },
        stopsPerRun = { min = 4, max = 7 },
        workDuration = 9000,
        workLabel = 'Extraire le minerai',
        workAnim = { dict = 'melee@large_wpn@streamed_core', clip = 'ground_attack_on_spot' },
        sellDuration = 5000,
        sellLabel = 'Vendre les minerais',
        maxCarry = 8,
        blipSprite = 618,
        blipColor = 46,
        locations = {
            vector3(2953.2, 2787.8, 41.5),
            vector3(2976.5, 2792.1, 40.4),
            vector3(2937.8, 2771.5, 39.2),
            vector3(2926.4, 2792.8, 41.0),
            vector3(2946.1, 2817.4, 42.5),
            vector3(2981.8, 2755.2, 43.1),
            vector3(3002.5, 2772.8, 43.5),
            vector3(2899.4, 2783.2, 35.8),
        },
    },
    {
        id = 'livreur',
        label = 'Livreur de Journaux',
        description = 'Livrez le journal du matin dans les boîtes aux lettres du quartier.',
        locked = false,
        icon = 'newspaper',
        vehicle = 'faggio',
        vehicleSpawn = vector4(-537.8, -886.4, 25.2, 180.0),
        depot = vector3(-537.8, -886.4, 25.2),
        pay = { min = 80, max = 140 },
        stopsPerRun = { min = 6, max = 10 },
        workDuration = 4000,
        workLabel = 'Déposer le journal',
        workAnim = { dict = 'mp_common', clip = 'givetake1_a' },
        blipSprite = 501,
        blipColor = 0,
        locations = {
            vector3(-46.8, -1445.5, 32.4),
            vector3(120.5, -1937.2, 20.8),
            vector3(338.6, -2042.5, 21.3),
            vector3(256.4, -1696.8, 29.1),
            vector3(-148.2, -1687.5, 33.1),
            vector3(472.8, -1775.2, 28.7),
            vector3(-217.5, -1618.4, 34.9),
            vector3(128.8, -1855.6, 25.2),
            vector3(-821.5, -1225.8, 7.3),
            vector3(374.2, -1791.5, 29.1),
            vector3(-1104.2, -1528.5, 4.5),
            vector3(16.5, -1446.8, 30.9),
        },
    },
}

-- =============================================================================
-- DÉBLOCAGE (optionnel)
-- Si un job est locked = true, il se débloque après X missions complétées
-- sur n'importe quel métier intérim (suivi serveur).
-- =============================================================================
Config.Unlock = {
    -- [jobId] = missions requises
    -- mineur = 10,
    -- joaillier utilise id 'mineur'
}

-- Quitter le métier intérim remet ce job ESX
Config.DefaultJob = {
    name = 'unemployed',
    grade = 0,
}

-- Distance max anti-cheat pour valider une action
Config.InteractDistance = 4.0
