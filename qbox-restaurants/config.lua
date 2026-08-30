Config = {}

Config.Debug = false
Config.Locale = 'fr'
Config.Currency = '$'
Config.DefaultRestaurant = 'hornys'
Config.Job = 'hornys' -- alias / compat

Config.TabletCommand = 'restaurant'
Config.TabletKey = 'F6'
Config.PaymentDistance = 5.0

Config.EnableBilling = true
Config.EnableDeliveries = true
Config.EnableCrafting = true
Config.EnableEmployeeManagement = true
Config.EnableStock = true
Config.EnableSocietyAccount = true
Config.SocietyAccountPrefix = 'society_'

--- Max discount % employees with grade >= 3 can apply
Config.MaxDiscount = 50

Config.Commission = {
    [0] = 0.10,
    [1] = 0.15,
    [2] = 0.20,
    [3] = 0.25,
    [4] = 0.30,
}

Config.GradeLabels = {
    [0] = 'Stagiaire',
    [1] = 'Employé',
    [2] = 'Cuisinier',
    [3] = 'Manager',
    [4] = 'Patron',
}

Config.Permissions = {
    [0] = { tablet = true, sales = true, service = true },
    [1] = { tablet = true, sales = true, service = true, recipes = true, billing = true },
    [2] = { tablet = true, sales = true, service = true, recipes = true, billing = true, kitchen = true },
    [3] = {
        tablet = true, sales = true, service = true, recipes = true, billing = true, kitchen = true,
        employees = true, stock = true, orders = true, deliveries = true,
    },
    [4] = {
        tablet = true, sales = true, service = true, recipes = true, billing = true, kitchen = true,
        employees = true, stock = true, orders = true, deliveries = true, finances = true, settings = true,
    },
}

Config.Cooldowns = {
    sale = 2,
    craft = 1,
    invoice = 3,
    order = 5,
    hire = 3,
    grade = 2,
}

Config.Craft = {
    animDict = 'amb@prop_human_bbq@male@base',
    animClip = 'base',
    cancelable = true,
}

Config.Delivery = {
    pickup = vector4(1208.45, -3115.12, 5.54, 90.0),
    vehicle = 'mule',
    blip = { sprite = 478, color = 2, scale = 0.85, label = 'Livraison restaurant' },
}

Config.PatchNotes = {
    {
        version = '2.1.0',
        date = '30/08/2026',
        notes = {
            'Renommage du resource en qbox-restaurants',
            'Configuration Horny\'s Burgers (Mirror Park)',
            'Configuration Greasy Joe\'s Diner (La Puerta)',
            'Menus et recettes par établissement',
        },
    },
    {
        version = '2.0.0',
        date = '19/08/2026',
        notes = {
            'Refonte complète du resource qbox-restaurants',
            'Tablette NUI premium multi-pages',
            'Ventes, factures, craft, stock et livraisons',
            'Architecture multi-restaurants',
        },
    },
}

--[[
    Coordonnées calibrées pour :
    - Horny's : MLO Mirror Park (Gabz / DRC Hornys)
    - Greasy Joe's : MLO La Puerta (MXC Greasy Joe's Drive-in)

    Ajustez les positions si votre MLO diffère.
]]
Config.Restaurants = {
    hornys = {
        job = 'hornys',
        label = "Horny's Burgers",
        theme = { primary = '#E74C3C', accent = '#F39C12' },
        blip = {
            enabled = true,
            coords = vector3(1243.33, -359.71, 69.08),
            sprite = 106,
            color = 1,
            scale = 0.75,
            label = "Horny's Burgers",
        },
        stash = {
            id = 'hornys_storage',
            label = "Stock Horny's",
            slots = 80,
            weight = 200000,
        },
        locations = {
            Boss = {
                coords = vector3(1239.02, -348.42, 69.03),
                size = vec3(1.4, 1.4, 2.0),
                rotation = 75.0,
                label = 'Bureau patron',
                icon = 'fas fa-briefcase',
            },
            Kitchen = {
                coords = vector3(1253.50, -355.51, 69.04),
                size = vec3(1.8, 1.8, 2.0),
                rotation = 75.0,
                label = 'Cuisine',
                icon = 'fas fa-utensils',
            },
            Cashier = {
                coords = vector3(1249.43, -358.91, 69.16),
                size = vec3(1.4, 1.4, 2.0),
                rotation = 75.0,
                label = 'Caisse',
                icon = 'fas fa-cash-register',
            },
            Storage = {
                coords = vector3(1250.00, -356.93, 68.53),
                size = vec3(1.6, 1.6, 2.0),
                rotation = 75.0,
                label = 'Stock / Frigo',
                icon = 'fas fa-box',
            },
            Cloakroom = {
                coords = vector3(1245.78, -355.14, 69.20),
                size = vec3(1.4, 1.4, 2.0),
                rotation = 75.0,
                label = 'Vestiaire',
                icon = 'fas fa-shirt',
            },
            Delivery = {
                coords = vector3(1257.51, -336.71, 68.08),
                size = vec3(2.0, 2.0, 2.0),
                rotation = 170.0,
                label = 'Point de livraison',
                icon = 'fas fa-truck',
            },
        },
    },

    greasy_joes = {
        job = 'greasy_joes',
        label = "Greasy Joe's Diner",
        theme = { primary = '#2980B9', accent = '#F1C40F' },
        blip = {
            enabled = true,
            coords = vector3(-1186.80, -885.20, 13.79),
            sprite = 93,
            color = 5,
            scale = 0.75,
            label = "Greasy Joe's Diner",
        },
        stash = {
            id = 'greasy_joes_storage',
            label = "Stock Greasy Joe's",
            slots = 80,
            weight = 200000,
        },
        locations = {
            Boss = {
                coords = vector3(-1175.80, -896.30, 13.75),
                size = vec3(1.4, 1.4, 2.0),
                rotation = 35.0,
                label = 'Bureau patron',
                icon = 'fas fa-briefcase',
            },
            Kitchen = {
                coords = vector3(-1188.20, -897.55, 13.75),
                size = vec3(1.8, 1.8, 2.0),
                rotation = 35.0,
                label = 'Cuisine',
                icon = 'fas fa-utensils',
            },
            Cashier = {
                coords = vector3(-1182.45, -891.12, 13.75),
                size = vec3(1.4, 1.4, 2.0),
                rotation = 35.0,
                label = 'Caisse',
                icon = 'fas fa-cash-register',
            },
            Storage = {
                coords = vector3(-1190.55, -893.80, 13.75),
                size = vec3(1.6, 1.6, 2.0),
                rotation = 35.0,
                label = 'Stock / Frigo',
                icon = 'fas fa-box',
            },
            Cloakroom = {
                coords = vector3(-1180.10, -894.50, 13.75),
                size = vec3(1.4, 1.4, 2.0),
                rotation = 35.0,
                label = 'Vestiaire',
                icon = 'fas fa-shirt',
            },
            Delivery = {
                coords = vector3(-1195.40, -878.60, 13.50),
                size = vec3(2.0, 2.0, 2.0),
                rotation = 125.0,
                label = 'Point de livraison',
                icon = 'fas fa-truck',
            },
        },
    },
}
