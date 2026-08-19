Recipes = {
    burger_classic = {
        id = 'burger_classic',
        label = 'Burger Classic',
        time = 10000,
        grade = 2,
        category = 'Cuisine',
        ingredients = { bread = 1, meat = 1, lettuce = 1, tomato = 1, cheese = 1 },
        result = { item = 'burger_classic', amount = 1 },
    },
    burger_dino = {
        id = 'burger_dino',
        label = 'Burger Dino',
        time = 12000,
        grade = 2,
        category = 'Cuisine',
        ingredients = { bread = 1, meat = 2, lettuce = 1, tomato = 1, cheese = 2 },
        result = { item = 'burger_dino', amount = 1 },
    },
    fries = {
        id = 'fries',
        label = 'Frites',
        time = 7000,
        grade = 1,
        category = 'Cuisine',
        ingredients = { potato = 2, oil = 1 },
        result = { item = 'rex_fries', amount = 1 },
    },
    dessert = {
        id = 'dessert',
        label = 'Dessert Dino',
        time = 8000,
        grade = 1,
        category = 'Pâtisserie',
        ingredients = { flour = 1, sugar = 2, milk = 1 },
        result = { item = 'rex_dessert', amount = 1 },
    },
    coffee = {
        id = 'coffee',
        label = 'Café',
        time = 5000,
        grade = 0,
        category = 'Boissons',
        ingredients = { coffee_bean = 1, water = 1 },
        result = { item = 'rex_coffee', amount = 1 },
    },
    cola = {
        id = 'cola',
        label = 'Cola',
        time = 4000,
        grade = 0,
        category = 'Boissons',
        ingredients = { cola_syrup = 1, water = 1 },
        result = { item = 'rex_cola', amount = 1 },
    },
    plat = {
        id = 'plat',
        label = 'Plat du jour',
        time = 10000,
        grade = 2,
        category = 'Cuisine',
        ingredients = { meat = 1, potato = 1, lettuce = 1, oil = 1 },
        result = { item = 'rex_plat', amount = 1 },
    },
    formula_mini_dino = {
        id = 'formula_mini_dino',
        label = 'Formule Mini Dino',
        time = 12000,
        grade = 2,
        category = 'Menus',
        ingredients = { bread = 1, meat = 1, cheese = 1, potato = 1, cola_syrup = 1, water = 1 },
        result = { item = 'formula_mini_dino', amount = 1 },
    },
    formula_jurassic_royal = {
        id = 'formula_jurassic_royal',
        label = 'Formule Jurassic Royal',
        time = 15000,
        grade = 2,
        category = 'Menus',
        ingredients = {
            bread = 1, meat = 2, cheese = 2, lettuce = 1, tomato = 1,
            potato = 2, oil = 1, cola_syrup = 1, water = 1,
        },
        result = { item = 'formula_jurassic_royal', amount = 1 },
    },
}

Config.Recipes = Recipes

function Rex.GetRecipe(id)
    return Recipes[id]
end

function Rex.GetRecipeList()
    local list = {}
    for id, recipe in pairs(Recipes) do
        local ingredients = {}
        for item, amount in pairs(recipe.ingredients) do
            ingredients[#ingredients + 1] = {
                item = item,
                amount = amount,
                label = IngredientLabels[item] or item,
            }
        end
        table.sort(ingredients, function(a, b) return a.label < b.label end)
        list[#list + 1] = {
            id = id,
            label = recipe.label,
            time = recipe.time,
            grade = recipe.grade or 0,
            category = recipe.category,
            ingredients = ingredients,
            result = recipe.result,
        }
    end
    table.sort(list, function(a, b) return a.label < b.label end)
    return list
end
