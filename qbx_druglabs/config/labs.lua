Config = Config or {}

--- Template definitions used when seeding labs or creating via admin.
--- Persistent state (owner, lock, seal, rental) lives in SQL.
Config.LabTypes = {
    empty = {
        label = 'Empty Laboratory',
        description = 'Bare interior with stash access only.',
        defaultPurchasePrice = 75000,
        defaultRentPrice = 7500,
        stash = { slots = 50, weight = 200000 },
        recipes = {},
    },
    weed = {
        label = 'Weed Laboratory',
        description = 'Grow, maintain and package cannabis.',
        defaultPurchasePrice = 150000,
        defaultRentPrice = 15000,
        stash = { slots = 80, weight = 350000 },
        recipes = { 'plant', 'harvest', 'pack_1g', 'pack_5g', 'pack_10g' },
    },
    cocaine = {
        label = 'Cocaine Laboratory',
        description = 'Unpack, cut and package cocaine.',
        defaultPurchasePrice = 275000,
        defaultRentPrice = 25000,
        stash = { slots = 90, weight = 400000 },
        recipes = { 'unpack', 'cut', 'pack_1g', 'pack_5g', 'pack_10g' },
    },
    meth = {
        label = 'Meth Laboratory',
        description = 'Complex multi-stage methamphetamine production.',
        defaultPurchasePrice = 350000,
        defaultRentPrice = 30000,
        stash = { slots = 100, weight = 500000 },
        recipes = { 'mix', 'furnace', 'chemical_mixer', 'tray', 'break', 'pack_1g', 'pack_5g', 'pack_10g' },
    },
    acid = {
        label = 'Acid Laboratory',
        description = 'Bottle and package acid products.',
        defaultPurchasePrice = 200000,
        defaultRentPrice = 20000,
        stash = { slots = 70, weight = 300000 },
        recipes = { 'bottling', 'packing' },
    },
    mdma = {
        label = 'MDMA Laboratory',
        description = 'Custom-ready MDMA template.',
        defaultPurchasePrice = 300000,
        defaultRentPrice = 28000,
        stash = { slots = 90, weight = 400000 },
        recipes = {},
    },
    heroin = {
        label = 'Heroin Laboratory',
        description = 'Custom-ready heroin template.',
        defaultPurchasePrice = 320000,
        defaultRentPrice = 29000,
        stash = { slots = 90, weight = 400000 },
        recipes = {},
    },
    lsd = {
        label = 'LSD Laboratory',
        description = 'Custom-ready LSD template.',
        defaultPurchasePrice = 280000,
        defaultRentPrice = 26000,
        stash = { slots = 80, weight = 350000 },
        recipes = {},
    },
    crack = {
        label = 'Crack Laboratory',
        description = 'Custom-ready crack template.',
        defaultPurchasePrice = 180000,
        defaultRentPrice = 16000,
        stash = { slots = 70, weight = 300000 },
        recipes = {},
    },
    fentanyl = {
        label = 'Fentanyl Laboratory',
        description = 'Custom-ready fentanyl template.',
        defaultPurchasePrice = 400000,
        defaultRentPrice = 35000,
        stash = { slots = 100, weight = 450000 },
        recipes = {},
    },
}

--- Seed labs created on first install if SQL is empty and Config.SeedLabsOnStart is true.
Config.SeedLabsOnStart = true

