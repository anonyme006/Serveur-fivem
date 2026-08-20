Config = {}

Config.Debug = false

-- ox_target sur les corps (admin + info)
Config.UseOxTarget = true

-- Afficher « 💤 Prénom Nom — Déconnecté » au-dessus du corps
Config.ShowName = true
Config.NameDistance = 10.0

-- Corrections de placement
Config.ZOffset = 0.0
Config.RotationOffset = 0.0

-- Supprimer le corps SQL + ped à la reconnexion
Config.DeleteOnReconnect = true

-- Restaurer les corps depuis MySQL au démarrage ressource
Config.LoadBodiesOnResourceStart = true

-- Animation allongé / dort
Config.SleepAnimation = {
    dict = 'timetable@tracy@sleep@',
    anim = 'idle_c',
    flag = 1, -- loop
}

-- Fallback si le dict principal échoue
Config.SleepAnimationFallback = {
    dict = 'amb@world_human_bum_slumped@male@laying_on_right_side@base',
    anim = 'base',
    flag = 1,
}

-- Apparence : 'auto' | 'illenium-appearance' | 'fivem-appearance' | 'qb-clothing' | 'none'
Config.AppearanceSystem = 'auto'

-- Groupes / permissions QBox pour /sleepingbodies
Config.AdminGroups = {
    'admin',
    'god',
}

-- Ace permission alternative (en plus des groupes)
Config.AdminAce = 'qbx_sleeping_bodies.admin'

-- Intervalle client : cache position/apparence vers le serveur (ms)
Config.ClientCacheInterval = 15000

-- Validation anti-cheat : distance max entre dernière cache et ped au drop (m)
Config.MaxDropDistanceDelta = 80.0

-- Prop / scénario : laisser false (animation ped)
Config.UseScenario = false
Config.Scenario = 'WORLD_HUMAN_BUM_SLUMPED'

-- Couleur texte 3D
Config.NameColor = { r = 180, g = 210, b = 255, a = 220 }
