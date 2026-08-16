ShopCreator = ShopCreator or {}

---@param source number
---@param permFn fun(): table
---@return table|nil
local function requireAdmin(source, permFn)
    if not ShopCreator.IsAdmin(source) then
        return { ok = false, error = ShopCreator.L('no_permission') }
    end
    return permFn()
end

--- Admin callbacks
lib.callback.register('qbx_shopcreator:admin:listShops', function(source)
    return ShopCreator.ListShopsAdmin(source)
end)

lib.callback.register('qbx_shopcreator:admin:getShop', function(source, shopId)
    return requireAdmin(source, function()
        shopId = tonumber(shopId)
        local shop = ShopCreator.Cache.shops[shopId]
        if not shop then
            return { ok = false, error = ShopCreator.L('invalid_data') }
        end
        return { ok = true, data = ShopCreator.DeepCopy(shop) }
    end)
end)

lib.callback.register('qbx_shopcreator:admin:createShop', function(source, payload)
    return requireAdmin(source, function()
        return ShopCreator.AdminCreateShop(source, payload)
    end)
end)

lib.callback.register('qbx_shopcreator:admin:updateShop', function(source, shopId, payload)
    return requireAdmin(source, function()
        if type(payload) == 'table' and payload.shop then
            return ShopCreator.AdminUpdateShop(source, shopId or payload.shop.id, payload.shop)
        end
        return ShopCreator.AdminUpdateShop(source, shopId, payload)
    end)
end)

lib.callback.register('qbx_shopcreator:admin:deleteShop', function(source, shopId)
    return requireAdmin(source, function()
        if type(shopId) == 'table' then
            shopId = shopId.id or shopId.shopId
        end
        return ShopCreator.AdminDeleteShop(source, shopId)
    end)
end)

lib.callback.register('qbx_shopcreator:admin:listAdmins', function(source)
    return requireAdmin(source, function()
        return { ok = true, data = ShopCreator.AdminEntries or ShopCreator.ReloadAdmins() }
    end)
end)

lib.callback.register('qbx_shopcreator:admin:addAdmin', function(source, data)
    return requireAdmin(source, function()
        data = data or {}
        return ShopCreator.AddAdmin(source, data.identifier, data.label)
    end)
end)

lib.callback.register('qbx_shopcreator:admin:removeAdmin', function(source, adminId)
    return requireAdmin(source, function()
        if type(adminId) == 'table' then
            adminId = adminId.id
        end
        return ShopCreator.RemoveAdmin(source, adminId)
    end)
end)

lib.callback.register('qbx_shopcreator:admin:getSettings', function(source)
    return requireAdmin(source, function()
        return { ok = true, data = ShopCreator.Settings }
    end)
end)

lib.callback.register('qbx_shopcreator:admin:saveSettings', function(source, settings)
    return ShopCreator.SaveSettings(source, settings)
end)

lib.callback.register('qbx_shopcreator:admin:getInventoryItems', function(source)
    return requireAdmin(source, function()
        return ShopCreator.GetInventoryItems()
    end)
end)

lib.callback.register('qbx_shopcreator:admin:getPlayerPosition', function(source)
    return requireAdmin(source, function()
        local coords = lib.callback.await('qbx_shopcreator:client:getPlayerPosition', source)
        if not coords then
            return { ok = false, error = ShopCreator.L('invalid_data') }
        end
        return { ok = true, data = coords }
    end)
end)

lib.callback.register('qbx_shopcreator:admin:useCurrentPosition', function(source)
    return requireAdmin(source, function()
        local coords = lib.callback.await('qbx_shopcreator:client:getPlayerPosition', source)
        if not coords then
            return { ok = false, error = ShopCreator.L('invalid_data') }
        end
        return { ok = true, data = coords }
    end)
end)

--- Storefront
lib.callback.register('qbx_shopcreator:storefront:getStorefront', function(source, shopId)
    if type(shopId) == 'table' then
        shopId = shopId.shopId or shopId.id
    end
    return ShopCreator.GetShopForClient(source, shopId, 'storefront')
end)

lib.callback.register('qbx_shopcreator:storefront:purchase', function(source, data)
    data = data or {}
    return ShopCreator.Purchase(source, data.shopId, data.cart, data.paymentMethod or data.payment)
end)

