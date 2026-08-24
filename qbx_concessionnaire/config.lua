Config = {}

Config.Locale = 'fr'

--[[
    Marqueurs plats au sol (comme sur la photo)
    type 25 = disque
    rouge = ouvrir le menu
    vert  = place de livraison / spawn après achat
]]
Config.Markers = {
    menu = {
        type = 25,
        size = vector3(2.2, 2.2, 0.15),
        color = { r = 220, g = 40, b = 40, a = 140 },
    },
    park = {
        type = 25,
        size = vector3(2.6, 2.6, 0.15),
        color = { r = 40, g = 220, b = 80, a = 140 },
    },
}

Config.Zones = {
    {
        name = 'pdm',
        label = 'Concessionnaire PDM',
        blip = {
            enabled = true,
            sprite = 326,
            colour = 5,
            scale = 0.85,
            label = 'Concessionnaire',
        },
        -- Point rouge (ouvrir le menu)
        menu = vector3(-45.56, -1097.97, 26.42),
        drawDistance = 35.0,
        interactDistance = 1.8,
        -- Preview showroom
        preview = {
            coords = vector3(-44.20, -1097.10, 26.42),
            heading = 70.0,
            camera = {
                offset = vector3(-4.8, -3.6, 1.6),
                fov = 50.0,
            },
        },
        -- Points verts (livraison après achat)
        parks = {
            vector4(-31.15, -1090.72, 26.42, 340.0),
            vector4(-33.80, -1091.60, 26.42, 340.0),
            vector4(-36.40, -1092.50, 26.42, 340.0),
        },
    },
}

-- Compat anciens noms Config.Preview / PurchaseSpawn (premier zone)
Config.Preview = Config.Zones[1].preview
Config.PurchaseSpawn = {
    coords = vector3(Config.Zones[1].parks[1].x, Config.Zones[1].parks[1].y, Config.Zones[1].parks[1].z),
    heading = Config.Zones[1].parks[1].w,
}

-- Paiement : 'bank' | 'cash' | 'both' (alias 'money' = cash)
Config.PaymentAccount = 'both'
Config.DefaultGarage = 'pillbox'
Config.PurchaseState = 0 -- 0 sorti | 1 garage
Config.PlatePrefix = 'VIBE'
Config.PlateDigits = 4
Config.CloseWithEscape = true

