Config = {}

Config.Job = 'burgershot'
Config.Label = 'Burger Shot'
Config.Duty = vec3(-1198.0, -895.0, 14.0)
Config.Stash = 'burgershot_stash'

--- Stations de travail (coords à ajuster sur votre MLO)
Config.Stations = {
    grill = {
        label = 'Grill',
        coords = vec3(-1198.2, -897.1, 13.9),
        duration = 6500,
        anim = { dict = 'amb@prop_human_bbq@male@base', clip = 'base' },
        input = { item = 'bs_raw_patty', count = 1 },
        output = { item = 'bs_patty', count = 1 },
    },
    fryer = {
        label = 'Friteuse',
        coords = vec3(-1200.6, -896.8, 13.9),
        duration = 5500,
        anim = { dict = 'amb@prop_human_bbq@male@idle_a', clip = 'idle_b' },
        input = { item = 'bs_potato', count = 1 },
        output = { item = 'bs_fries', count = 1 },
    },
    drinks = {
        label = 'Boissons',
        coords = vec3(-1197.0, -894.2, 13.9),
        duration = 3500,
        anim = { dict = 'mp_ped_interaction', clip = 'handshake_guy_a' },
        input = nil,
        output = { item = 'bs_drink', count = 1 },
    },
    assemble = {
        label = 'Assemblage',
        coords = vec3(-1196.4, -896.5, 13.9),
        duration = 5000,
        anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
        input = {
            { item = 'bs_patty', count = 1 },
            { item = 'bs_bun', count = 1 },
        },
        output = { item = 'bs_burger', count = 1 },
    },
}

Config.Counter = {
    label = 'Caisse',
    coords = vec3(-1194.8, -893.9, 13.9),
    radius = 1.2,
}

--- Menu client (prix)
Config.Menu = {
    { id = 'burger_meal', label = 'Menu Burger', price = 85, items = { bs_burger = 1, bs_fries = 1, bs_drink = 1 } },
    { id = 'burger_only', label = 'Burger seul', price = 55, items = { bs_burger = 1 } },
    { id = 'fries_only', label = 'Frites', price = 25, items = { bs_fries = 1 } },
    { id = 'drink_only', label = 'Boisson', price = 20, items = { bs_drink = 1 } },
}

Config.SalaryBonus = 15 -- tip employé à chaque vente réussie
Config.RequireDuty = true
Config.MaxOrderDistance = 3.0
