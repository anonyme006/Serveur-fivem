Products = {
    formula_jurassic_royal = {
        id = 'formula_jurassic_royal',
        label = 'Formule Jurassic Royal',
        description = 'Menu royal : burger premium, frites et boisson.',
        price = 1400,
        category = 'Menus',
        color = '#C0392B',
        item = 'formula_jurassic_royal',
        recipe = 'formula_jurassic_royal',
        prepTime = 15000,
        available = true,
        sellable = true,
    },
    formula_mini_dino = {
        id = 'formula_mini_dino',
        label = 'Formule Mini Dino',
        description = 'Menu enfant dinosaure.',
        price = 800,
        category = 'Menus',
        color = '#E74C3C',
        item = 'formula_mini_dino',
        recipe = 'formula_mini_dino',
        prepTime = 12000,
        available = true,
        sellable = true,
    },
    plat = {
        id = 'plat',
        label = 'Plat',
        description = 'Plat du jour.',
        price = 500,
        category = 'Petite Faim',
        color = '#E67E22',
        item = 'rex_plat',
        recipe = 'plat',
        prepTime = 10000,
        available = true,
        sellable = true,
    },
    burger = {
        id = 'burger',
        label = 'Burger',
        description = 'Burger classic.',
        price = 600,
        category = 'Petite Faim',
        color = '#D35400',
        item = 'burger_classic',
        recipe = 'burger_classic',
        prepTime = 10000,
        available = true,
        sellable = true,
    },
    burger_dino = {
        id = 'burger_dino',
        label = 'Burger Dino',
        description = 'Burger signature.',
        price = 750,
        category = 'Petite Faim',
        color = '#A93226',
        item = 'burger_dino',
        recipe = 'burger_dino',
        prepTime = 12000,
        available = true,
        sellable = true,
    },
    dessert = {
        id = 'dessert',
        label = 'Dessert',
        description = 'Dessert dinosaure.',
        price = 600,
        category = 'Desserts',
        color = '#8E44AD',
        item = 'rex_dessert',
        recipe = 'dessert',
        prepTime = 8000,
        available = true,
        sellable = true,
    },
    boisson = {
        id = 'boisson',
        label = 'Boisson',
        description = 'Boisson fraîche.',
        price = 400,
        category = 'Boissons',
        color = '#5D6D7E',
        item = 'rex_cola',
        recipe = 'cola',
        prepTime = 4000,
        available = true,
        sellable = true,
    },
    fries = {
        id = 'fries',
        label = 'Frites',
        description = 'Frites croustillantes.',
        price = 350,
        category = 'Petite Faim',
        color = '#F39C12',
        item = 'rex_fries',
        recipe = 'fries',
        prepTime = 7000,
        available = true,
        sellable = true,
    },
    coffee = {
        id = 'coffee',
        label = 'Café',
        description = 'Café chaud.',
        price = 250,
        category = 'Boissons',
        color = '#6E2C00',
        item = 'rex_coffee',
        recipe = 'coffee',
        prepTime = 5000,
        available = true,
        sellable = true,
    },
}

Config.Products = Products

function Rex.GetProduct(id)
    return Products[id]
end

function Rex.GetSellableProducts()
    local list = {}
    for id, product in pairs(Products) do
        if product.sellable ~= false and product.available ~= false then
            list[#list + 1] = {
                id = id,
                label = product.label,
                description = product.description,
                price = product.price,
                category = product.category,
                color = product.color,
                prepTime = product.prepTime,
            }
        end
    end
    table.sort(list, function(a, b) return a.label < b.label end)
    return list
end
