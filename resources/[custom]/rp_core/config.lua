Config = {}

Config.Debug = false
Config.Framework = 'qbox'
Config.Inventory = 'ox_inventory'
Config.Target = 'ox_target'
Config.Notify = 'ox_lib'
Config.Locale = 'fr'
Config.DiscordLogs = true

--- Banque : renewed = Renewed-Banking (recette Qbox) | native = money bank Qbox
Config.Banking = 'renewed'

--- Téléphone : npwd | lb-phone | sd-phone | none
Config.Phone = 'npwd'

--- HUD custom (rp_hud). Si true, arrêtez qbx_hud dans server.cfg
Config.UseCustomHud = false

--- Garages custom (rp_garages). Si true, arrêtez qbx_garages
Config.UseCustomGarages = false

--- Admin custom (rp_admin) en plus ou à la place de qbx_adminmenu
Config.UseCustomAdmin = true

Config.AutoSaveInterval = 10 -- minutes (relais info ; qbx_core gère la sauvegarde native)

Config.RequiredResources = {
    'oxmysql',
    'ox_lib',
    'qbx_core',
    'ox_inventory',
    'ox_target',
}

Config.NotifyDefaults = {
    duration = 5000,
    position = 'top-right',
}
