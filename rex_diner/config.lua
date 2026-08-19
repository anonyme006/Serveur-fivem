Config = {}

Config.Debug = false
Config.Locale = 'fr'
Config.Currency = '$'
Config.DefaultRestaurant = 'rex_diner'
Config.Job = 'rex_diner' -- alias / compat

Config.TabletCommand = 'diner'
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
        version = '2.0.0',
        date = '19/08/2026',
        notes = {
            'Refonte complète du resource rex_diner',
            'Tablette NUI premium multi-pages',
            'Ventes, factures, craft, stock et livraisons',
            'Architecture multi-restaurants',
        },
    },
}

--[[
    Ajoutez d'autres restaurants ici (job + locations + stash).
]]
Config.Restaurants = {
    rex_diner = {
        job = 'rex_diner',
        label = 'Rex Diner',
        blip = {
            enabled = true,
            coords = vector3(1587.12, 6455.48, 26.01),
            sprite = 106,
            color = 1,
            scale = 0.75,
            label = 'Rex Diner',
        },
        stash = {
            id = 'rex_diner_storage',
            label = 'Stock Rex Diner',
            slots = 80,
            weight = 200000,
        },
        locations = {
            Boss = {
                coords = vector3(1595.42, 6454.88, 26.01),
                size = vec3(1.4, 1.4, 2.0),
                rotation = 0.0,
                label = 'Bureau patron',
                icon = 'fas fa-briefcase',
            },
            Kitchen = {
                coords = vector3(1587.85, 6458.12, 26.01),
                size = vec3(1.6, 1.6, 2.0),
                rotation = 0.0,
                label = 'Cuisine',
                icon = 'fas fa-utensils',
            },
            Cashier = {
                coords = vector3(1589.25, 6455.20, 26.01),
                size = vec3(1.4, 1.4, 2.0),
                rotation = 0.0,
                label = 'Caisse',
                icon = 'fas fa-cash-register',
            },
            Storage = {
                coords = vector3(1584.90, 6457.40, 26.01),
                size = vec3(1.6, 1.6, 2.0),
                rotation = 0.0,
                label = 'Stock / Frigo',
                icon = 'fas fa-box',
            },
            Cloakroom = {
                coords = vector3(1593.10, 6452.80, 26.01),
                size = vec3(1.4, 1.4, 2.0),
                rotation = 0.0,
                label = 'Vestiaire',
                icon = 'fas fa-shirt',
            },
            Delivery = {
                coords = vector3(1582.40, 6454.10, 26.01),
                size = vec3(2.0, 2.0, 2.0),
                rotation = 0.0,
                label = 'Point de livraison',
                icon = 'fas fa-truck',
            },
        },
    },
}