Config.Categories = {
    { id = 'compacts', label = 'Compacts' },
    { id = 'sedans', label = 'Sedans' },
    { id = 'coupes', label = 'Coupes' },
    { id = 'muscle', label = 'Muscle' },
    { id = 'suvs', label = 'Suv' },
    { id = 'sportsclassics', label = 'Sports Classics' },
    { id = 'sports', label = 'Sports' },
    { id = 'super', label = 'Super' },
    { id = 'motorcycles', label = 'Motos' },
    { id = 'offroad', label = 'Off-Road' },
    { id = 'vans', label = 'Vans' },
}
Config.Vehicles = {
    -- Compacts
    { model = 'brioso2', name = 'Brioso 300', category = 'compacts', price = 21340 },
    { model = 'issi3', name = 'Issi Classic', category = 'compacts', price = 7670 },
    { model = 'asbo', name = 'Asbo', category = 'compacts', price = 8500 },
    { model = 'blista', name = 'Blista', category = 'compacts', price = 9500 },
    { model = 'dilettante', name = 'Dilettante', category = 'compacts', price = 7200 },
    { model = 'kanjo', name = 'Blista Kanjo', category = 'compacts', price = 14500 },
    { model = 'panto', name = 'Panto', category = 'compacts', price = 4800 },
    { model = 'prairie', name = 'Prairie', category = 'compacts', price = 11000 },
    { model = 'rhapsody', name = 'Rhapsody', category = 'compacts', price = 6200 },
    { model = 'club', name = 'Club', category = 'compacts', price = 12800 },
    { model = 'weevil', name = 'Weevil', category = 'compacts', price = 9800 },
    { model = 'brioso', name = 'Brioso R/A', category = 'compacts', price = 16500 },

    -- Sedans
    { model = 'asea', name = 'Asea', category = 'sedans', price = 6500 },
    { model = 'asterope', name = 'Asterope', category = 'sedans', price = 9200 },
    { model = 'cinquemila', name = 'Lampadati Cinquemila', category = 'sedans', price = 85000 },
    { model = 'cog55', name = 'Cognoscenti 55', category = 'sedans', price = 52000 },
    { model = 'cognoscenti', name = 'Cognoscenti', category = 'sedans', price = 61000 },
    { model = 'emperor', name = 'Emperor', category = 'sedans', price = 5400 },
    { model = 'fugitive', name = 'Fugitive', category = 'sedans', price = 18500 },
    { model = 'glendale', name = 'Glendale', category = 'sedans', price = 7800 },
    { model = 'ingot', name = 'Ingot', category = 'sedans', price = 4200 },
    { model = 'intruder', name = 'Intruder', category = 'sedans', price = 8900 },
    { model = 'premier', name = 'Premier', category = 'sedans', price = 9700 },
    { model = 'primo', name = 'Primo', category = 'sedans', price = 8600 },
    { model = 'schafter2', name = 'Schafter', category = 'sedans', price = 42000 },
    { model = 'stanier', name = 'Stanier', category = 'sedans', price = 7500 },
    { model = 'stratum', name = 'Stratum', category = 'sedans', price = 6800 },
    { model = 'superd', name = 'Super Diamond', category = 'sedans', price = 95000 },
    { model = 'tailgater', name = 'Tailgater', category = 'sedans', price = 22000 },
    { model = 'warrener', name = 'Warrener', category = 'sedans', price = 11200 },
    { model = 'washington', name = 'Washington', category = 'sedans', price = 10500 },

    -- Coupes
    { model = 'cogcabrio', name = 'Cognoscenti Cabrio', category = 'coupes', price = 58000 },
    { model = 'exemplar', name = 'Exemplar', category = 'coupes', price = 42000 },
    { model = 'f620', name = 'F620', category = 'coupes', price = 48000 },
    { model = 'felon', name = 'Felon', category = 'coupes', price = 39000 },
    { model = 'felon2', name = 'Felon GT', category = 'coupes', price = 45000 },
    { model = 'jackal', name = 'Jackal', category = 'coupes', price = 36000 },
    { model = 'oracle', name = 'Oracle', category = 'coupes', price = 28000 },
    { model = 'oracle2', name = 'Oracle XS', category = 'coupes', price = 34000 },
    { model = 'sentinel', name = 'Sentinel', category = 'coupes', price = 32000 },
    { model = 'sentinel2', name = 'Sentinel XS', category = 'coupes', price = 38000 },
    { model = 'windsor', name = 'Windsor', category = 'coupes', price = 72000 },
    { model = 'windsor2', name = 'Windsor Drop', category = 'coupes', price = 85000 },
    { model = 'zion', name = 'Zion', category = 'coupes', price = 31000 },
    { model = 'zion2', name = 'Zion Cabrio', category = 'coupes', price = 35000 },

    -- Muscle
    { model = 'blade', name = 'Blade', category = 'muscle', price = 18500 },
    { model = 'buccaneer', name = 'Buccaneer', category = 'muscle', price = 22000 },
    { model = 'chino', name = 'Chino', category = 'muscle', price = 16000 },
    { model = 'dominator', name = 'Dominator', category = 'muscle', price = 35000 },
    { model = 'dukes', name = 'Dukes', category = 'muscle', price = 28000 },
    { model = 'gauntlet', name = 'Gauntlet', category = 'muscle', price = 32000 },
    { model = 'hotknife', name = 'Hotknife', category = 'muscle', price = 45000 },
    { model = 'faction', name = 'Faction', category = 'muscle', price = 24000 },
    { model = 'nightshade', name = 'Nightshade', category = 'muscle', price = 52000 },
    { model = 'phoenix', name = 'Phoenix', category = 'muscle', price = 21000 },
    { model = 'picador', name = 'Picador', category = 'muscle', price = 14000 },
    { model = 'ruiner', name = 'Ruiner', category = 'muscle', price = 19000 },
    { model = 'sabregt', name = 'Sabre Turbo', category = 'muscle', price = 26000 },
    { model = 'slamvan', name = 'Slamvan', category = 'muscle', price = 23000 },
    { model = 'tampa', name = 'Tampa', category = 'muscle', price = 29000 },
    { model = 'vigero', name = 'Vigero', category = 'muscle', price = 20000 },
    { model = 'virgo', name = 'Virgo', category = 'muscle', price = 17500 },
    { model = 'voodoo2', name = 'Voodoo', category = 'muscle', price = 15500 },

    -- SUVs
    { model = 'baller', name = 'Baller', category = 'suvs', price = 48000 },
    { model = 'baller2', name = 'Baller II', category = 'suvs', price = 62000 },
    { model = 'bjxl', name = 'BeeJay XL', category = 'suvs', price = 28000 },
    { model = 'cavalcade', name = 'Cavalcade', category = 'suvs', price = 32000 },
    { model = 'contender', name = 'Contender', category = 'suvs', price = 55000 },
    { model = 'dubsta', name = 'Dubsta', category = 'suvs', price = 45000 },
    { model = 'fq2', name = 'FQ 2', category = 'suvs', price = 26000 },
    { model = 'granger', name = 'Granger', category = 'suvs', price = 38000 },
    { model = 'gresley', name = 'Gresley', category = 'suvs', price = 30000 },
    { model = 'habanero', name = 'Habanero', category = 'suvs', price = 24000 },
    { model = 'huntley', name = 'Huntley S', category = 'suvs', price = 52000 },
    { model = 'landstalker', name = 'Landstalker', category = 'suvs', price = 35000 },
    { model = 'mesa', name = 'Mesa', category = 'suvs', price = 22000 },
    { model = 'patriot', name = 'Patriot', category = 'suvs', price = 42000 },
    { model = 'radi', name = 'Radius', category = 'suvs', price = 27000 },
    { model = 'rocoto', name = 'Rocoto', category = 'suvs', price = 34000 },
    { model = 'seminole', name = 'Seminole', category = 'suvs', price = 25000 },
    { model = 'serrano', name = 'Serrano', category = 'suvs', price = 29000 },
    { model = 'xls', name = 'XLS', category = 'suvs', price = 58000 },

    -- Sports Classics
    { model = 'btype', name = 'Roosevelt', category = 'sportsclassics', price = 75000 },
    { model = 'btype3', name = 'Roosevelt Valor', category = 'sportsclassics', price = 92000 },
    { model = 'casco', name = 'Casco', category = 'sportsclassics', price = 68000 },
    { model = 'cheetah2', name = 'Cheetah Classic', category = 'sportsclassics', price = 110000 },
    { model = 'coquette2', name = 'Coquette Classic', category = 'sportsclassics', price = 85000 },
    { model = 'infernus2', name = 'Infernus Classic', category = 'sportsclassics', price = 125000 },
    { model = 'jb700', name = 'JB 700', category = 'sportsclassics', price = 78000 },
    { model = 'mamba', name = 'Mamba', category = 'sportsclassics', price = 82000 },
    { model = 'manana', name = 'Manana', category = 'sportsclassics', price = 18000 },
    { model = 'monroe', name = 'Monroe', category = 'sportsclassics', price = 95000 },
    { model = 'peyote', name = 'Peyote', category = 'sportsclassics', price = 22000 },
    { model = 'pigalle', name = 'Pigalle', category = 'sportsclassics', price = 28000 },
    { model = 'stinger', name = 'Stinger', category = 'sportsclassics', price = 72000 },
    { model = 'stingergt', name = 'Stinger GT', category = 'sportsclassics', price = 88000 },
    { model = 'torero', name = 'Torero', category = 'sportsclassics', price = 105000 },
    { model = 'tornado', name = 'Tornado', category = 'sportsclassics', price = 20000 },
    { model = 'ztype', name = 'Z-Type', category = 'sportsclassics', price = 180000 },

    -- Sports
    { model = 'alpha', name = 'Alpha', category = 'sports', price = 65000 },
    { model = 'banshee', name = 'Banshee', category = 'sports', price = 78000 },
    { model = 'bestiagts', name = 'Bestia GTS', category = 'sports', price = 92000 },
    { model = 'buffalo', name = 'Buffalo', category = 'sports', price = 42000 },
    { model = 'buffalo2', name = 'Buffalo S', category = 'sports', price = 52000 },
    { model = 'carbonizzare', name = 'Carbonizzare', category = 'sports', price = 110000 },
    { model = 'comet2', name = 'Comet', category = 'sports', price = 85000 },
    { model = 'coquette', name = 'Coquette', category = 'sports', price = 98000 },
    { model = 'elegy2', name = 'Elegy RH8', category = 'sports', price = 72000 },
    { model = 'feltzer2', name = 'Feltzer', category = 'sports', price = 88000 },
    { model = 'furoregt', name = 'Furore GT', category = 'sports', price = 76000 },
    { model = 'fusilade', name = 'Fusilade', category = 'sports', price = 48000 },
    { model = 'jester', name = 'Jester', category = 'sports', price = 95000 },
    { model = 'kuruma', name = 'Kuruma', category = 'sports', price = 68000 },
    { model = 'lynx', name = 'Lynx', category = 'sports', price = 82000 },
    { model = 'massacro', name = 'Massacro', category = 'sports', price = 90000 },
    { model = 'ninef', name = '9F', category = 'sports', price = 105000 },
    { model = 'ninef2', name = '9F Cabrio', category = 'sports', price = 112000 },
    { model = 'penumbra', name = 'Penumbra', category = 'sports', price = 38000 },
    { model = 'rapidgt', name = 'Rapid GT', category = 'sports', price = 86000 },
    { model = 'schafter3', name = 'Schafter V12', category = 'sports', price = 70000 },
    { model = 'sultan', name = 'Sultan', category = 'sports', price = 45000 },
    { model = 'surano', name = 'Surano', category = 'sports', price = 80000 },

    -- Super
    { model = 'adder', name = 'Adder', category = 'super', price = 850000 },
    { model = 'bullet', name = 'Bullet', category = 'super', price = 420000 },
    { model = 'cheetah', name = 'Cheetah', category = 'super', price = 520000 },
    { model = 'entityxf', name = 'Entity XF', category = 'super', price = 680000 },
    { model = 'infernus', name = 'Infernus', category = 'super', price = 480000 },
    { model = 'osiris', name = 'Osiris', category = 'super', price = 720000 },
    { model = 't20', name = 'T20', category = 'super', price = 950000 },
    { model = 'turismor', name = 'Turismo R', category = 'super', price = 780000 },
    { model = 'vacca', name = 'Vacca', category = 'super', price = 390000 },
    { model = 'voltic', name = 'Voltic', category = 'super', price = 280000 },
    { model = 'zentorno', name = 'Zentorno', category = 'super', price = 890000 },

    -- Motos
    { model = 'akuma', name = 'Akuma', category = 'motorcycles', price = 18000 },
    { model = 'bagger', name = 'Bagger', category = 'motorcycles', price = 12000 },
    { model = 'bati', name = 'Bati 801', category = 'motorcycles', price = 28000 },
    { model = 'bati2', name = 'Bati 801RR', category = 'motorcycles', price = 32000 },
    { model = 'carbonrs', name = 'Carbon RS', category = 'motorcycles', price = 35000 },
    { model = 'daemon', name = 'Daemon', category = 'motorcycles', price = 15000 },
    { model = 'double', name = 'Double T', category = 'motorcycles', price = 22000 },
    { model = 'faggio', name = 'Faggio', category = 'motorcycles', price = 2500 },
    { model = 'hakuchou', name = 'Hakuchou', category = 'motorcycles', price = 42000 },
    { model = 'hexer', name = 'Hexer', category = 'motorcycles', price = 14000 },
    { model = 'nemesis', name = 'Nemesis', category = 'motorcycles', price = 16000 },
    { model = 'pcj', name = 'PCJ-600', category = 'motorcycles', price = 13000 },
    { model = 'ruffian', name = 'Ruffian', category = 'motorcycles', price = 17000 },
    { model = 'sanchez', name = 'Sanchez', category = 'motorcycles', price = 11000 },
    { model = 'vader', name = 'Vader', category = 'motorcycles', price = 14500 },

    -- Off-Road
    { model = 'bfinjection', name = 'Injection', category = 'offroad', price = 16000 },
    { model = 'bifta', name = 'Bifta', category = 'offroad', price = 18000 },
    { model = 'blazer', name = 'Blazer', category = 'offroad', price = 9000 },
    { model = 'bodhi2', name = 'Bodhi', category = 'offroad', price = 14000 },
    { model = 'brawler', name = 'Brawler', category = 'offroad', price = 55000 },
    { model = 'dune', name = 'Dune Buggy', category = 'offroad', price = 12000 },
    { model = 'rebel', name = 'Rebel', category = 'offroad', price = 15000 },
    { model = 'sandking', name = 'Sandking', category = 'offroad', price = 38000 },
    { model = 'trophytruck', name = 'Trophy Truck', category = 'offroad', price = 72000 },

    -- Vans
    { model = 'bison', name = 'Bison', category = 'vans', price = 22000 },
    { model = 'bobcatxl', name = 'Bobcat XL', category = 'vans', price = 18000 },
    { model = 'burrito3', name = 'Burrito', category = 'vans', price = 16000 },
    { model = 'minivan', name = 'Minivan', category = 'vans', price = 14000 },
    { model = 'paradise', name = 'Paradise', category = 'vans', price = 17000 },
    { model = 'rumpo', name = 'Rumpo', category = 'vans', price = 15000 },
    { model = 'speedo', name = 'Speedo', category = 'vans', price = 13000 },
    { model = 'youga', name = 'Youga', category = 'vans', price = 14500 },
}
