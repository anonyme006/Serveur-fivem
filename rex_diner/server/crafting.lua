---@param source number
---@param recipeId string
---@return boolean
---@return string
function RexDiner.StartCraft(source, recipeId)
    if not Config.EnableCrafting then
        return false, 'Cuisine désactivée.'
    end
    if not RexDiner.CheckCooldown(source, 'craft') then
        return false, 'Patientez avant de recuire.'
    end
    if RexDiner.ActiveCrafts[source] then
        return false, 'Fabrication déjà en cours.'
    end

    local ok, err, ctx = RexDiner.Authorize(source, 'kitchen')
    if not ok then return false, err end

    local recipe = GetRecipe(recipeId)
    if not recipe then
        return false, 'Recette introuvable.'
    end

    if ctx.grade < (recipe.grade or 0) then
        return false, 'Grade insuffisant pour cette recette.'
    end

    -- Prefer player inventory ingredients; fallback to restaurant stock
    local hasInv, missingInv = RexDiner.HasItems(source, recipe.ingredients)
    local useStock = false
    if not hasInv then
        local hasStock, missingStock = RexDiner.HasStockIngredients(ctx.restaurantKey, recipe.ingredients)
        if not hasStock then
            local label = IngredientLabels[missingInv or missingStock] or missingInv or missingStock or 'ingrédient'
            return false, ('Ingrédient manquant : %s'):format(label)
        end
        useStock = true
    end

    RexDiner.ActiveCrafts[source] = true
    return true, {
        recipeId = recipeId,
        label = recipe.label,
        time = recipe.time or 8000,
        useStock = useStock,
    }
end

---@param source number
---@param recipeId string
---@param useStock boolean
---@return boolean
---@return string
function RexDiner.FinishCraft(source, recipeId, useStock)
    if not RexDiner.ActiveCrafts[source] then
        return false, 'Aucune fabrication en cours.'
    end

    local ok, err, ctx = RexDiner.Authorize(source, 'kitchen')
    if not ok then
        RexDiner.ActiveCrafts[source] = nil
        return false, err
    end

    local recipe = GetRecipe(recipeId)
    if not recipe then
        RexDiner.ActiveCrafts[source] = nil
        return false, 'Recette introuvable.'
    end

    local removed = false
    if useStock then
        removed = RexDiner.ConsumeStockIngredients(ctx.restaurantKey, recipe.ingredients)
        if not removed then
            -- try inventory as fallback
            removed = RexDiner.RemoveItems(source, recipe.ingredients)
        end
    else
        removed = RexDiner.RemoveItems(source, recipe.ingredients)
        if not removed then
            removed = RexDiner.ConsumeStockIngredients(ctx.restaurantKey, recipe.ingredients)
        end
    end

    if not removed then
        RexDiner.ActiveCrafts[source] = nil
        return false, 'Impossible de retirer les ingrédients.'
    end

    local resultItem = recipe.result.item
    local resultAmount = math.floor(tonumber(recipe.result.amount) or 1)
    if not RexDiner.AddItem(source, resultItem, resultAmount) then
        -- refund ingredients to inventory if add failed
        for item, amount in pairs(recipe.ingredients) do
            RexDiner.AddItem(source, item, amount)
        end
        RexDiner.ActiveCrafts[source] = nil
        return false, 'Inventaire plein.'
    end

    RexDiner.ActiveCrafts[source] = nil
    RexDiner.Notify(source, 'Cuisine', ('%s préparé !'):format(recipe.label), 'success')
    return true, recipe.label
end

RegisterNetEvent('rex_diner:server:cancelCraft', function()
    local src = source
    RexDiner.ActiveCrafts[src] = nil
end)
