lib.callback.register('rex_diner:getTabletData', function(source)
    local ok, err, ctx = Rex.Authorize(source, 'tablet', false)
    if not ok then return { ok = false, error = err } end

    local firstname, lastname = Rex.GetNames(source)
    local service = Rex.GetServiceStats(ctx.citizenid, ctx.key)
    local onDuty = ctx.onDuty or service.onDuty
    local rate = Rex.GetCommissionRate(ctx.grade)

    return {
        ok = true,
        player = {
            firstname = firstname,
            lastname = lastname,
            name = ctx.name,
            grade = ctx.grade,
            gradeLabel = Rex.GetGradeLabel(ctx.grade),
            onDuty = onDuty,
            commissionRate = rate,
            commissionPercent = math.floor(rate * 100),
            avatar = string.sub(firstname ~= '' and firstname or ctx.name or 'R', 1, 1):upper(),
        },
        restaurant = { key = ctx.key, label = ctx.restaurant.label, job = ctx.restaurant.job },
        permissions = Config.Permissions[ctx.grade] or Config.Permissions[0],
        stats = Rex.GetStats(ctx.key, ctx.citizenid),
        service = service,
        products = Rex.GetSellableProducts(ctx.key),
        recipes = Rex.GetRecipeList(ctx.key),
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

lib.callback.register('rex_diner:getStats', function(source)
    local ok, _, ctx = Rex.Authorize(source, 'tablet', false)
    if not ok then return nil end
    return Rex.GetStats(ctx.key, ctx.citizenid)
end)

lib.callback.register('rex_diner:getStock', function(source)
    local ok, err, ctx = Rex.Authorize(source, 'stock', false)
    if not ok then return { ok = false, error = err } end
    return { ok = true, stock = Rex.GetStock(ctx.key) }
end)

lib.callback.register('rex_diner:getOrders', function(source)
    local ok, err, ctx = Rex.Authorize(source, 'orders', false)
    if not ok then return { ok = false, error = err } end
    return { ok = true, orders = Rex.GetOrders(ctx.key) }
end)

lib.callback.register('rex_diner:getSales', function(source, filters)
    local ok, err, ctx = Rex.Authorize(source, 'sales', false)
    if not ok then return { ok = false, error = err } end
    return { ok = true, sales = Rex.GetSales(ctx.key, filters or {}) }
end)

lib.callback.register('rex_diner:getEmployees', function(source)
    local ok, err, ctx = Rex.Authorize(source, 'employees', false)
    if not ok then return { ok = false, error = err } end
    return { ok = true, employees = Rex.GetEmployees(ctx.key) }
end)

lib.callback.register('rex_diner:getInvoices', function(source)
    local ok, err, ctx = Rex.Authorize(source, 'billing', false)
    if not ok then return { ok = false, error = err } end
    return { ok = true, invoices = Rex.GetInvoices(ctx.key, ctx.citizenid) }
end)

lib.callback.register('rex_diner:getNearbyPlayers', function(source)
    local ok = select(1, Rex.Authorize(source, 'sales', false))
        or select(1, Rex.Authorize(source, 'billing', false))
        or select(1, Rex.Authorize(source, 'employees', false))
    if not ok then return {} end
    return Rex.GetNearbyPlayers(source)
end)

lib.callback.register('rex_diner:toggleService', function(source)
    local success, result = Rex.ToggleService(source)
    return { ok = success, data = result }
end)

lib.callback.register('rex_diner:processSale', function(source, data)
    data = data or {}
    local success, result = Rex.ProcessSale(source, data.targetId, data.cart, data.paymentMethod, data.discount)
    return success and { ok = true, sale = result } or { ok = false, error = result }
end)

lib.callback.register('rex_diner:createInvoice', function(source, data)
    data = data or {}
    local success, result = Rex.CreateInvoice(source, data.targetId, data.amount, data.reason)
    return success and { ok = true, invoiceId = result } or { ok = false, error = result }
end)

lib.callback.register('rex_diner:payInvoice', function(source, data)
    data = data or {}
    local success, result = Rex.PayInvoice(source, data.invoiceId, data.paymentMethod)
    return { ok = success, message = result }
end)

lib.callback.register('rex_diner:cancelInvoice', function(source, invoiceId)
    local success, result = Rex.CancelInvoice(source, invoiceId)
    return { ok = success, message = result }
end)

lib.callback.register('rex_diner:startCraft', function(source, recipeId)
    local success, result = Rex.StartCraft(source, recipeId)
    return success and { ok = true, craft = result } or { ok = false, error = result }
end)

lib.callback.register('rex_diner:finishCraft', function(source, data)
    data = data or {}
    local success, result = Rex.FinishCraft(source, data.recipeId, data.useStock == true)
    return { ok = success, message = result }
end)

lib.callback.register('rex_diner:createOrder', function(source, items)
    local success, result = Rex.CreateOrder(source, items)
    return { ok = success, data = result }
end)

lib.callback.register('rex_diner:takeDelivery', function(source, deliveryId)
    local success, result = Rex.TakeDelivery(source, deliveryId)
    return { ok = success, data = result }
end)

lib.callback.register('rex_diner:completeDelivery', function(source, deliveryId)
    local success, result = Rex.CompleteDelivery(source, deliveryId)
    return { ok = success, message = result }
end)

lib.callback.register('rex_diner:hireEmployee', function(source, data)
    data = data or {}
    local success, result = Rex.HireEmployee(source, data.targetId, data.grade)
    return { ok = success, message = result }
end)

lib.callback.register('rex_diner:fireEmployee', function(source, citizenid)
    local success, result = Rex.FireEmployee(source, citizenid)
    return { ok = success, message = result }
end)

lib.callback.register('rex_diner:setEmployeeGrade', function(source, data)
    data = data or {}
    local success, result = Rex.SetEmployeeGrade(source, data.citizenid, data.grade)
    return { ok = success, message = result }
end)

lib.callback.register('rex_diner:getSettings', function(source)
    local ok, err, ctx = Rex.Authorize(source, 'settings', false)
    if not ok then return { ok = false, error = err } end
    local rows = MySQL.query.await(
        'SELECT setting_key, setting_value FROM rex_diner_settings WHERE restaurant = ?',
        { ctx.key }
    ) or {}
    local settings = {}
    for i = 1, #rows do settings[rows[i].setting_key] = rows[i].setting_value end
    return { ok = true, settings = settings, restaurant = ctx.key }
end)

lib.callback.register('rex_diner:saveSetting', function(source, key, value)
    local ok, err, ctx = Rex.Authorize(source, 'settings')
    if not ok then return { ok = false, error = err } end
    if type(key) ~= 'string' or #key > 64 then return { ok = false, error = 'Clé invalide.' } end
    MySQL.insert.await([[
        INSERT INTO rex_diner_settings (restaurant, setting_key, setting_value)
        VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)
    ]], { ctx.key, key, tostring(value or ''):sub(1, 2000) })
    return { ok = true }
end)

RegisterNetEvent('rex_diner:server:openStash', function()
    local src = source
    local ok, err, ctx = Rex.Authorize(src, 'stock', false)
    if not ok then
        Rex.Notify(src, 'Stock', err, 'error')
        return
    end
    local stash = ctx.restaurant.stash
    if not stash then return end
    exports.ox_inventory:RegisterStash(stash.id, stash.label, stash.slots or 50, stash.weight or 100000, false)
    TriggerClientEvent('ox_inventory:openInventory', src, 'stash', stash.id)
end)
