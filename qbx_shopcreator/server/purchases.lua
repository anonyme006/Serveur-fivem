ShopCreator = ShopCreator or {}

local Repo = ShopCreator.Repository

---@param source number
---@param shopId number
---@param cart table
---@param paymentMethod string|nil
---@return table
function ShopCreator.Purchase(source, shopId, cart, paymentMethod)
    shopId = tonumber(shopId)
    if not shopId then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    if not ShopCreator.RateLimit(source, 'purchase', Config.RateLimit.purchaseMs) then
        return { ok = false, error = ShopCreator.L('rate_limited') }
    end

    local shop = ShopCreator.Cache.shops[shopId]
    if not shop or not shop.enabled then
        return { ok = false, error = ShopCreator.L('shop_closed') }
    end

    if not ShopCreator.IsShopOpen(shop) then
        return { ok = false, error = ShopCreator.L('shop_closed') }
    end

    if type(cart) ~= 'table' or #cart < 1 or #cart > Config.Purchase.maxCartItems then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    paymentMethod = paymentMethod == 'bank' and 'bank' or 'cash'
    if paymentMethod == 'cash' and not shop.allow_cash then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end
    if paymentMethod == 'bank' and not shop.allow_bank then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    local productMap = {}
    for i = 1, #(shop.products or {}) do
        local prod = shop.products[i]
        productMap[prod.id] = prod
    end

    local lines = {}
    local total = 0

    for i = 1, #cart do
        local line = cart[i]
        local productId = tonumber(line.product_id)
        local quantity = math.floor(tonumber(line.quantity) or 0)

        if not productId or quantity < 1 or quantity > Config.Purchase.maxQuantityPerLine then
            return { ok = false, error = ShopCreator.L('invalid_data') }
        end

        local product = productMap[productId]
        if not product or not product.enabled then
            return { ok = false, error = ShopCreator.L('invalid_data') }
        end

        if not shop.infinite_stock and (product.stock or 0) < quantity then
            return { ok = false, error = ShopCreator.L('out_of_stock') }
        end

        local itemName = ShopCreator.SanitizeItemName(product.item_name)
        if not itemName then
            return { ok = false, error = ShopCreator.L('invalid_data') }
        end

        local canCarry = true
        pcall(function()
            canCarry = exports.ox_inventory:CanCarryItem(source, itemName, quantity)
        end)
        if not canCarry then
            return { ok = false, error = ShopCreator.L('inventory_full') }
        end

        local lineTotal = product.price * quantity
        total = total + lineTotal
        lines[#lines + 1] = {
            product_id = productId,
            item_name = itemName,
            label = product.label,
            quantity = quantity,
            price = product.price,
            line_total = lineTotal,
        }
    end

    if total <= 0 then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    if ShopCreator.GetMoney(source, paymentMethod) < total then
        return { ok = false, error = ShopCreator.L('not_enough_money') }
    end

    local stockDecrements = {}
    if not shop.infinite_stock then
        for i = 1, #lines do
            local line = lines[i]
            local affected = Repo.DecrementProductStock(line.product_id, line.quantity)
            if not affected or affected < 1 then
                for j = 1, #stockDecrements do
                    local rollback = stockDecrements[j]
                    Repo.IncrementProductStock(rollback.product_id, rollback.quantity)
                end
                return { ok = false, error = ShopCreator.L('out_of_stock') }
            end
            stockDecrements[#stockDecrements + 1] = {
                product_id = line.product_id,
                quantity = line.quantity,
            }
        end
    end

    if not ShopCreator.RemoveMoney(source, total, paymentMethod, 'shop_purchase') then
        if not shop.infinite_stock then
            for i = 1, #stockDecrements do
                local rollback = stockDecrements[i]
                Repo.IncrementProductStock(rollback.product_id, rollback.quantity)
            end
        end
        return { ok = false, error = ShopCreator.L('not_enough_money') }
    end

    local givenItems = {}
    for i = 1, #lines do
        local line = lines[i]
        local added = false
        pcall(function()
            added = exports.ox_inventory:AddItem(source, line.item_name, line.quantity) and true or false
        end)

        if not added then
            ShopCreator.AddMoney(source, total, paymentMethod, 'shop_refund')
            if not shop.infinite_stock then
                for j = 1, #stockDecrements do
                    local rollback = stockDecrements[j]
                    Repo.IncrementProductStock(rollback.product_id, rollback.quantity)
                end
            end
            for j = 1, #givenItems do
                local given = givenItems[j]
                pcall(function()
                    exports.ox_inventory:RemoveItem(source, given.item_name, given.quantity)
                end)
            end
            return { ok = false, error = ShopCreator.L('inventory_full') }
        end

        givenItems[#givenItems + 1] = {
            item_name = line.item_name,
            quantity = line.quantity,
        }
    end

    Repo.AddBalance(shopId, total)

    local citizenid = ShopCreator.GetCitizenId(source)
    local playerName = ShopCreator.GetPlayerName(source)
    local description = ('Vente %s'):format(lines[1].label)
    if #lines > 1 then
        description = ('Vente panier x%d'):format(#lines)
    end

    Repo.InsertTransaction(
        shopId,
        ShopCreator.TransactionTypes.sale,
        total,
        citizenid,
        playerName,
        description,
        { lines = lines, payment = paymentMethod }
    )

    ShopCreator.ReloadShop(shopId)
    ShopCreator.SyncShopToClients(shopId)

    ShopCreator.Log('purchase', {
        shopId = shopId,
        citizenid = citizenid,
        total = total,
        lines = #lines,
    })

    ShopCreator.Notify(source, ShopCreator.L('purchase_success'), 'success')
    return { ok = true, data = { total = total } }
end
