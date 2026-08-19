Config = {}

---@type string Default restaurant key when none is resolved from job
Config.DefaultRestaurant = 'rex_diner'

---@type string Alias kept for backwards compatibility
Config.Job = 'rex_diner'

Config.TabletCommand = 'diner'
Config.TabletKey = 'F6'
Config.PaymentDistance = 5.0
Config.Currency = '$'
Config.Locale = 'fr'

Config.EnableBilling = true
Config.EnableDeliveries = true
Config.EnableCrafting = true
Config.EnableEmployeeManagement = true
Config.EnableStock = true
Config.EnableSocietyAccount = true

--- Commission rate by job grade (0.25 = 25%)
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
    [0] = {
        tablet = true,
        sales = true,
        service = true,
    },
    [1] = {
        tablet = true,
        sales = true,
        recipes = true,
        service = true,
        billing = true,
    },
    [2] = {
        tablet = true,
        sales = true,
        recipes = true,
        kitchen = true,
        service = true,
        billing = true,
    },
    [3] = {
        tablet = true,
        sales = true,
        recipes = true,
        kitchen = true,
        employees = true,
        stock = true,
        orders = true,
        deliveries = true,
        service = true,
        billing = true,
    },
    [4] = {
        tablet = true,
        sales = true,
        recipes = true,
        kitchen = true,
        employees = true,
        stock = true,
        orders = true,
        deliveries = true,
        finances = true,
        settings = true,
        service = true,
        billing = true,
    },
}

Config.Cooldowns = {
    sale = 2,
    craft = 1,
    invoice = 3,
    order = 5,
    hire = 3,
    grade = 2,
    stock = 1,
}

Config.Craft = {
    progressLabel = 'Préparation en cours...',
    animDict = 'amb@prop_human_bbq@male@base',
    animClip = 'base',
    cancelable = true,
}

Config.Delivery = {
    pickup = vector4(1208.45, -3115.12, 5.54, 90.0),
    vehicle = 'mule',
    blip = {
        sprite = 478,
        color = 2,
        scale = 0.85,
        label = 'Livraison restaurant',
    },
}

Config.SocietyAccountPrefix = 'society_'

---@type table<string, RestaurantConfig>
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
        stash = {
            id = 'rex_diner_storage',
            label = 'Stock Rex Diner',
            slots = 80,
            weight = 200000,
        },
    },
}

--- Optional second restaurant template (disabled by default — set job + coords to enable)
-- Config.Restaurants.burger_shot = {
--     job = 'burgershot',
--     label = 'Burger Shot',
--     locations = { ... },
-- }

Config.PatchNotes = {
    {
        version = '1.0.0',
        date = '19/08/2026',
        notes = {
            'Lancement de la tablette Rex Diner',
            'Système de ventes, factures et commissions',
            'Cuisine, stock et livraisons',
            'Gestion multi-restaurants',
        },
    },
}

Config.Debug = false
