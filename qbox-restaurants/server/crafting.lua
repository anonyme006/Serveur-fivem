function Rest.StartCraft(source, recipeId)
    if not Config.EnableCrafting then return false, 'Cuisine désactivée.' end
    if not Rest.Cooldown(source, 'craft') then return false, 'Patientez.' end
    if Rest.ActiveCrafts[source] then return false, 'Fabrication déjà en cours.' end

    local ok, err, ctx = Rest.Authorize(source, 'kitchen')
    if not ok then return false, err end

    local recipe = Rest.GetRecipe(recipeId)
    if not recipe then return false, 'Recette introuvable.' end
    if recipe.restaurants and not recipe.restaurants[ctx.key] then
        return false, 'Recette non disponible dans cet établissement.'
    end
    if ctx.grade < (recipe.grade or 0) then return false, 'Grade insuffisant.' end

    local hasInv = Rest.HasItems(source, recipe.ingredients)
    local useStock = false
    if not hasInv then
        local hasStock, missing = Rest.HasStock(ctx.key, recipe.ingredients)
        if not hasStock then
            return false, ('Ingrédient manquant : %s'):format(IngredientLabels[missing] or missing or '?')
        end
        useStock = true
    end

    Rest.ActiveCrafts[source] = true
    return true, {
        recipeId = recipeId,
        label = recipe.label,
        time = recipe.time or 8000,
        useStock = useStock,
    }
end

function Rest.FinishCraft(source, recipeId, useStock)
    if not Rest.ActiveCrafts[source] then return false, 'Aucune fabrication.' end
    local ok, err, ctx = Rest.Authorize(source, 'kitchen')
    if not ok then
        Rest.ActiveCrafts[source] = nil
        return false, err
    end

    local recipe = Rest.GetRecipe(recipeId)
    if not recipe then
        Rest.ActiveCrafts[source] = nil
        return false, 'Recette introuvable.'
    end
    if recipe.restaurants and not recipe.restaurants[ctx.key] then
        Rest.ActiveCrafts[source] = nil
        return false, 'Recette non disponible dans cet établissement.'
    end

    local removed
    if useStock then
        removed = Rest.ConsumeStock(ctx.key, recipe.ingredients)
        if not removed then removed = Rest.RemoveItems(source, recipe.ingredients) end
    else
        removed = Rest.RemoveItems(source, recipe.ingredients)
        if not removed then removed = Rest.ConsumeStock(ctx.key, recipe.ingredients) end
    end

    if not removed then
        Rest.ActiveCrafts[source] = nil
        return false, 'Impossible de retirer les ingrédients.'
    end

    local amount = math.floor(tonumber(recipe.result.amount) or 1)
    if not Rest.AddItem(source, recipe.result.item, amount) then
        for item, qty in pairs(recipe.ingredients) do
            Rest.AddItem(source, item, qty)
        end
        Rest.ActiveCrafts[source] = nil
        return false, 'Inventaire plein.'
    end

    Rest.ActiveCrafts[source] = nil
    Rest.Notify(source, 'Cuisine', ('%s préparé !'):format(recipe.label), 'success')
    return true, recipe.label
end

RegisterNetEvent('qbox_restaurants:server:cancelCraft', function()
    Rest.ActiveCrafts[source] = nil
end)