--- Management
lib.callback.register('qbx_shopcreator:management:getManagementData', function(source, shopId)
    if type(shopId) == 'table' then
        shopId = shopId.shopId
    end
    return ShopCreator.GetManagementData(source, shopId)
end)

lib.callback.register('qbx_shopcreator:management:updateShopStatus', function(source, data)
    data = data or {}
    return ShopCreator.UpdateShopStatus(source, data.shopId, data.is_open, data.auto_hours)
end)

lib.callback.register('qbx_shopcreator:management:depositFunds', function(source, data)
    data = data or {}
    return ShopCreator.DepositFunds(source, data.shopId, data.amount)
end)

lib.callback.register('qbx_shopcreator:management:withdrawFunds', function(source, data)
    data = data or {}
    return ShopCreator.WithdrawFunds(source, data.shopId, data.amount)
end)

lib.callback.register('qbx_shopcreator:management:saveCategories', function(source, data)
    data = data or {}
    return ShopCreator.SaveCategories(source, data.shopId, data.categories)
end)

lib.callback.register('qbx_shopcreator:management:saveProducts', function(source, data)
    data = data or {}
    return ShopCreator.SaveProducts(source, data.shopId, data.products)
end)

lib.callback.register('qbx_shopcreator:management:createStockOrder', function(source, data)
    data = data or {}
    return ShopCreator.CreateStockOrder(source, data.shopId, data.method, data.items)
end)

lib.callback.register('qbx_shopcreator:management:hireEmployee', function(source, data)
    data = data or {}
    return ShopCreator.HireEmployee(source, data.shopId, data.citizenid, data.name)
end)

lib.callback.register('qbx_shopcreator:management:fireEmployee', function(source, data)
    data = data or {}
    return ShopCreator.FireEmployee(source, data.shopId, data.employeeId or data.id)
end)

lib.callback.register('qbx_shopcreator:management:updateEmployeePermissions', function(source, data)
    data = data or {}
    return ShopCreator.UpdateEmployeePermissions(source, data.shopId, data.employeeId or data.id, data.permissions)
end)

lib.callback.register('qbx_shopcreator:management:buyShop', function(source, data)
    data = data or {}
    return ShopCreator.BuyShop(source, data.shopId)
end)

lib.callback.register('qbx_shopcreator:management:sellShop', function(source, data)
    data = data or {}
    return ShopCreator.SellShop(source, data.shopId)
end)

lib.callback.register('qbx_shopcreator:management:transferOwnership', function(source, data)
    data = data or {}
    return ShopCreator.TransferOwnership(source, data.shopId, data.citizenid or data.targetCitizenId)
end)

--- Deliveries
lib.callback.register('qbx_shopcreator:deliveries:listDeliveryJobs', function(source)
    return ShopCreator.ListDeliveryJobs(source)
end)

lib.callback.register('qbx_shopcreator:deliveries:acceptDelivery', function(source, data)
    data = data or {}
    return ShopCreator.AcceptDelivery(source, data.jobId or data.id)
end)

lib.callback.register('qbx_shopcreator:deliveries:completeDelivery', function(source, data)
    data = data or {}
    return ShopCreator.CompleteDelivery(source, data.jobId or data.id, data.phase)
end)

lib.callback.register('qbx_shopcreator:deliveries:cancelSelfDelivery', function(source, data)
    data = data or {}
    return ShopCreator.CancelSelfDelivery(source, data.jobId or data.id)
end)

--- Garage
lib.callback.register('qbx_shopcreator:garage:takeVehicle', function(source, data)
    data = data or {}
    return ShopCreator.TakeVehicle(source, data.shopId, data.vehicleId or data.id, data.model)
end)

lib.callback.register('qbx_shopcreator:garage:storeVehicle', function(source, data)
    data = data or {}
    return ShopCreator.StoreVehicle(source, data.shopId, data.netId)
end)

