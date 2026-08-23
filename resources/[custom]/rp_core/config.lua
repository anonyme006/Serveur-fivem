Config = {}

Config.Debug = false
Config.Framework = 'qbox'
Config.Inventory = 'ox_inventory'
Config.Target = 'ox_target'
Config.Notify = 'ox_lib'
Config.Locale = 'fr'
Config.DiscordLogs = true

--- Identité serveur (style cinéma / streamer)
Config.Brand = {
    name = 'Cinéma LS',
    tagline = 'Écris ton histoire à Los Santos',
    --- Accent cinéma : ambre chaud, pas violet
    colors = {
        bg = '#0a0b0d',
        panel = '#12141a',
        text = '#f4efe6',
        muted = '#9a9388',
        accent = '#c4a574',
        danger = '#c45c5c',
        success = '#6f9f7a',
    },
}

--- Banque : renewed = Renewed-Banking | native = money bank Qbox
Config.Banking = 'renewed'

--- Téléphone premium recommandé : lb-phone
Config.Phone = 'lb-phone'

--- Activer la couche UI cinéma (stoppez qbx_hud si true)
Config.UseCustomHud = true

--- Garages : garder qbx_garages par défaut (qualité déjà bonne)
Config.UseCustomGarages = false

Config.UseCustomAdmin = true

Config.AutoSaveInterval = 10

Config.RequiredResources = {
    'oxmysql',
    'ox_lib',
    'qbx_core',
    'ox_inventory',
    'ox_target',
}

Config.NotifyDefaults = {
    duration = 4500,
    position = 'top-right',
}
