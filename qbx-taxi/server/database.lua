-- Base de données — Étape 15

TaxiDatabase = TaxiDatabase or {}

local function runMigrations()
    if not Config.SQL.autoRun then return end

    Taxi.Debug('SQL autoRun activé — migration prévue à l\'étape 15')
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= Taxi.GetResourceName() then return end
    runMigrations()
end)
