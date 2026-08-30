lib.callback.register('qbox_restaurants:getTabletData', function(source)
    local ok, err, ctx = Rest.Authorize(source, 'tablet', false)
    if not ok then return { ok = false, error = err } end

    local firstname, lastname = Rest.GetNames(source)
    local service = Rest.GetServiceStats(ctx.citizenid, ctx.key)
    local onDuty = ctx.onDuty or service.onDuty
    local rate = Rest.GetCommissionRate(ctx.grade)

    return {
        ok = true,
        player = {
            firstname = firstname,
            lastname = lastname,
            name = ctx.name,
            grade = ctx.grade,
            gradeLabel = Rest.GetGradeLabel(ctx.grade),
            onDuty = onDuty,
            commissionRate = rate,
            commissionPercent = math.floor(rate * 100),
            avatar = string.sub(firstname ~= '' and firstname or ctx.name or 'R', 1, 1):upper(),
        },
        restaurant = { key = ctx.key, label = ctx.restaurant.label, job = ctx.restaurant.job },
        permissions = Config.Permissions[ctx.grade] or Config.Permissions[0],
        stats = Rest.GetStats(ctx.key, ctx.citizenid),
        service = service,
        products = Rest.GetSellableProducts(ctx.key),
        recipes = Rest.GetRecipeList(ctx.key),
        patchNotes = Config.PatchNotes,
        currency = Config.Currency,
        maxDiscount = Config.MaxDiscount or 50,
        features = {
            billing = Config.EnableBilling,
            deliveries = Config.EnableDeliveries,
            crafting = Config.EnableCrafting,
            employees = Config.EnableEmployeeManagement,
            stock = Config.EnableStock,
        },
    }
end)

lib.callback.register('qbox_restaurants:getStats', function(source)
    local ok, _, ctx = Rest.Authorize(source, 'tablet', false)
    if not ok then return nil end
    return Rest.GetStats(ctx.key, ctx.citizenid)
end)

lib.callback.register('qbox_restaurants:getStock', function(source)
    local ok, err, ctx = Rest.Authorize(source, 'stock', false)
    if not ok then return { ok = false, error = err } end
    return { ok = true, stock = Rest.GetStock(ctx.key) }
end)

lib.callback.register('qbox_restaurants:getOrders', function(source)
    local ok, err, ctx = Rest.Authorize(source, 'orders', false)
    if not ok then return { ok = false, error = err } end
    return { ok = true, orders = Rest.GetOrders(ctx.key) }
end)

lib.callback.register('qbox_restaurants:getSales', function(source, filters)
    local ok, err, ctx = Rest.Authorize(source, 'sales', false)
    if not ok then return { ok = false, error = err } end
    return { ok = true, sales = Rest.GetSales(ctx.key, filters or {}) }
end)

lib.callback.register('qbox_restaurants:getEmployees', function(source)
    local ok, err, ctx = Rest.Authorize(source, 'employees', false)
    if not ok then return { ok = false, error = err } end
    return { ok = true, employees = Rest.GetEmployees(ctx.key) }
end)

lib.callback.register('qbox_restaurants:getInvoices', function(source)
    local ok, err, ctx = Rest.Authorize(source, 'billing', false)
    if not ok then return { ok = false, error = err } end
    return { ok = true, invoices = Rest.GetInvoices(ctx.key, ctx.citizenid) }
end)

lib.callback.register('qbox_restaurants:getNearbyPlayers', function(source)
    local ok = select(1, Rest.Authorize(source, 'sales', false))
        or select(1, Rest.Authorize(source, 'billing', false))
        or select(1, Rest.Authorize(source, 'employees', false))
    if not ok then return {} end
    return Rest.GetNearbyPlayers(source)
end)

lib.callback.register('qbox_restaurants:toggleService', function(source)
    local success, result = Rest.ToggleService(source)
    return { ok = success, data = result }
end)

lib.callback.register('qbox_restaurants:processSale', function(source, data)
    data = data or {}
    local success, result = Rest.ProcessSale(source, data.targetId, data.cart, data.paymentMethod, data.discount)
    return success and { ok = true, sale = result } or { ok = false, error = result }
end)

