ShopCreator = ShopCreator or {}

local Repo = ShopCreator.Repository

---@param shop table
---@param locationType string
---@return table|nil
local function getShopLocation(shop, locationType)
    for i = 1, #(shop.locations or {}) do
        local loc = shop.locations[i]
        if loc.location_type == locationType then
            return loc
        end
    end
    return nil
end

---@param shopId number
---@param orderId number
function ShopCreator.ApplyStockFromOrder(shopId, orderId)
    local order = Repo.GetStockOrder(orderId)
    if not order then return false end

    for i = 1, #(order.items or {}) do
        local item = order.items[i]
        Repo.IncrementProductStock(item.product_id, item.quantity, true)
    end

    Repo.UpdateStockOrderStatus(orderId, ShopCreator.OrderStatus.delivered)
    ShopCreator.ReloadShop(shopId)
    ShopCreator.SyncShopToClients(shopId)
    return true
end

---@param shopId number
---@param order table
---@return table origin, table dest
function ShopCreator.ResolveDeliveryPoints(shopId, order)
    local shop = ShopCreator.Cache.shops[shopId]
    local pickup = Config.Delivery.defaultPickup
    local origin = { x = pickup.x, y = pickup.y, z = pickup.z }

    local deliveryLoc = shop and getShopLocation(shop, ShopCreator.LocationTypes.delivery)
    local storageLoc = shop and getShopLocation(shop, ShopCreator.LocationTypes.storage)
    local destLoc = deliveryLoc or storageLoc

    local dest
    if destLoc then
        dest = { x = destLoc.x, y = destLoc.y, z = destLoc.z }
    else
        dest = { x = origin.x, y = origin.y, z = origin.z }
    end

    return origin, dest
end

---@param totalCost number
---@return number
function ShopCreator.CalculatePublicReward(totalCost)
    local percent = (ShopCreator.Settings.public_reward_percent or 12) / 100
    local reward = math.floor(totalCost * percent)
    reward = math.max(reward, Config.Delivery.publicMinReward)
    reward = math.min(reward, Config.Delivery.publicMaxReward)
    return reward
end

---@param source number
---@param shopId number
---@param method string
---@param items table
---@return table
function ShopCreator.CreateStockOrder(source, shopId, method, items)
    shopId = tonumber(shopId)
    if not ShopCreator.HasShopPermission(source, shopId, 'create_stock_orders') then
        return { ok = false, error = ShopCreator.L('no_permission') }
    end

    if not ShopCreator.RateLimit(source, 'stock_order', Config.RateLimit.fundsMs) then
        return { ok = false, error = ShopCreator.L('rate_limited') }
    end

    method = method or 'instant'
    if method ~= 'instant' and method ~= 'self' and method ~= 'public' then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    if method == 'instant' and not ShopCreator.Settings.instant_delivery then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end
    if method == 'self' and not ShopCreator.Settings.self_delivery then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end
    if method == 'public' and not ShopCreator.Settings.public_delivery then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    if method == 'public' and not ShopCreator.HasShopPermission(source, shopId, 'publish_delivery_jobs') then
        return { ok = false, error = ShopCreator.L('no_permission') }
    end

    if type(items) ~= 'table' or #items < 1 then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    local shop = ShopCreator.Cache.shops[shopId]
    if not shop then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    local productMap = {}
    for i = 1, #(shop.products or {}) do
        productMap[shop.products[i].id] = shop.products[i]
    end

    local lines = {}
    local totalCost = 0

    for i = 1, #items do
        local line = items[i]
        local productId = tonumber(line.product_id)
        local quantity = math.floor(tonumber(line.quantity) or 0)
        if not productId or quantity < 1 then
            return { ok = false, error = ShopCreator.L('invalid_data') }
        end

        local product = productMap[productId]
        if not product or not product.enabled then
            return { ok = false, error = ShopCreator.L('invalid_data') }
        end

        local unitCost = product.wholesale_price or 0
        totalCost = totalCost + (unitCost * quantity)
        lines[#lines + 1] = {
            product_id = productId,
            item_name = product.item_name,
            quantity = quantity,
            unit_cost = unitCost,
        }
    end

    if totalCost <= 0 then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    if (shop.balance or 0) < totalCost then
        return { ok = false, error = ShopCreator.L('not_enough_money') }
    end

    local affected = Repo.WithdrawBalance(shopId, totalCost)
    if not affected or affected < 1 then
        return { ok = false, error = ShopCreator.L('not_enough_money') }
    end

    local citizenid = ShopCreator.GetCitizenId(source)
    local playerName = ShopCreator.GetPlayerName(source)
    local status = ShopCreator.OrderStatus.pending

    if method == 'instant' then
        status = ShopCreator.OrderStatus.delivered
    end

    local orderId = Repo.InsertStockOrder(shopId, citizenid, playerName, method, totalCost, status)
    if not orderId then
        Repo.AddBalance(shopId, totalCost)
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    for i = 1, #lines do
        local line = lines[i]
        Repo.InsertStockOrderItem(orderId, line.product_id, line.item_name, line.quantity, line.unit_cost)
    end

    Repo.InsertTransaction(
        shopId,
        ShopCreator.TransactionTypes.stock_order,
        -totalCost,
        citizenid,
        playerName,
        ('Commande stock (%s)'):format(method),
        { orderId = orderId, method = method }
    )

    local mission = nil

    if method == 'instant' then
        ShopCreator.ApplyStockFromOrder(shopId, orderId)
    elseif method == 'self' or method == 'public' then
        local origin, dest = ShopCreator.ResolveDeliveryPoints(shopId, nil)
        local reward = method == 'public' and ShopCreator.CalculatePublicReward(totalCost) or 0
        local jobId = Repo.InsertDeliveryJob(orderId, shopId, reward, origin, dest)
        Repo.UpdateStockOrderStatus(orderId, ShopCreator.OrderStatus.pending)

        if method == 'self' and jobId then
            local accept = ShopCreator.AcceptDelivery(source, jobId)
            if accept.ok then
                mission = accept.data
                TriggerClientEvent('qbx_shopcreator:client:startDelivery', source, mission)
            end
        end
    end

    ShopCreator.ReloadShop(shopId)

    ShopCreator.Log('stock_order_created', {
        shopId = shopId,
        orderId = orderId,
        method = method,
        totalCost = totalCost,
    })

    ShopCreator.Notify(source, ShopCreator.L('order_created'), 'success')
    return { ok = true, data = { id = orderId, total_cost = totalCost, mission = mission } }
end

---@param shopId number
function ShopCreator.EnsureShopStash(shopId)
    ShopCreator.RegisterShopStash(shopId)
end
