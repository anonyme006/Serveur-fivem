function Rex.StartCraft(source, recipeId)
    if not Config.EnableCrafting then return false, 'Cuisine désactivée.' end
    if not Rex.Cooldown(source, 'craft') then return false, 'Patientez.' end
    if Rex.ActiveCrafts[source] then return false, 'Fabrication déjà en cours.' end

    local ok, err, ctx = Rex.Authorize(source, 'kitchen')
    if not ok then return false, err end

    local recipe = Rex.GetRecipe(recipeId)
    if not recipe then return false, 'Recette introuvable.' end
    if ctx.grade < (recipe.grade or 0) then return false, 'Grade insuffisant.' end

    local hasInv = Rex.HasItems(source, recipe.ingredients)
    local useStock = false
    if not hasInv then
        local hasStock, missing = Rex.HasStock(ctx.key, recipe.ingredients)
        if not hasStock then
            return false, ('Ingrédient manquant : %s'):format(IngredientLabels[missing] or missing or '?')
        end
        useStock = true
    end

    Rex.ActiveCrafts[source] = true
    return true, {
        recipeId = recipeId,
        label = recipe.label,
        time = recipe.time or 8000,
        useStock = useStock,
    }
end

function Rex.FinishCraft(source, recipeId, useStock)
    if not Rex.ActiveCrafts[source] then return false, 'Aucune fabrication.' end
    local ok, err, ctx = Rex.Authorize(source, 'kitchen')
    if not ok then
        Rex.ActiveCrafts[source] = nil
        return false, err
    end

    local recipe = Rex.GetRecipe(recipeId)
    if not recipe then
        Rex.ActiveCrafts[source] = nil
        return false, 'Recette introuvable.'
    end

    local removed
    if useStock then
        removed = Rex.ConsumeStock(ctx.key, recipe.ingredients)
        if not removed then removed = Rex.RemoveItems(source, recipe.ingredients) end
    else
        removed = Rex.RemoveItems(source, recipe.ingredients)
        if not removed then removed = Rex.ConsumeStock(ctx.key, recipe.ingredients) end
    end

    if not removed then
        Rex.ActiveCrafts[source] = nil
        return false, 'Impossible de retirer les ingrédients.'
    end

    local amount = math.floor(tonumber(recipe.result.amount) or 1)
    if not Rex.AddItem(source, recipe.result.item, amount) then
        for item, qty in pairs(recipe.ingredients) do
            Rex.AddItem(source, item, qty)
        end
        Rex.ActiveCrafts[source] = nil
        return false, 'Inventaire plein.'
    end

    Rex.ActiveCrafts[source] = nil
    Rex.Notify(source, 'Cuisine', ('%s préparé !'):format(recipe.label), 'success')
    return true, recipe.label
end

RegisterNetEvent('rex_diner:server:cancelCraft', function()
    Rex.ActiveCrafts[source] = nil
end)
