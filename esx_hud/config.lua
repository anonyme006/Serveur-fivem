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

-- Position des barres de status (CSS)
Config.StatusPosition = {
    bottom = '2.8%',
    left = '1.6%',
}

-- Position du speedometer (centré en bas)
Config.VehiclePosition = {
    bottom = '3.5%',
}