--- Sync
lib.callback.register('qbx_shopcreator:sync:requestShops', function(source)
    if not ShopCreator.Cache.ready then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end
    local list = {}
    for _, shop in pairs(ShopCreator.Cache.shops) do
        if shop.enabled then
            list[#list + 1] = ShopCreator.BuildPublicPayload(shop)
        end
    end
    return { ok = true, data = list }
end)

--- Net events (alternative entry points)
RegisterNetEvent('qbx_shopcreator:server:requestShops', function()
    local src = source
    if not ShopCreator.RateLimit(src, 'request_shops', Config.RateLimit.windowMs) then return end
    ShopCreator.SyncAllPublicShops(src)
end)

RegisterNetEvent('qbx_shopcreator:server:purchase', function(shopId, cart, paymentMethod)
    local src = source
    local result = ShopCreator.Purchase(src, shopId, cart, paymentMethod)
    TriggerClientEvent('qbx_shopcreator:client:purchaseResult', src, result)
end)

RegisterNetEvent('qbx_shopcreator:server:refreshShop', function(shopId)
    local src = source
    if not ShopCreator.IsAdmin(src) then return end
    shopId = tonumber(shopId)
    if shopId then
        ShopCreator.ReloadShop(shopId)
        ShopCreator.SyncShopToClients(shopId)
    end
end)

--- Legacy NUI bridge aliases (client may map simple names to these callbacks)
lib.callback.register('qbx_shopcreator:getShops', function(source)
    return ShopCreator.ListShopsAdmin(source)
end)

lib.callback.register('qbx_shopcreator:getShop', function(source, data)
    data = data or {}
    local shopId = data.id or data.shopId
    if ShopCreator.IsAdmin(source) then
        shopId = tonumber(shopId)
        local shop = ShopCreator.Cache.shops[shopId]
        if not shop then
            return { ok = false, error = ShopCreator.L('invalid_data') }
        end
        return { ok = true, data = ShopCreator.DeepCopy(shop) }
    end
    return ShopCreator.GetShopForClient(source, shopId, 'storefront')
end)

lib.callback.register('qbx_shopcreator:saveShop', function(source, data)
    data = data or {}
    local shop = data.shop
    if not shop then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end
    if shop.id and shop.id > 0 then
        return ShopCreator.AdminUpdateShop(source, shop.id, shop)
    end
    return ShopCreator.AdminCreateShop(source, shop)
end)

lib.callback.register('qbx_shopcreator:deleteShop', function(source, data)
    data = data or {}
    return ShopCreator.AdminDeleteShop(source, data.id or data.shopId)
end)

lib.callback.register('qbx_shopcreator:getAdmins', function(source)
    if not ShopCreator.IsAdmin(source) then
        return { ok = false, error = ShopCreator.L('no_permission') }
    end
    return { ok = true, data = ShopCreator.AdminEntries or ShopCreator.ReloadAdmins() }
end)

lib.callback.register('qbx_shopcreator:addAdmin', function(source, data)
    return ShopCreator.AddAdmin(source, data and data.identifier, data and data.label)
end)

lib.callback.register('qbx_shopcreator:removeAdmin', function(source, data)
    return ShopCreator.RemoveAdmin(source, data and data.id)
end)

lib.callback.register('qbx_shopcreator:getSettings', function(source)
    if not ShopCreator.IsAdmin(source) then
        return { ok = false, error = ShopCreator.L('no_permission') }
    end
    return { ok = true, data = ShopCreator.Settings }
end)

lib.callback.register('qbx_shopcreator:saveSettings', function(source, data)
    return ShopCreator.SaveSettings(source, data)
end)

lib.callback.register('qbx_shopcreator:getInventoryItems', function(source)
    if not ShopCreator.IsAdmin(source) then
        return { ok = false, error = ShopCreator.L('no_permission') }
    end
    return ShopCreator.GetInventoryItems()
end)

lib.callback.register('qbx_shopcreator:purchase', function(source, data)
    data = data or {}
    return ShopCreator.Purchase(source, data.shopId, data.cart, data.paymentMethod or data.payment)
end)

lib.callback.register('qbx_shopcreator:buyShop', function(source, data)
    data = data or {}
    return ShopCreator.BuyShop(source, data.shopId)
end)

lib.callback.register('qbx_shopcreator:sellShop', function(source, data)
    data = data or {}
    return ShopCreator.SellShop(source, data.shopId)
end)

lib.callback.register('qbx_shopcreator:getManagementData', function(source, data)
    data = data or {}
    return ShopCreator.GetManagementData(source, data.shopId)
end)

lib.callback.register('qbx_shopcreator:updateShopStatus', function(source, data)
    data = data or {}
    return ShopCreator.UpdateShopStatus(source, data.shopId, data.is_open, data.auto_hours)
end)

lib.callback.register('qbx_shopcreator:depositFunds', function(source, data)
    data = data or {}
    return ShopCreator.DepositFunds(source, data.shopId, data.amount)
end)

lib.callback.register('qbx_shopcreator:withdrawFunds', function(source, data)
    data = data or {}
    return ShopCreator.WithdrawFunds(source, data.shopId, data.amount)
end)

lib.callback.register('qbx_shopcreator:saveCategories', function(source, data)
    data = data or {}
    return ShopCreator.SaveCategories(source, data.shopId, data.categories)
end)

lib.callback.register('qbx_shopcreator:saveProducts', function(source, data)
    data = data or {}
    return ShopCreator.SaveProducts(source, data.shopId, data.products)
end)

lib.callback.register('qbx_shopcreator:createStockOrder', function(source, data)
    data = data or {}
    return ShopCreator.CreateStockOrder(source, data.shopId, data.method, data.items)
end)

lib.callback.register('qbx_shopcreator:hireEmployee', function(source, data)
    data = data or {}
    return ShopCreator.HireEmployee(source, data.shopId, data.citizenid, data.name)
end)

lib.callback.register('qbx_shopcreator:fireEmployee', function(source, data)
    data = data or {}
    return ShopCreator.FireEmployee(source, data.shopId, data.employeeId or data.id)
end)

lib.callback.register('qbx_shopcreator:updateEmployeePermissions', function(source, data)
    data = data or {}
    return ShopCreator.UpdateEmployeePermissions(source, data.shopId, data.employeeId or data.id, data.permissions)
end)

lib.callback.register('qbx_shopcreator:getDeliveryJobs', function(source)
    return ShopCreator.ListDeliveryJobs(source)
end)

lib.callback.register('qbx_shopcreator:acceptDelivery', function(source, data)
    data = data or {}
    return ShopCreator.AcceptDelivery(source, data.jobId or data.id)
end)

lib.callback.register('qbx_shopcreator:completeDelivery', function(source, data)
    data = data or {}
    return ShopCreator.CompleteDelivery(source, data.jobId or data.id, data.phase)
end)

lib.callback.register('qbx_shopcreator:cancelSelfDelivery', function(source, data)
    data = data or {}
    return ShopCreator.CancelSelfDelivery(source, data.jobId or data.id)
end)

lib.callback.register('qbx_shopcreator:takeVehicle', function(source, data)
    data = data or {}
    return ShopCreator.TakeVehicle(source, data.shopId, data.vehicleId or data.id, data.model)
end)

lib.callback.register('qbx_shopcreator:storeVehicle', function(source, data)
    data = data or {}
    return ShopCreator.StoreVehicle(source, data.shopId, data.netId)
end)

lib.callback.register('qbx_shopcreator:spawnBusinessVehicle', function(source, data)
    data = data or {}
    return ShopCreator.TakeVehicle(source, data.shopId, data.vehicleId or data.id, data.model)
end)

lib.callback.register('qbx_shopcreator:storeBusinessVehicle', function(source, data)
    data = data or {}
    return ShopCreator.StoreVehicle(source, data.shopId, data.netId)
end)

lib.callback.register('qbx_shopcreator:listDeliveryJobs', function(source)
    return ShopCreator.ListDeliveryJobs(source)
end)

lib.callback.register('qbx_shopcreator:syncShops', function(source)
    if not ShopCreator.Cache.ready then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end
    local list = {}
    for _, shop in pairs(ShopCreator.Cache.shops) do
        if shop.enabled then
            list[#list + 1] = ShopCreator.BuildPublicPayload(shop)
        end
    end
    return { ok = true, data = list }
end)

lib.callback.register('qbx_shopcreator:isAdmin', function(source)
    return { ok = true, data = ShopCreator.IsAdmin(source) }
end)

lib.callback.register('qbx_shopcreator:useCurrentPosition', function(source)
    if not ShopCreator.IsAdmin(source) then
        return { ok = false, error = ShopCreator.L('no_permission') }
    end
    local coords = lib.callback.await('qbx_shopcreator:client:getPlayerPosition', source)
    if not coords then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end
    return { ok = true, data = coords }
end)

lib.callback.register('qbx_shopcreator:requestShops', function(source)
    if not ShopCreator.Cache.ready then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end
    local list = {}
    for _, shop in pairs(ShopCreator.Cache.shops) do
        if shop.enabled then
            list[#list + 1] = ShopCreator.BuildPublicPayload(shop)
        end
    end
    return { ok = true, data = list }
end)
