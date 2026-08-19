--[[
    Copiez ces items dans ox_inventory/data/items.lua
    (ou fusionnez-les avec votre fichier existant)
]]

return {
    -- Ingrédients
    ['bread'] = { label = 'Pain', weight = 100, stack = true, close = true, description = 'Pain burger Rex Diner' },
    ['meat'] = { label = 'Viande', weight = 150, stack = true, close = true, description = 'Viande fraîche' },
    ['cheese'] = { label = 'Fromage', weight = 80, stack = true, close = true, description = 'Tranche de fromage' },
    ['lettuce'] = { label = 'Salade', weight = 50, stack = true, close = true, description = 'Salade fraîche' },
    ['tomato'] = { label = 'Tomate', weight = 60, stack = true, close = true, description = 'Tomate tranchée' },
    ['potato'] = { label = 'Pomme de terre', weight = 120, stack = true, close = true, description = 'Pomme de terre' },
    ['oil'] = { label = 'Huile', weight = 200, stack = true, close = true, description = 'Huile de friture' },
    ['flour'] = { label = 'Farine', weight = 200, stack = true, close = true, description = 'Farine' },
    ['sugar'] = { label = 'Sucre', weight = 100, stack = true, close = true, description = 'Sucre' },
    ['milk'] = { label = 'Lait', weight = 250, stack = true, close = true, description = 'Brique de lait' },
    ['coffee_bean'] = { label = 'Café (grain)', weight = 80, stack = true, close = true, description = 'Grains de café' },
    ['cola_syrup'] = { label = 'Sirop cola', weight = 150, stack = true, close = true, description = 'Sirop pour boisson' },
    ['water'] = { label = 'Eau', weight = 100, stack = true, close = true, description = 'Eau' },

    -- Produits finis
    ['burger_classic'] = {
        label = 'Burger Classic',
        weight = 300,
        stack = true,
        close = true,
        description = 'Burger classic Rex Diner',
        client = { status = { hunger = 250000 }, anim = 'eating', prop = 'burger', usetime = 2500 },
    },
    ['burger_dino'] = {
        label = 'Burger Dino',
        weight = 350,
        stack = true,
        close = true,
        description = 'Burger signature dinosaure',
        client = { status = { hunger = 300000 }, anim = 'eating', prop = 'burger', usetime = 2500 },
    },
    ['rex_fries'] = {
        label = 'Frites',
        weight = 200,
        stack = true,
        close = true,
        description = 'Frites croustillantes',
        client = { status = { hunger = 150000 }, anim = 'eating', usetime = 2000 },
    },
    ['rex_dessert'] = {
        label = 'Dessert Dino',
        weight = 180,
        stack = true,
        close = true,
        description = 'Dessert dinosaure',
        client = { status = { hunger = 120000 }, anim = 'eating', usetime = 2000 },
    },
    ['rex_coffee'] = {
        label = 'Café',
        weight = 150,
        stack = true,
        close = true,
        description = 'Café chaud',
        client = { status = { thirst = 100000 }, anim = 'drinking', usetime = 2000 },
    },
    ['rex_cola'] = {
        label = 'Cola',
        weight = 200,
        stack = true,
        close = true,
        description = 'Boisson fraîche',
        client = { status = { thirst = 180000 }, anim = 'drinking', usetime = 2000 },
    },
    ['rex_plat'] = {
        label = 'Plat du jour',
        weight = 400,
        stack = true,
        close = true,
        description = 'Plat du Rex Diner',
        client = { status = { hunger = 350000 }, anim = 'eating', usetime = 3000 },
    },
    ['formula_mini_dino'] = {
        label = 'Formule Mini Dino',
        weight = 600,
        stack = true,
        close = true,
        description = 'Menu enfant dinosaure',
        client = { status = { hunger = 400000, thirst = 150000 }, anim = 'eating', usetime = 3500 },
    },
    ['formula_jurassic_royal'] = {
        label = 'Formule Jurassic Royal',
        weight = 800,
        stack = true,
        close = true,
        description = 'Menu royal du Rex Diner',
        client = { status = { hunger = 500000, thirst = 200000 }, anim = 'eating', usetime = 4000 },
    },
}
