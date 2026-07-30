Config = {}

-- Unités de vitesse : 'kmh' ou 'mph'
Config.SpeedUnit = 'kmh'

-- Afficher le compteur véhicule uniquement en véhicule
Config.ShowVehicleHud = true

-- Cacher le radar GTA par défaut (minimap)
Config.HideRadar = false

-- Intervalle de mise à jour du HUD véhicule (ms) — plus bas = plus fluide
Config.VehicleUpdateMs = 50

-- Intervalle de mise à jour santé / faim / soif (ms)
Config.StatusUpdateMs = 200

-- Noms des status esx_status (adapter si votre serveur utilise d'autres noms)
Config.Status = {
    hunger = 'hunger',
    thirst = 'thirst',
}

-- Remonter la minimap pour laisser la place aux barres en dessous
Config.OffsetMinimap = true
-- Décalage vertical de la minimap (plus grand = plus haut)
Config.MinimapOffsetY = 0.028

-- Commandes
Config.EditCommand = 'edithud'   -- /edithud → déplacer le HUD à la souris
Config.ResetCommand = 'resethud' -- /resethud → positions par défaut

-- Positions par défaut (pourcentages de l'écran : left / top)
-- Utilisées si le joueur n'a pas encore déplacé le HUD
Config.DefaultPositions = {
    status = { left = 1.55, top = 97.6 },
    vehicle = { left = 42.0, top = 82.0 },
}
