Recipes = {
    -- Horny's
    hornys_burger_classic = {
        id = 'hornys_burger_classic',
        label = 'Burger Classic',
        time = 10000,
        grade = 2,
        category = 'Cuisine',
        restaurants = { hornys = true },
        ingredients = { bread = 1, meat = 1, lettuce = 1, tomato = 1, cheese = 1 },
        result = { item = 'hornys_burger_classic', amount = 1 },
    },
    hornys_burger_bone = {
        id = 'hornys_burger_bone',
        label = 'Burger The Beef with the Bone',
        time = 12000,
        grade = 2,
        category = 'Cuisine',
        restaurants = { hornys = true },
        ingredients = { bread = 1, meat = 2, lettuce = 1, tomato = 1, cheese = 2 },
        result = { item = 'hornys_burger_bone', amount = 1 },
    },
    hornys_fries = {
        id = 'hornys_fries',
        label = 'Frites Horny\'s',
        time = 7000,
        grade = 1,
        category = 'Cuisine',
        restaurants = { hornys = true },
        ingredients = { potato = 2, oil = 1 },
        result = { item = 'hornys_fries', amount = 1 },
    },
    hornys_nuggets = {
        id = 'hornys_nuggets',
        label = 'Nuggets',
        time = 9000,
        grade = 2,
        category = 'Cuisine',
        restaurants = { hornys = true },
        ingredients = { meat = 1, flour = 1, oil = 1 },
        result = { item = 'hornys_nuggets', amount = 1 },
    },
    hornys_tacos = {
        id = 'hornys_tacos',
        label = 'Tacos Horny\'s',
        time = 10000,
        grade = 2,
        category = 'Cuisine',
        restaurants = { hornys = true },
        ingredients = { bread = 1, meat = 1, lettuce = 1, cheese = 1, tomato = 1 },
        result = { item = 'hornys_tacos', amount = 1 },
    },
    hornys_milkshake = {
        id = 'hornys_milkshake',
        label = 'Milkshake',
        time = 5000,
        grade = 0,
        category = 'Boissons',
        restaurants = { hornys = true },
        ingredients = { milk = 1, sugar = 1, ice = 1 },
        result = { item = 'hornys_milkshake', amount = 1 },
    },
    hornys_cola = {
        id = 'hornys_cola',
        label = 'Cola',
        time = 4000,
        grade = 0,
        category = 'Boissons',
        restaurants = { hornys = true },
        ingredients = { cola_syrup = 1, water = 1 },
        result = { item = 'hornys_cola', amount = 1 },
    },
    hornys_menu_combo = {
        id = 'hornys_menu_combo',
        label = 'Menu Combo Horny\'s',
        time = 15000,
        grade = 2,
        category = 'Menus',
        restaurants = { hornys = true },
        ingredients = {
            bread = 1, meat = 2, cheese = 1, lettuce = 1, tomato = 1,
            potato = 2, oil = 1, cola_syrup = 1, water = 1,
        },
        result = { item = 'hornys_menu_combo', amount = 1 },
    },

    -- Greasy Joe's
    greasy_breakfast = {
        id = 'greasy_breakfast',
        label = 'Petit-déjeuner complet',
        time = 14000,
        grade = 2,
        category = 'Petit-déjeuner',
        restaurants = { greasy_joes = true },
        ingredients = { egg = 2, bacon = 2, bread = 1, potato = 1, oil = 1 },
        result = { item = 'greasy_breakfast', amount = 1 },
    },
    greasy_pancakes = {
        id = 'greasy_pancakes',
        label = 'Pancakes',
        time = 10000,
        grade = 1,
        category = 'Petit-déjeuner',
        restaurants = { greasy_joes = true },
        ingredients = { flour = 2, milk = 1, egg = 1, syrup = 1 },
        result = { item = 'greasy_pancakes', amount = 1 },
    },
    greasy_bacon_eggs = {
        id = 'greasy_bacon_eggs',
        label = 'Bacon & Œufs',
        time = 11000,
        grade = 1,
        category = 'Petit-déjeuner',
        restaurants = { greasy_joes = true },
        ingredients = { egg = 2, bacon = 2, oil = 1 },
        result = { item = 'greasy_bacon_eggs', amount = 1 },
    },
    greasy_burger = {
        id = 'greasy_burger',
        label = 'Burger Diner',
        time = 11000,
        grade = 2,
        category = 'Plats',
        restaurants = { greasy_joes = true },
        ingredients = { bread = 1, meat = 1, cheese = 1, lettuce = 1, tomato = 1 },
        result = { item = 'greasy_burger', amount = 1 },
    },
    greasy_fries = {
        id = 'greasy_fries',
        label = 'Frites maison',
        time = 7000,
        grade = 1,
        category = 'Cuisine',
        restaurants = { greasy_joes = true },
        ingredients = { potato = 2, oil = 1 },
        result = { item = 'greasy_fries', amount = 1 },
    },
    greasy_coffee = {
        id = 'greasy_coffee',
        label = 'Café',
        time = 5000,
        grade = 0,
        category = 'Boissons',
        restaurants = { greasy_joes = true },
        ingredients = { coffee_bean = 1, water = 1 },
        result = { item = 'greasy_coffee', amount = 1 },
    },
    greasy_orange_juice = {
        id = 'greasy_orange_juice',
        label = 'Jus d\'orange',
        time = 4000,
        grade = 0,
        category = 'Boissons',
        restaurants = { greasy_joes = true },
        ingredients = { orange = 2, water = 1 },
        result = { item = 'greasy_orange_juice', amount = 1 },
    },
    greasy_milkshake = {
        id = 'greasy_milkshake',
        label = 'Milkshake Diner',
        time = 5000,
        grade = 0,
        category = 'Boissons',
        restaurants = { greasy_joes = true },
        ingredients = { milk = 1, sugar = 1, ice = 1 },
        result = { item = 'greasy_milkshake', amount = 1 },
    },
}

Config.Recipes = Recipes

---@param id string
---@return table|nil
function Rest.GetRecipe(id)
    return Recipes[id]
end

---@param restaurantKey string|nil
---@return table[]
function Rest.GetRecipeList(restaurantKey)
    local list = {}
    for id, recipe in pairs(Recipes) do
        if not restaurantKey or not recipe.restaurants or recipe.restaurants[restaurantKey] then
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
    end
    table.sort(list, function(a, b) return a.label < b.label end)
    return list
end