Config.DefaultLabs = {
    ['weed_lab_01'] = {
        label = 'Grove Weed Lab',
        type = 'weed',
        purchaseMode = 'purchase',
        purchasePrice = 150000,
        rentPrice = 15000,
        entrance = vec4(243.54, -1375.92, 39.53, 140.0),
        interior = {
            entrance = vec4(1066.22, -3183.45, -39.16, 90.0),
            exit = vec4(1066.22, -3183.45, -39.16, 270.0),
        },
        stash = {
            coords = vec3(1042.16, -3195.45, -38.15),
            slots = 80,
            weight = 350000,
        },
        stations = {
            plant_1 = { coords = vec3(1051.55, -3195.80, -39.14), heading = 0.0, recipeGroup = 'plant' },
            plant_2 = { coords = vec3(1056.45, -3195.80, -39.14), heading = 0.0, recipeGroup = 'plant' },
            plant_3 = { coords = vec3(1061.20, -3195.80, -39.14), heading = 0.0, recipeGroup = 'plant' },
            packing = { coords = vec3(1038.40, -3205.85, -38.17), heading = 180.0, recipeGroup = 'pack' },
        },
        blip = { enabled = false, sprite = 469, color = 2, scale = 0.7 },
    },
    ['coke_lab_01'] = {
        label = 'Docks Cocaine Lab',
        type = 'cocaine',
        purchaseMode = 'purchase',
        purchasePrice = 275000,
        rentPrice = 25000,
        entrance = vec4(892.16, -2172.94, 32.28, 175.0),
        interior = {
            entrance = vec4(1088.65, -3187.58, -38.99, 180.0),
            exit = vec4(1088.65, -3187.58, -38.99, 0.0),
        },
        stash = {
            coords = vec3(1096.85, -3192.85, -38.99),
            slots = 90,
            weight = 400000,
        },
        stations = {
            unpack = { coords = vec3(1090.20, -3194.90, -38.99), heading = 0.0, recipeGroup = 'unpack' },
            cut = { coords = vec3(1093.10, -3196.50, -38.99), heading = 90.0, recipeGroup = 'cut' },
            packing = { coords = vec3(1101.25, -3198.70, -38.99), heading = 180.0, recipeGroup = 'pack' },
        },
        blip = { enabled = false, sprite = 501, color = 0, scale = 0.7 },
    },
    ['meth_lab_01'] = {
        label = 'Sandy Meth Lab',
        type = 'meth',
        purchaseMode = 'purchase',
        purchasePrice = 350000,
        rentPrice = 30000,
        entrance = vec4(1389.86, 3607.89, 38.94, 110.0),
        interior = {
            entrance = vec4(996.89, -3200.73, -36.39, 270.0),
            exit = vec4(996.89, -3200.73, -36.39, 90.0),
        },
        stash = {
            coords = vec3(1016.45, -3194.90, -38.99),
            slots = 100,
            weight = 500000,
        },
        stations = {
            mix = { coords = vec3(1005.75, -3200.40, -38.52), heading = 0.0, recipeGroup = 'mix' },
            furnace = { coords = vec3(1009.80, -3198.20, -38.99), heading = 90.0, recipeGroup = 'furnace' },
            chemical_mixer = { coords = vec3(1012.40, -3198.50, -38.99), heading = 180.0, recipeGroup = 'chemical_mixer' },
            tray = { coords = vec3(1014.10, -3194.80, -38.99), heading = 0.0, recipeGroup = 'tray' },
            break_crystal = { coords = vec3(1016.20, -3199.10, -38.99), heading = 270.0, recipeGroup = 'break' },
            packing = { coords = vec3(1011.50, -3194.30, -38.99), heading = 0.0, recipeGroup = 'pack' },
        },
        blip = { enabled = false, sprite = 499, color = 1, scale = 0.7 },
    },
    ['acid_lab_01'] = {
        label = 'Paleto Acid Lab',
        type = 'acid',
        purchaseMode = 'purchase',
        purchasePrice = 200000,
        rentPrice = 20000,
        entrance = vec4(-315.42, 6193.95, 31.56, 45.0),
        interior = {
            entrance = vec4(482.89, -2624.90, -49.06, 180.0),
            exit = vec4(482.89, -2624.90, -49.06, 0.0),
        },
        stash = {
            coords = vec3(490.10, -2622.40, -49.06),
            slots = 70,
            weight = 300000,
        },
        stations = {
            bottling = { coords = vec3(485.50, -2625.80, -49.06), heading = 90.0, recipeGroup = 'bottling' },
            packing = { coords = vec3(488.20, -2628.10, -49.06), heading = 180.0, recipeGroup = 'packing' },
        },
        blip = { enabled = false, sprite = 499, color = 52, scale = 0.7 },
    },
    ['empty_lab_01'] = {
        label = 'Empty Warehouse Lab',
        type = 'empty',
        purchaseMode = 'purchase',
        purchasePrice = 75000,
        rentPrice = 7500,
        entrance = vec4(717.82, -964.39, 30.40, 0.0),
        interior = {
            entrance = vec4(1173.55, -3196.55, -39.01, 90.0),
            exit = vec4(1173.55, -3196.55, -39.01, 270.0),
        },
        stash = {
            coords = vec3(1160.20, -3192.80, -39.01),
            slots = 50,
            weight = 200000,
        },
        stations = {},
        blip = { enabled = false, sprite = 473, color = 0, scale = 0.6 },
    },
}
