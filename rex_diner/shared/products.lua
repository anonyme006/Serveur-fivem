Products = {
    formula_jurassic_royal = {
        id = 'formula_jurassic_royal',
        label = 'Formule Jurassic Royal',
        description = 'Menu royal : burger premium, frites et boisson.',
        price = 1400,
        category = 'Menus',
        image = 'formula_jurassic_royal.png',
        color = '#C0392B',
        item = 'formula_jurassic_royal',
        craftable = true,
        recipe = 'formula_jurassic_royal',
        prepTime = 15000,
        available = true,
        stockItem = 'formula_jurassic_royal',
        sellable = true,
    },
    formula_mini_dino = {
        id = 'formula_mini_dino',
        label = 'Formule Mini Dino',
        description = 'Menu enfant dinosaure avec burger, frites et boisson.',
        price = 800,
        category = 'Menus',
        image = 'formula_mini_dino.png',
        color = '#E74C3C',
        item = 'formula_mini_dino',
        craftable = true,
        recipe = 'formula_mini_dino',
        prepTime = 12000,
        available = true,
        stockItem = 'formula_mini_dino',
        sellable = true,
    },
    plat = {
        id = 'plat',
        label = 'Plat',
        description = 'Plat du jour du Rex Diner.',
        price = 500,
        category = 'Petite Faim',
        image = 'plat.png',
        color = '#E67E22',
        item = 'rex_plat',
        craftable = true,
        recipe = 'plat',
        prepTime = 10000,
        available = true,
        stockItem = 'rex_plat',
        sellable = true,
    },
    burger = {
        id = 'burger',
        label = 'Burger',
        description = 'Burger classic Rex Diner.',
        price = 600,
        category = 'Petite Faim',
        image = 'burger.png',
        color = '#D35400',
        item = 'burger_classic',
        craftable = true,
        recipe = 'burger_classic',
        prepTime = 10000,
        available = true,
        stockItem = 'burger_classic',
        sellable = true,
    },
    burger_dino = {
        id = 'burger_dino',
        label = 'Burger Dino',
        description = 'Burger signature dinosaure.',
        price = 750,
        category = 'Petite Faim',
        image = 'burger_dino.png',
        color = '#A93226',
        item = 'burger_dino',
        craftable = true,
        recipe = 'burger_dino',
        prepTime = 12000,
        available = true,
        stockItem = 'burger_dino',
        sellable = true,
    },
    dessert = {
        id = 'dessert',
        label = 'Dessert',
        description = 'Dessert dinosaure maison.',
        price = 600,
        category = 'Boisson',
        image = 'dessert.png',
        color = '#8E44AD',
        item = 'rex_dessert',
        craftable = true,
        recipe = 'dessert',
        prepTime = 8000,
        available = true,
        stockItem = 'rex_dessert',
        sellable = true,
    },
    boisson = {
        id = 'boisson',
        label = 'Boisson',
        description = 'Boisson fraîche au choix.',
        price = 400,
        category = 'Boisson',
        image = 'boisson.png',
        color = '#5D6D7E',
        item = 'rex_cola',
        craftable = true,
        recipe = 'cola',
        prepTime = 4000,
        available = true,
        stockItem = 'rex_cola',
        sellable = true,
    },
    fries = {
        id = 'fries',
        label = 'Frites',
        description = 'Frites croustillantes.',
        price = 350,
        category = 'Petite Faim',
        image = 'fries.png',
        color = '#F39C12',
        item = 'rex_fries',
        craftable = true,
        recipe = 'fries',
        prepTime = 7000,
        available = true,
        stockItem = 'rex_fries',
        sellable = true,
    },
    coffee = {
        id = 'coffee',
        label = 'Café',
        description = 'Café chaud maison.',
        price = 250,
        category = 'Boisson',
        image = 'coffee.png',
        color = '#6E2C00',
        item = 'rex_coffee',
        craftable = true,
        recipe = 'coffee',
        prepTime = 5000,
        available = true,
        stockItem = 'rex_coffee',
        sellable = true,
    },
}

--- Alias used by config / docs
Config.Products = Products

---@param productId string
---@return table|nil
function GetProduct(productId)
    return Products[productId]
end

---@return table[]
function GetSellableProducts()
    local list = {}
    for id, product in pairs(Products) do
        if product.sellable ~= false and product.available ~= false then
            list[#list + 1] = {
                id = id,
                label = product.label,
                description = product.description,
                price = product.price,
                category = product.category,
                image = product.image,
                color = product.color,
                prepTime = product.prepTime,
            }
        end
    end
    table.sort(list, function(a, b)
        return a.label < b.label
    end)
    return list
end
