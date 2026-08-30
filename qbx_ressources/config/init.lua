Config = {}

Config.Locale = 'fr'

--[[--------------------------------------------------------------------------
    Modules — active / désactive chaque sous-système
---------------------------------------------------------------------------]]
Config.Modules = {
    core = true,       -- véhicules, clés, météo, réseau, discord, etc.
    duty = true,       -- prise de service + blips entreprises
    sleeping = true,   -- corps endormis à la déconnexion
}
