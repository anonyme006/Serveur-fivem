--[[
    Fusionnez dans ox_inventory/data/items.lua
]]

return {
    -- Ingrédients communs
    ['bread'] = { label = 'Pain', weight = 100, stack = true, close = true, description = 'Pain burger' },
    ['meat'] = { label = 'Viande', weight = 150, stack = true, close = true, description = 'Viande fraîche' },
    ['cheese'] = { label = 'Fromage', weight = 80, stack = true, close = true, description = 'Fromage' },
    ['lettuce'] = { label = 'Salade', weight = 50, stack = true, close = true, description = 'Salade' },
    ['tomato'] = { label = 'Tomate', weight = 60, stack = true, close = true, description = 'Tomate' },
    ['potato'] = { label = 'Pomme de terre', weight = 120, stack = true, close = true, description = 'Pomme de terre' },
    ['oil'] = { label = 'Huile', weight = 200, stack = true, close = true, description = 'Huile' },
    ['flour'] = { label = 'Farine', weight = 200, stack = true, close = true, description = 'Farine' },
    ['sugar'] = { label = 'Sucre', weight = 100, stack = true, close = true, description = 'Sucre' },
    ['milk'] = { label = 'Lait', weight = 250, stack = true, close = true, description = 'Lait' },
    ['coffee_bean'] = { label = 'Café (grain)', weight = 80, stack = true, close = true, description = 'Grains de café' },
    ['cola_syrup'] = { label = 'Sirop cola', weight = 150, stack = true, close = true, description = 'Sirop cola' },
    ['water'] = { label = 'Eau', weight = 100, stack = true, close = true, description = 'Eau' },
    ['egg'] = { label = 'Œuf', weight = 60, stack = true, close = true, description = 'Œuf frais' },
    ['bacon'] = { label = 'Bacon', weight = 100, stack = true, close = true, description = 'Bacon fumé' },
    ['ice'] = { label = 'Glaçons', weight = 50, stack = true, close = true, description = 'Glaçons' },
    ['syrup'] = { label = 'Sirop', weight = 150, stack = true, close = true, description = 'Sirop érable' },
    ['orange'] = { label = 'Orange', weight = 80, stack = true, close = true, description = 'Orange fraîche' },

    -- Horny's Burgers
    ['hornys_burger_classic'] = {
        label = 'Burger Classic', weight = 300, stack = true, close = true, description = 'Burger classique Horny\'s',
        client = { status = { hunger = 250000 }, anim = 'eating', prop = 'burger', usetime = 2500 },
    },
    ['hornys_burger_bone'] = {
        label = 'Burger The Beef with the Bone', weight = 350, stack = true, close = true, description = 'Signature Horny\'s',
        client = { status = { hunger = 320000 }, anim = 'eating', prop = 'burger', usetime = 2500 },
    },
    ['hornys_fries'] = {
        label = 'Frites Horny\'s', weight = 200, stack = true, close = true, description = 'Frites croustillantes',
        client = { status = { hunger = 150000 }, anim = 'eating', usetime = 2000 },
    },
    ['hornys_nuggets'] = {
        label = 'Nuggets', weight = 180, stack = true, close = true, description = '6 nuggets croustillants',
        client = { status = { hunger = 180000 }, anim = 'eating', usetime = 2000 },
    },
    ['hornys_tacos'] = {
        label = 'Tacos Horny\'s', weight = 250, stack = true, close = true, description = 'Tacos maison',
        client = { status = { hunger = 220000 }, anim = 'eating', usetime = 2500 },
    },
    ['hornys_milkshake'] = {
        label = 'Milkshake', weight = 250, stack = true, close = true, description = 'Milkshake onctueux',
        client = { status = { thirst = 200000 }, anim = 'drinking', usetime = 2000 },
    },
    ['hornys_cola'] = {
        label = 'Cola', weight = 200, stack = true, close = true, description = 'Cola frais',
        client = { status = { thirst = 180000 }, anim = 'drinking', usetime = 2000 },
    },
    ['hornys_menu_combo'] = {
        label = 'Menu Combo Horny\'s', weight = 700, stack = true, close = true, description = 'Burger, frites et boisson',
        client = { status = { hunger = 450000, thirst = 150000 }, anim = 'eating', usetime = 3500 },
    },

    -- Greasy Joe's Diner
    ['greasy_breakfast'] = {
        label = 'Petit-déjeuner complet', weight = 450, stack = true, close = true, description = 'Œufs, bacon, toast',
        client = { status = { hunger = 400000 }, anim = 'eating', usetime = 3000 },
    },
    ['greasy_pancakes'] = {
        label = 'Pancakes', weight = 300, stack = true, close = true, description = 'Stack de pancakes au sirop',
        client = { status = { hunger = 280000 }, anim = 'eating', usetime = 2500 },
    },
    ['greasy_bacon_eggs'] = {
        label = 'Bacon & Œufs', weight = 320, stack = true, close = true, description = 'Œufs au plat et bacon',
        client = { status = { hunger = 300000 }, anim = 'eating', usetime = 2500 },
    },
    ['greasy_burger'] = {
        label = 'Burger Diner', weight = 320, stack = true, close = true, description = 'Burger style diner',
        client = { status = { hunger = 280000 }, anim = 'eating', prop = 'burger', usetime = 2500 },
    },
    ['greasy_fries'] = {
        label = 'Frites maison', weight = 200, stack = true, close = true, description = 'Frites épaisses',
        client = { status = { hunger = 150000 }, anim = 'eating', usetime = 2000 },
    },
    ['greasy_coffee'] = {
        label = 'Café', weight = 150, stack = true, close = true, description = 'Café chaud',
        client = { status = { thirst = 100000 }, anim = 'drinking', usetime = 2000 },
    },
    ['greasy_orange_juice'] = {
        label = 'Jus d\'orange', weight = 200, stack = true, close = true, description = 'Jus pressé',
        client = { status = { thirst = 180000 }, anim = 'drinking', usetime = 2000 },
    },
    ['greasy_milkshake'] = {
        label = 'Milkshake Diner', weight = 250, stack = true, close = true, description = 'Milkshake style 50\'s',
        client = { status = { thirst = 200000 }, anim = 'drinking', usetime = 2000 },
    },
}