lib.callback.register('qbox_restaurants:createInvoice', function(source, data)
    data = data or {}
    local success, result = Rest.CreateInvoice(source, data.targetId, data.amount, data.reason)
    return success and { ok = true, invoiceId = result } or { ok = false, error = result }
end)

lib.callback.register('qbox_restaurants:payInvoice', function(source, data)
    data = data or {}
    local success, result = Rest.PayInvoice(source, data.invoiceId, data.paymentMethod)
    return { ok = success, message = result }
end)

lib.callback.register('qbox_restaurants:cancelInvoice', function(source, invoiceId)
    local success, result = Rest.CancelInvoice(source, invoiceId)
    return { ok = success, message = result }
end)

lib.callback.register('qbox_restaurants:startCraft', function(source, recipeId)
    local success, result = Rest.StartCraft(source, recipeId)
    return success and { ok = true, craft = result } or { ok = false, error = result }
end)

lib.callback.register('qbox_restaurants:finishCraft', function(source, data)
    data = data or {}
    local success, result = Rest.FinishCraft(source, data.recipeId, data.useStock == true)
    return { ok = success, message = result }
end)

lib.callback.register('qbox_restaurants:createOrder', function(source, items)
    local success, result = Rest.CreateOrder(source, items)
    return { ok = success, data = result }
end)

lib.callback.register('qbox_restaurants:takeDelivery', function(source, deliveryId)
    local success, result = Rest.TakeDelivery(source, deliveryId)
    return { ok = success, data = result }
end)

lib.callback.register('qbox_restaurants:completeDelivery', function(source, deliveryId)
    local success, result = Rest.CompleteDelivery(source, deliveryId)
    return { ok = success, message = result }
end)

lib.callback.register('qbox_restaurants:hireEmployee', function(source, data)
    data = data or {}
    local success, result = Rest.HireEmployee(source, data.targetId, data.grade)
    return { ok = success, message = result }
end)

lib.callback.register('qbox_restaurants:fireEmployee', function(source, citizenid)
    local success, result = Rest.FireEmployee(source, citizenid)
    return { ok = success, message = result }
end)

lib.callback.register('qbox_restaurants:setEmployeeGrade', function(source, data)
    data = data or {}
    local success, result = Rest.SetEmployeeGrade(source, data.citizenid, data.grade)
    return { ok = success, message = result }
end)

lib.callback.register('qbox_restaurants:getSettings', function(source)
    local ok, err, ctx = Rest.Authorize(source, 'settings', false)
    if not ok then return { ok = false, error = err } end
    local rows = MySQL.query.await(
        'SELECT setting_key, setting_value FROM qbox_restaurants_settings WHERE restaurant = ?',
        { ctx.key }
    ) or {}
    local settings = {}
    for i = 1, #rows do settings[rows[i].setting_key] = rows[i].setting_value end
    return { ok = true, settings = settings, restaurant = ctx.key }
end)

lib.callback.register('qbox_restaurants:saveSetting', function(source, key, value)
    local ok, err, ctx = Rest.Authorize(source, 'settings')
    if not ok then return { ok = false, error = err } end
    if type(key) ~= 'string' or #key > 64 then return { ok = false, error = 'Clé invalide.' } end
    MySQL.insert.await([[
        INSERT INTO qbox_restaurants_settings (restaurant, setting_key, setting_value)
        VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)
    ]], { ctx.key, key, tostring(value or ''):sub(1, 2000) })
    return { ok = true }
end)

RegisterNetEvent('qbox_restaurants:server:openStash', function()
    local src = source
    local ok, err, ctx = Rest.Authorize(src, 'stock', false)
    if not ok then
        Rest.Notify(src, 'Stock', err, 'error')
        return
    end
    local stash = ctx.restaurant.stash
    if not stash then return end
    exports.ox_inventory:RegisterStash(stash.id, stash.label, stash.slots or 50, stash.weight or 100000, false)
    TriggerClientEvent('ox_inventory:openInventory', src, 'stash', stash.id)
end)
