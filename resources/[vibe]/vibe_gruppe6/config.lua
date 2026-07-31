Config = {}

Config.Job = 'gruppe6'
Config.Society = 'gruppe6'
Config.RequireDuty = true

Config.Depot = {
    label = 'Gruppe 6 — Dépôt',
    coords = vec3(-141.2, -620.8, 168.8),
    radius = 2.0,
}

Config.Vehicle = 'stockade'
Config.Spawn = vec4(-129.5, -633.0, 168.8, 100.0)

Config.Route = {
    minStops = 3,
    maxStops = 6,
}

Config.Cooldown = 300 -- secondes entre deux tournées

Config.BagItem = 'money_bag'

Config.PayByType = {
    banque = { min = 1200, max = 2000 },
    armurerie = { min = 800, max = 1400 },
    magasin = { min = 400, max = 800 },
    grossiste = { min = 600, max = 1000 },
}

Config.TypeLabels = {
    banque = 'Banque',
    armurerie = 'Armurerie',
    magasin = 'Magasin',
    grossiste = 'Grossiste',
}

Config.Pickup = {
    duration = 7000,
    radius = 3.0,
    label = 'Récupérer le sac de billets',
}

Config.Deposit = {
    duration = 10000,
    label = 'Déposer les fonds au dépôt',
}

--- Points par défaut (seed en base au premier démarrage)
Config.DefaultPoints = {
    -- Banques
    { type = 'banque', label = 'Fleeca Legion', coords = vec3(149.46, -1040.09, 29.37) },
    { type = 'banque', label = 'Fleeca Alta', coords = vec3(313.84, -280.58, 54.16) },
    { type = 'banque', label = 'Fleeca Del Perro', coords = vec3(-1211.9, -331.9, 37.78) },
    { type = 'banque', label = 'Fleeca Burton', coords = vec3(-351.23, -51.28, 49.04) },
    { type = 'banque', label = 'Fleeca Great Ocean', coords = vec3(-2961.14, 483.09, 15.7) },
    { type = 'banque', label = 'Fleeca Route 68', coords = vec3(1174.8, 2708.2, 38.09) },
    { type = 'banque', label = 'Banque Paleto', coords = vec3(-112.22, 6471.01, 31.63) },

    -- Magasins (247)
    { type = 'magasin', label = '247 Innocence', coords = vec3(25.7, -1347.3, 29.49) },
    { type = 'magasin', label = '247 Chumash', coords = vec3(-3038.71, 585.9, 7.9) },
    { type = 'magasin', label = '247 Great Ocean', coords = vec3(-3241.47, 1001.14, 12.83) },
    { type = 'magasin', label = '247 Paleto', coords = vec3(1728.66, 6414.16, 35.03) },
    { type = 'magasin', label = '247 Grapeseed', coords = vec3(1697.99, 4924.4, 42.06) },
    { type = 'magasin', label = '247 Sandy', coords = vec3(1961.48, 3739.96, 32.34) },
    { type = 'magasin', label = '247 Route 68', coords = vec3(547.79, 2671.79, 42.15) },
    { type = 'magasin', label = '247 Senora', coords = vec3(2679.25, 3280.12, 55.24) },
    { type = 'magasin', label = '247 Tataviam', coords = vec3(2557.94, 382.05, 108.62) },
    { type = 'magasin', label = '247 Clinton', coords = vec3(373.55, 325.56, 103.56) },

    -- Armureries
    { type = 'armurerie', label = 'Ammu-Nation Morningwood', coords = vec3(-662.18, -934.96, 21.83) },
    { type = 'armurerie', label = 'Ammu-Nation Cypress', coords = vec3(810.25, -2157.60, 29.62) },
    { type = 'armurerie', label = 'Ammu-Nation Sandy', coords = vec3(1693.44, 3760.16, 34.71) },
    { type = 'armurerie', label = 'Ammu-Nation Paleto', coords = vec3(-330.24, 6083.88, 31.45) },
    { type = 'armurerie', label = 'Ammu-Nation Hawick', coords = vec3(252.63, -50.00, 69.94) },
    { type = 'armurerie', label = 'Ammu-Nation Pillbox', coords = vec3(22.56, -1109.89, 29.80) },
    { type = 'armurerie', label = 'Ammu-Nation Tataviam', coords = vec3(2567.69, 294.38, 108.73) },
    { type = 'armurerie', label = 'Ammu-Nation Route 68', coords = vec3(-1117.58, 2698.61, 18.55) },
    { type = 'armurerie', label = 'Ammu-Nation La Mesa', coords = vec3(842.44, -1033.42, 28.19) },

    -- Grossistes
    { type = 'grossiste', label = 'YouTool Senora', coords = vec3(2748.0, 3473.0, 55.67) },
    { type = 'grossiste', label = 'YouTool Davis', coords = vec3(342.99, -1298.26, 32.51) },
    { type = 'grossiste', label = 'Entrepôt Davis', coords = vec3(46.5, -1749.5, 29.6) },
    { type = 'grossiste', label = 'Entrepôt Docks', coords = vec3(1209.6, -3114.8, 5.5) },
}
