--[[
    Fusionnez dans ox_inventory/data/items.lua
]]

return {
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

    ['burger_classic'] = {
        label = 'Burger Classic', weight = 300, stack = true, close = true, description = 'Burger classic',
        client = { status = { hunger = 250000 }, anim = 'eating', prop = 'burger', usetime = 2500 },
    },
    ['burger_dino'] = {
        label = 'Burger Dino', weight = 350, stack = true, close = true, description = 'Burger dino',
        client = { status = { hunger = 300000 }, anim = 'eating', prop = 'burger', usetime = 2500 },
    },
    ['rex_fries'] = {
        label = 'Frites', weight = 200, stack = true, close = true, description = 'Frites',
        client = { status = { hunger = 150000 }, anim = 'eating', usetime = 2000 },
    },
    ['rex_dessert'] = {
        label = 'Dessert Dino', weight = 180, stack = true, close = true, description = 'Dessert',
        client = { status = { hunger = 120000 }, anim = 'eating', usetime = 2000 },
    },
    ['rex_coffee'] = {
        label = 'Café', weight = 150, stack = true, close = true, description = 'Café',
        client = { status = { thirst = 100000 }, anim = 'drinking', usetime = 2000 },
    },
    ['rex_cola'] = {
        label = 'Cola', weight = 200, stack = true, close = true, description = 'Cola',
        client = { status = { thirst = 180000 }, anim = 'drinking', usetime = 2000 },
    },
    ['rex_plat'] = {
        label = 'Plat du jour', weight = 400, stack = true, close = true, description = 'Plat',
        client = { status = { hunger = 350000 }, anim = 'eating', usetime = 3000 },
    },
    ['formula_mini_dino'] = {
        label = 'Formule Mini Dino', weight = 600, stack = true, close = true, description = 'Menu enfant',
        client = { status = { hunger = 400000, thirst = 150000 }, anim = 'eating', usetime = 3500 },
    },
    ['formula_jurassic_royal'] = {
        label = 'Formule Jurassic Royal', weight = 800, stack = true, close = true, description = 'Menu royal',
        client = { status = { hunger = 500000, thirst = 200000 }, anim = 'eating', usetime = 4000 },
    },
}
