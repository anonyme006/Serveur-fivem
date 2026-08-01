Config = {}

-- =============================================================================
-- GÉNÉRAL
-- =============================================================================

--- Afficher les blips des radars sur la carte
Config.ShowBlips = false

--- Tolérance de vitesse par défaut (km/h) — le flash démarre à limite + tolérance + 1
Config.Tolerance = 5

--- Effet flash blanc à l'écran
Config.CameraFlash = true

--- Son d'appareil photo lors du flash
Config.CameraSound = true

--- Amende par défaut (fallback)
Config.DefaultFine = 150

--- Métiers exemptés d'amende (véhicule autorisé)
Config.AllowedJobs = {
    'police',
    'ambulance',
    'sheriff',
    'fib',
    'government',
}

-- =============================================================================
-- PERMISSIONS ADMIN
-- =============================================================================

--- Groupes ESX autorisés à créer / supprimer / gérer les radars
Config.AdminGroups = {
    'admin',
    'superadmin',
}

--- Ou ACE permission (ex: radar.admin). Laisser vide pour n'utiliser que les groupes.
Config.AdminAce = 'radar.admin'

-- =============================================================================
-- COMMANDES
-- =============================================================================

Config.Commands = {
    create = 'createradar',
    delete = 'deleteradar',
    manage = 'radars',
}

-- =============================================================================
-- DÉTECTION & PERFORMANCE
-- =============================================================================

--- Distance max (m) pour commencer à surveiller un radar (au-delà = sleep long)
Config.MaxCheckDistance = 80.0

--- Cooldown (ms) avant de re-flasher le même véhicule sur le même radar
Config.FlashCooldown = 15000

--- Intervalle de veille (ms) quand le joueur n'est pas conducteur / loin des radars
Config.IdleWait = 1500

--- Intervalle (ms) quand un radar est à proximité
Config.NearWait = 100

--- Intervalle (ms) dans la zone de détection
Config.ActiveWait = 50

--- Angle max (degrés) pour considérer qu'un véhicule passe « devant » le radar
Config.FrontAngle = 55.0

--- Prop affiché à la position du radar (nil = aucun prop)
Config.RadarProp = 'prop_cctv_pole_01'

--- Offset Z du prop par rapport au sol
Config.RadarPropZOffset = 0.0

-- =============================================================================
-- LIMITATIONS DE VITESSE DISPONIBLES (km/h)
-- =============================================================================

Config.SpeedLimits = { 30, 50, 70, 80, 90, 110, 130, 160 }

-- =============================================================================
-- TOLÉRANCES DISPONIBLES DANS LE MENU (km/h)
-- =============================================================================

Config.ToleranceOptions = { 0, 3, 5, 7, 10, 15 }

-- =============================================================================
-- DISTANCES DE DÉTECTION DISPONIBLES (m)
-- =============================================================================

Config.DetectionDistances = { 10.0, 15.0, 20.0, 25.0, 30.0, 40.0, 50.0 }

-- =============================================================================
-- SENS DU RADAR
-- =============================================================================

--- both = les deux sens | forward = sens aller | backward = sens retour
Config.Directions = {
    { value = 'both',     label = 'Les deux sens' },
    { value = 'forward',  label = 'Sens aller' },
    { value = 'backward', label = 'Sens retour' },
}

-- =============================================================================
-- BARÈME D'AMENDES ($)
-- =============================================================================

--- Excès = vitesse_retenue - limitation
--- Palier 1 : excess < maxExcess (20) → 150 $
--- Palier 2 : 20 ≤ excess ≤ maxExcess (50) → 350 $
--- Palier 3 : excess > 50 → 750 $
Config.Fines = {
    { maxExcess = 20,  amount = 150 },
    { maxExcess = 50,  amount = 350 },
    { maxExcess = 999, amount = 750 },
}

-- =============================================================================
-- NOTIFICATION FLASH
-- =============================================================================

Config.Notify = {
    title = '911 Emergency',
    subtitle = 'Radar automatique',
    flashed = 'Votre véhicule vient d\'être flashé',
    authorized = 'Véhicule autorisé',
    duration = 8000,
}

-- =============================================================================
-- BLIP
-- =============================================================================

Config.Blip = {
    sprite = 184,
    color = 1,
    scale = 0.65,
    shortRange = true,
    label = 'Radar',
}

-- =============================================================================
-- OX_TARGET (interaction admin sur le prop)
-- =============================================================================

Config.UseOxTarget = true
Config.TargetDistance = 2.5

-- =============================================================================
-- SÉCURITÉ
-- =============================================================================

--- Vitesse max plausible (km/h) — au-delà le flash serveur est rejeté
Config.MaxPlausibleSpeed = 400

--- Distance max (m) joueur ↔ radar pour accepter un flash côté serveur
Config.MaxFlashDistance = 80.0
