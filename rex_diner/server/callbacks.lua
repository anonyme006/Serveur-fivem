local function nearbyPlayers(source, distance)
    distance = distance or Config.PaymentDistance or 5.0
    local myPed = GetPlayerPed(source)
    if myPed == 0 then return {} end
    local myCoords = GetEntityCoords(myPed)
    local list = {}

    for _, playerId in ipairs(GetPlayers()) do
        local sid = tonumber(playerId)
        if sid and sid ~= source then
            local ped = GetPlayerPed(sid)
            if ped ~= 0 then
                local dist = #(myCoords - GetEntityCoords(ped))
                if dist <= distance then
                    list[#list + 1] = {
                        id = sid,
                        name = RexDiner.GetCharName(sid),
                        distance = math.floor(dist * 10) / 10,
                    }
                end
            end
        end
    end

    table.sort(list, function(a, b)
        return a.distance < b.distance
    end)
    return list
end

lib.callback.register('rex_diner:getTabletData', function(source)
    local ok, err, ctx = RexDiner.Authorize(source, 'tablet', false)
    if not ok then
        return { ok = false, error = err }
    end

    local firstname, lastname = RexDiner.GetCharNames(source)
    local service = RexDiner.GetServiceStats(ctx.citizenid, ctx.restaurantKey)
    local onDuty = ctx.onDuty or service.onDuty or RexDiner.ServiceCache[source] ~= nil
    local stats = RexDiner.GetStats(ctx.restaurantKey, ctx.citizenid)
    local commissionRate = GetCommissionRate(ctx.grade)

    return {
        ok = true,
        player = {
            firstname = firstname or '',
            lastname = lastname or '',
            name = ctx.name,
            grade = ctx.grade,
            gradeLabel = GetGradeLabel(ctx.grade),
            onDuty = onDuty,
            commissionRate = commissionRate,
            commissionPercent = math.floor(commissionRate * 100),
            avatar = string.sub(firstname or ctx.name or 'P', 1, 1):upper(),
        },
        restaurant = {
            key = ctx.restaurantKey,
            label = ctx.restaurant.label,
            job = ctx.restaurant.job,
        },
        permissions = Config.Permissions[ctx.grade] or Config.Permissions[0],
        stats = stats,
        service = service,
        products = GetSellableProducts(),
        recipes = GetRecipeList(),
        patchNotes = Config.PatchNotes,
        currency = Config.Currency,
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
    local ok, _, ctx = RexDiner.Authorize(source, 'tablet', false)
    if not ok then return nil end
    return RexDiner.GetStats(ctx.restaurantKey, ctx.citizenid)
end)

lib.callback.register('rex_diner:getStock', function(source)
    local ok, err, ctx = RexDiner.Authorize(source, 'stock', false)
    if not ok then return { ok = false, error = err } end
    return { ok = true, stock = RexDiner.GetStock(ctx.restaurantKey) }
end)

lib.callback.register('rex_diner:getOrders', function(source)
    local ok, err, ctx = RexDiner.Authorize(source, 'orders', false)
    if not ok then return { ok = false, error = err } end
    return { ok = true, orders = RexDiner.GetOrders(ctx.restaurantKey) }
end)

lib.callback.register('rex_diner:getSales', function(source, filters)
    local ok, err, ctx = RexDiner.Authorize(source, 'sales', false)
    if not ok then return { ok = false, error = err } end
    return { ok = true, sales = RexDiner.GetSalesHistory(ctx.restaurantKey, filters or {}) }
end)

lib.callback.register('rex_diner:getEmployees', function(source)
    local ok, err, ctx = RexDiner.Authorize(source, 'employees', false)
    if not ok then return { ok = false, error = err } end
    return { ok = true, employees = RexDiner.GetEmployees(ctx.restaurantKey) }
end)

lib.callback.register('rex_diner:getInvoices', function(source)
    local ok, err, ctx = RexDiner.Authorize(source, 'billing', false)
    if not ok then return { ok = false, error = err } end
    return { ok = true, invoices = RexDiner.GetInvoices(ctx.restaurantKey, ctx.citizenid) }
end)

lib.callback.register('rex_diner:getNearbyPlayers', function(source)
    local ok = RexDiner.Authorize(source, 'sales', false)
    if not ok then
        ok = RexDiner.Authorize(source, 'billing', false)
    end
    if not ok then return {} end
    return nearbyPlayers(source)
end)

lib.callback.register('rex_diner:toggleService', function(source)
    local success, result = RexDiner.ToggleService(source)
    return { ok = success, data = result }
end)

lib.callback.register('rex_diner:processSale', function(source, data)
    data = data or {}
    local success, result = RexDiner.ProcessSale(
        source,
        data.targetId,
        data.cart,
        data.paymentMethod,
        data.discount
    )
    if success then
        return { ok = true, sale = result }
    end
    return { ok = false, error = result }
end)

lib.callback.register('rex_diner:createInvoice', function(source, data)
    data = data or {}
    local success, result = RexDiner.CreateInvoice(source, data.targetId, data.amount, data.reason)
    if success then
        return { ok = true, invoiceId = result }
    end
    return { ok = false, error = result }
end)

lib.callback.register('rex_diner:payInvoice', function(source, data)
    data = data or {}
    local success, result = RexDiner.PayInvoice(source, data.invoiceId, data.paymentMethod)
    return { ok = success, message = result }
end)

lib.callback.register('rex_diner:cancelInvoice', function(source, invoiceId)
    local success, result = RexDiner.CancelInvoice(source, invoiceId)
    return { ok = success, message = result }
end)

lib.callback.register('rex_diner:startCraft', function(source, recipeId)
    local success, result = RexDiner.StartCraft(source, recipeId)
    if success then
        return { ok = true, craft = result }
    end
    return { ok = false, error = result }
end)

lib.callback.register('rex_diner:finishCraft', function(source, data)
    data = data or {}
    local success, result = RexDiner.FinishCraft(source, data.recipeId, data.useStock == true)
    return { ok = success, message = result }
end)

lib.callback.register('rex_diner:createOrder', function(source, items)
    local success, result = RexDiner.CreateOrder(source, items)
    return { ok = success, data = result }
end)

lib.callback.register('rex_diner:takeDelivery', function(source, deliveryId)
    local success, result = RexDiner.TakeDelivery(source, deliveryId)
    return { ok = success, data = result }
end)

lib.callback.register('rex_diner:completeDelivery', function(source, deliveryId)
    local success, result = RexDiner.CompleteDelivery(source, deliveryId)
    return { ok = success, message = result }
end)

lib.callback.register('rex_diner:hireEmployee', function(source, data)
    data = data or {}
    local success, result = RexDiner.HireEmployee(source, data.targetId, data.grade)
    return { ok = success, message = result }
end)

lib.callback.register('rex_diner:fireEmployee', function(source, citizenid)
    local success, result = RexDiner.FireEmployee(source, citizenid)
    return { ok = success, message = result }
end)

lib.callback.register('rex_diner:setEmployeeGrade', function(source, data)
    data = data or {}
    local success, result = RexDiner.SetEmployeeGrade(source, data.citizenid, data.grade)
    return { ok = success, message = result }
end)

lib.callback.register('rex_diner:getSettings', function(source)
    local ok, err, ctx = RexDiner.Authorize(source, 'settings', false)
    if not ok then return { ok = false, error = err } end
    local rows = MySQL.query.await(
        'SELECT setting_key, setting_value FROM rex_diner_settings WHERE restaurant = ?',
        { ctx.restaurantKey }
    ) or {}
    local settings = {}
    for i = 1, #rows do
        settings[rows[i].setting_key] = rows[i].setting_value
    end
    return { ok = true, settings = settings, restaurant = ctx.restaurantKey }
end)

lib.callback.register('rex_diner:saveSetting', function(source, key, value)
    local ok, err, ctx = RexDiner.Authorize(source, 'settings')
    if not ok then return { ok = false, error = err } end
    if type(key) ~= 'string' or #key > 64 then
        return { ok = false, error = 'Clé invalide.' }
    end
    value = tostring(value or ''):sub(1, 2000)
    MySQL.insert.await([[
        INSERT INTO rex_diner_settings (restaurant, setting_key, setting_value)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)
    ]], { ctx.restaurantKey, key, value })
    return { ok = true }
end)

RegisterNetEvent('rex_diner:server:openStash', function()
    local src = source
    local ok, err, ctx = RexDiner.Authorize(src, 'stock', false)
    if not ok then
        RexDiner.Notify(src, 'Stock', err, 'error')
        return
    end
    local stash = ctx.restaurant.stash
    if not stash then return end
    exports.ox_inventory:RegisterStash(stash.id, stash.label, stash.slots or 50, stash.weight or 100000, false)
    TriggerClientEvent('ox_inventory:openInventory', src, 'stash', stash.id)
end)
