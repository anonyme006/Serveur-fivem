Config = {}

Config.Job = 'marlowe'
Config.Label = 'Marlowe Vineyard'
Config.SocietyAccount = 'marlowe'

Config.Menu = {
    Position = 'centerright',
    Theme = 'native',
    Size = 'size-125',
}

Config.Colors = {
    Red = 180,
    Green = 130,
    Blue = 40,
}

Config.Command = 'marlowe'
Config.OpenKey = 'F6'

Config.Grades = {
    Stagiaire = 0,
    Vigneron = 1,
    Ouvrier = 2,
    Responsable = 3,
    Directeur = 4,
}

Config.Permissions = {
    Production = 0,
    Stock = 0,
    Deliveries = 1,
    Wardrobe = 0,
    Garage = 1,
    Duty = 0,
    Statistics = 0,
    Employees = 3,
    Society = 3,
    Orders = 2,
    DomainManagement = 3,
    Director = 4,
}

Config.RequireDuty = {
    Harvest = true,
    Production = true,
    Deliveries = true,
}

Config.Vineyard = {
    HarvestZones = {
        {
            coords = vec3(-1873.5, 2058.2, 135.9),
            radius = 2.5,
            label = 'Vigne nord',
        },
        {
            coords = vec3(-1860.8, 2065.4, 135.7),
            radius = 2.5,
            label = 'Vigne est',
        },
        {
            coords = vec3(-1885.2, 2048.6, 136.1),
            radius = 2.5,
            label = 'Vigne ouest',
        },
        {
            coords = vec3(-1870.1, 2035.8, 135.5),
            radius = 2.5,
            label = 'Vigne sud',
        },
    },
    ProductionPoint = {
        coords = vec3(-1928.72, 2059.35, 140.84),
        radius = 1.5,
        label = 'Cuve de production',
    },
    StockPoint = {
        coords = vec3(-1931.15, 2054.88, 140.84),
        radius = 1.5,
        label = 'Entrepôt',
    },
    GaragePoint = {
        coords = vec3(-1925.42, 2047.18, 140.74),
        radius = 2.0,
        label = 'Garage du domaine',
    },
    WardrobePoint = {
        coords = vec3(-1922.88, 2052.41, 140.84),
        radius = 1.5,
        label = 'Vestiaire',
    },
    BossPoint = {
        coords = vec3(-1920.55, 2058.92, 140.84),
        radius = 1.5,
        label = 'Bureau direction',
    },
    MenuPoint = {
        coords = vec3(-1923.10, 2056.50, 140.84),
        radius = 1.5,
        label = 'Gestion du domaine',
    },
}

Config.Production = {
    Harvest = {
        item = 'grape',
        amount = { min = 2, max = 5 },
        duration = 8000,
        anim = {
            dict = 'amb@world_human_gardener_plant@male@base',
            clip = 'base',
            flag = 49,
        },
        minGrade = 0,
    },
    Transform = {
        input = { item = 'grape', amount = 10 },
        output = { item = 'grape_juice', amount = 1 },
        duration = 10000,
        minGrade = 0,
    },
    Fermentation = {
        inputs = {
            red = { { item = 'grape_juice', amount = 5 } },
            white = { { item = 'grape_juice', amount = 5 } },
            rose = { { item = 'grape_juice', amount = 4 }, { item = 'grape', amount = 2 } },
        },
        outputs = {
            red = { item = 'wine_red', amount = 3 },
            white = { item = 'wine_white', amount = 3 },
            rose = { item = 'wine_rose', amount = 3 },
        },
        duration = 15000,
        minGrade = 1,
    },
    Bottling = {
        inputs = {
            { item = 'wine_red', amount = 1 },
            { item = 'wine_white', amount = 1 },
            { item = 'wine_rose', amount = 1 },
        },
        output = { item = 'wine_bottle_filled', amount = 1 },
        duration = 8000,
        minGrade = 1,
    },
    Labeling = {
        input = { item = 'wine_bottle_filled', amount = 1 },
        output = { item = 'wine_bottle_labeled', amount = 1 },
        duration = 5000,
        minGrade = 1,
    },
}

Config.Deliveries = {
    MinGrade = 1,
    DeliveryFee = 150,
    DeliveryPoints = {
        {
            label = 'Vinoteca Downtown',
            coords = vec3(-1223.42, -907.32, 12.33),
        },
        {
            label = 'Restaurant Vespucci',
            coords = vec3(-1193.85, -892.41, 13.99),
        },
        {
            label = 'Hôtel Del Perro',
            coords = vec3(-1447.52, -537.28, 34.74),
        },
        {
            label = 'Club Vinewood',
            coords = vec3(127.83, -1284.53, 29.28),
        },
    },
    Products = {
        { item = 'wine_bottle_labeled', label = 'Bouteille étiquetée', price = 85 },
        { item = 'wine_red', label = 'Vin rouge', price = 45 },
        { item = 'wine_white', label = 'Vin blanc', price = 45 },
        { item = 'wine_rose', label = 'Vin rosé', price = 50 },
    },
}

Config.Stashes = {
    RawMaterials = {
        id = 'marlowe_raw',
        label = 'Matières premières',
        slots = 50,
        weight = 100000,
    },
    FinishedProducts = {
        id = 'marlowe_finished',
        label = 'Produits finis',
        slots = 50,
        weight = 100000,
    },
    DeliveryStock = {
        id = 'marlowe_delivery',
        label = 'Stock livraison',
        slots = 30,
        weight = 80000,
    },
}

Config.Garage = {
    Spawn = vec4(-1928.55, 2042.18, 140.74, 258.0),
    StoreRadius = 8.0,
    MinGrade = 1,
    Vehicles = {
        { model = 'mule3', label = 'Mule', grade = 1 },
        { model = 'speedo', label = 'Speedo', grade = 1 },
        { model = 'burrito3', label = 'Burrito', grade = 2 },
        { model = 'pony', label = 'Pony', grade = 2 },
        { model = 'youga2', label = 'Youga Livraison', grade = 3 },
    },
}

Config.Blips = {
    {
        coords = vec3(-1923.10, 2056.50, 140.84),
        sprite = 85,
        color = 5,
        scale = 0.85,
        label = 'Marlowe Vineyard',
    },
}

Config.Outfits = {
    Work = {
        male = {
            ['t-shirt'] = { item = 15, texture = 0 },
            ['torso2'] = { item = 65, texture = 0 },
            ['arms'] = { item = 0, texture = 0 },
            ['pants'] = { item = 38, texture = 0 },
            ['shoes'] = { item = 25, texture = 0 },
        },
        female = {
            ['t-shirt'] = { item = 14, texture = 0 },
            ['torso2'] = { item = 59, texture = 0 },
            ['arms'] = { item = 0, texture = 0 },
            ['pants'] = { item = 38, texture = 0 },
            ['shoes'] = { item = 25, texture = 0 },
        },
    },
    Civil = nil,
}

Config.ClothingSystem = 'illenium'

Config.Notifications = {
    NoJob = 'Vous ne travaillez pas pour Marlowe Vineyard.',
    NoGrade = 'Votre grade ne permet pas cette action.',
    NoDuty = 'Vous devez être en service.',
    TooFar = 'Vous êtes trop loin.',
    MissingItems = 'Ingrédients insuffisants.',
    Success = 'Action réussie.',
    Failed = 'Action impossible.',
}
