--[[
    Server main — callbacks ox_lib + events
]]

local function notify(src, description, nType)
    TriggerClientEvent('ox_lib:notify', src, {
        title = _('wholesaler'),
        description = description,
        type = nType or 'inform',
        duration = Config.Notify.duration,
        position = Config.Notify.position,
    })
end

local function getPlayerJob(source)
    local player = Payment.GetPlayer(source)
    if not player then return nil end
    return player.PlayerData.job, player
end

--------------------------------------------------------------------------------
-- Bootstrap
--------------------------------------------------------------------------------
CreateThread(function()
    Wait(500)
    DB.Init()
    DB.SyncProducts()
    Stock.RefreshCache()
    Orders.ResumePending()
    print('^2[core_wholesaler]^0 initialized successfully')
end)

--------------------------------------------------------------------------------
-- Callbacks — accès / stock / panier
--------------------------------------------------------------------------------
lib.callback.register('core_wholesaler:getAccess', function(source)
    local job, player = getPlayerJob(source)
    if not player then return { ok = false } end

    local isWholesaler = job.name == Config.Job.name
    local isBuyer = Config.AllowedCompanies[job.name] ~= nil
    local isTransporter = Delivery.IsTransporter(player)
    local isAdmin = Admin.HasPermission(source, Config.Permissions.manageStock)
    local isBoss = Admin.CanBoss(source)

    local categories = Config.AllowedCompanies[job.name]
    if isWholesaler or isAdmin then
        categories = '*'
    end

    return {
        ok = true,
        job = job.name,
        grade = job.grade and job.grade.level or 0,
        label = job.label,
        isWholesaler = isWholesaler,
        isBuyer = isBuyer,
        isTransporter = isTransporter,
        isAdmin = isAdmin,
        isBoss = isBoss,
        categories = categories,
        paymentMethods = Config.Payment.methods,
        deliveryEnabled = Config.Delivery.enabled,
        exportEnabled = Config.Export.enabled,
    }
end)

lib.callback.register('core_wholesaler:getStock', function(source, categoryFilter)
    local job, player = getPlayerJob(source)
    if not player then return {} end

    local cats = categoryFilter
    if not cats then
        if job.name == Config.Job.name or Admin.HasPermission(source) then
            cats = nil -- all
        else
            cats = Config.AllowedCompanies[job.name]
            if cats == '*' then cats = nil end
            if not cats then return {} end
        end
    end

    local stock = Stock.GetAll(cats)
    -- Enrichir avec images
    for i = 1, #stock do
        stock[i].imageUrl = Wholesaler.ItemImage(stock[i].image, stock[i].item)
        stock[i].categoryLabel = Config.Categories[stock[i].category]
            and Config.Categories[stock[i].category].label
            or stock[i].category
    end
    return stock
end)

lib.callback.register('core_wholesaler:getCategories', function(source)
    local job = getPlayerJob(source)
    if not job then return {} end

    local allowed = Config.AllowedCompanies[job.name]
    if job.name == Config.Job.name or Admin.HasPermission(source) then
        allowed = '*'
    end
    if not allowed then return {} end

    local list = {}
    for catId, cat in pairs(Config.Categories) do
        if allowed == '*' or Wholesaler.CanAccessCategory(job.name, catId) then
            list[#list + 1] = {
                id = catId,
                label = cat.label,
                icon = cat.icon,
            }
        end
    end
    table.sort(list, function(a, b) return a.label < b.label end)
    return list
end)

--------------------------------------------------------------------------------
-- Commandes
--------------------------------------------------------------------------------
lib.callback.register('core_wholesaler:createOrder', function(source, data)
    if type(data) ~= 'table' then return { ok = false, err = 'error' } end

    local orderId, err = Orders.Create(
        source,
        data.cart,
        data.method or 'society',
        data.fulfillment or 'pickup',
        data.deliveryCoords
    )

    if not orderId then
        return { ok = false, err = err or 'error' }
    end

    notify(source, _('order_created', orderId), 'success')
    return { ok = true, orderId = orderId }
end)

lib.callback.register('core_wholesaler:getMyOrders', function(source)
    local player = Payment.GetPlayer(source)
    if not player then return {} end
    local rows = Orders.GetByCitizen(player.PlayerData.citizenid)
    for _, row in ipairs(rows) do
        row.items = json.decode(row.items) or {}
        row.statusLabel = Wholesaler.StatusLabel(row.status)
    end
    return rows
end)

lib.callback.register('core_wholesaler:getHistory', function(source)
    local player = Payment.GetPlayer(source)
    if not player then return {} end
    return Orders.GetHistory(player.PlayerData.citizenid)
end)

lib.callback.register('core_wholesaler:getPickupOrders', function(source)
    local player = Payment.GetPlayer(source)
    if not player then return {} end
    local rows = Orders.GetAvailablePickup(player.PlayerData.citizenid)
    for _, row in ipairs(rows) do
        row.items = json.decode(row.items) or {}
    end
    return rows
end)

lib.callback.register('core_wholesaler:withdrawOrder', function(source, orderId)
    orderId = tonumber(orderId)
    if not orderId then return { ok = false, err = 'error' } end

    local ok, err = Orders.Withdraw(source, orderId)
    if not ok then
        return { ok = false, err = err or 'error' }
    end
    notify(source, _('pickup_success', orderId), 'success')
    return { ok = true }
end)

--------------------------------------------------------------------------------
-- Livraisons
--------------------------------------------------------------------------------
lib.callback.register('core_wholesaler:getDeliveries', function(source)
    local player = Payment.GetPlayer(source)
    if not player or not Delivery.IsTransporter(player) then return {} end

    local rows = Delivery.GetAvailable()
    for _, row in ipairs(rows) do
        row.items = json.decode(row.items) or {}
        if row.delivery_coords then
            row.delivery_coords = json.decode(row.delivery_coords)
        end
    end
    return rows
end)

lib.callback.register('core_wholesaler:takeDelivery', function(source, orderId)
    orderId = tonumber(orderId)
    if not orderId then return { ok = false, err = 'error' } end

    local ok, err, order = Delivery.Take(source, orderId)
    if not ok then return { ok = false, err = err or 'error' } end

    local coords
    if order.delivery_coords then
        coords = json.decode(order.delivery_coords)
    end

    notify(source, _('delivery_started', orderId), 'success')
    return {
        ok = true,
        orderId = orderId,
        reward = order.delivery_reward,
        company = order.company,
        items = json.decode(order.items) or {},
        dropoff = coords,
        dock = {
            x = Config.Warehouse.loadingDock.coords.x,
            y = Config.Warehouse.loadingDock.coords.y,
            z = Config.Warehouse.loadingDock.coords.z,
        },
    }
end)

lib.callback.register('core_wholesaler:loadDelivery', function(source, orderId)
    local ok, err = Delivery.Load(source, tonumber(orderId))
    if not ok then return { ok = false, err = err } end
    notify(source, _('delivery_loaded'), 'inform')
    return { ok = true }
end)

lib.callback.register('core_wholesaler:completeDelivery', function(source, orderId)
    local ok, err, reward = Delivery.Complete(source, tonumber(orderId))
    if not ok then return { ok = false, err = err } end
    notify(source, _('delivery_complete', orderId, Wholesaler.FormatMoney(reward or 0)), 'success')
    return { ok = true, reward = reward }
end)

--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------
lib.callback.register('core_wholesaler:getExportDestinations', function(source)
    if not Admin.HasPermission(source, Config.Export.minGrade) then return {} end
    return Config.Export.destinations
end)

lib.callback.register('core_wholesaler:startExport', function(source, data)
    if type(data) ~= 'table' then return { ok = false, err = 'error' } end
    local ok, err, exportData = Export.Start(source, data.destination, data.cart)
    if not ok then return { ok = false, err = err or 'error' } end

    notify(source, _('export_started', exportData.destination.label), 'success')
    return {
        ok = true,
        id = exportData.id,
        reward = exportData.reward,
        destination = {
            id = exportData.destination.id,
            label = exportData.destination.label,
            x = exportData.destination.coords.x,
            y = exportData.destination.coords.y,
            z = exportData.destination.coords.z,
            heading = exportData.destination.heading,
            blip = exportData.destination.blip,
        },
        vehicle = Config.Export.vehicle,
        spawn = {
            x = Config.Warehouse.loadingDock.spawn.x,
            y = Config.Warehouse.loadingDock.spawn.y,
            z = Config.Warehouse.loadingDock.spawn.z,
            w = Config.Warehouse.loadingDock.spawn.w,
        },
    }
end)

lib.callback.register('core_wholesaler:completeExport', function(source, exportId)
    local ok, err, reward = Export.Complete(source, tonumber(exportId))
    if not ok then return { ok = false, err = err } end
    notify(source, _('export_complete', Wholesaler.FormatMoney(reward or 0)), 'success')
    return { ok = true, reward = reward }
end)

--------------------------------------------------------------------------------
-- Admin / Boss
--------------------------------------------------------------------------------
lib.callback.register('core_wholesaler:bossFinance', function(source)
    if not Admin.CanBoss(source) then return nil end
    return Boss.GetFinance()
end)

lib.callback.register('core_wholesaler:bossOrders', function(source)
    if not Admin.CanBoss(source) then return {} end
    local rows = Orders.GetAll(100)
    for _, row in ipairs(rows) do
        row.items = json.decode(row.items) or {}
        row.statusLabel = Wholesaler.StatusLabel(row.status)
    end
    return rows
end)

lib.callback.register('core_wholesaler:bossCompanies', function(source)
    if not Admin.CanBoss(source) then return {} end
    return Boss.GetCompanies()
end)

lib.callback.register('core_wholesaler:bossEmployees', function(source)
    if not Admin.CanBoss(source) then return {} end
    return Boss.GetEmployees()
end)

lib.callback.register('core_wholesaler:addStock', function(source, item, qty)
    if not Admin.HasPermission(source, Config.Permissions.manageStock) then
        return { ok = false, err = 'no_permission' }
    end
    qty = math.floor(tonumber(qty) or 0)
    if qty < 1 then return { ok = false, err = 'invalid_amount' } end
    if not Stock.Add(item, qty) then return { ok = false, err = 'error' } end

    local player = Payment.GetPlayer(source)
    DB.LogHistory({
        citizenid = player and player.PlayerData.citizenid or 'admin',
        company = Config.Job.name,
        action = 'stock_add',
        details = { item = item, qty = qty },
    })

    local product = Stock.Get(item)
    notify(source, _('stock_added', qty, product and product.label or item), 'success')
    return { ok = true }
end)

lib.callback.register('core_wholesaler:removeStock', function(source, item, qty)
    if not Admin.HasPermission(source, Config.Permissions.manageStock) then
        return { ok = false, err = 'no_permission' }
    end
    qty = math.floor(tonumber(qty) or 0)
    if qty < 1 then return { ok = false, err = 'invalid_amount' } end
    if not Stock.Remove(item, qty) then return { ok = false, err = 'out_of_stock' } end

    local player = Payment.GetPlayer(source)
    DB.LogHistory({
        citizenid = player and player.PlayerData.citizenid or 'admin',
        company = Config.Job.name,
        action = 'stock_remove',
        details = { item = item, qty = qty },
    })

    local product = Stock.Get(item)
    notify(source, _('stock_removed', qty, product and product.label or item), 'success')
    return { ok = true }
end)

lib.callback.register('core_wholesaler:setPrice', function(source, item, price)
    if not Admin.CanManagePrices(source) then
        return { ok = false, err = 'no_permission' }
    end
    price = math.floor(tonumber(price) or -1)
    if price < 0 then return { ok = false, err = 'invalid_amount' } end
    if not Stock.SetPrice(item, price) then return { ok = false, err = 'error' } end

    local product = Stock.Get(item)
    notify(source, _('price_updated', product and product.label or item, Wholesaler.FormatMoney(price)), 'success')
    return { ok = true }
end)

lib.callback.register('core_wholesaler:importDelivery', function(source, items)
    if not Admin.HasPermission(source, Config.Permissions.manageStock) then
        return { ok = false, err = 'no_permission' }
    end
    if type(items) ~= 'table' then return { ok = false, err = 'error' } end

    local count = Stock.Import(items)
    notify(source, _('import_success', count), 'success')
    return { ok = true, count = count }
end)

lib.callback.register('core_wholesaler:hire', function(source, targetId, grade)
    local ok, err = Boss.Hire(source, tonumber(targetId), grade)
    if not ok then return { ok = false, err = err or 'error' } end

    local target = Payment.GetPlayer(tonumber(targetId))
    notify(source, _('employee_hired', target and Payment.GetName(target) or '?'), 'success')
    if target then
        notify(tonumber(targetId), _('employee_hired', Payment.GetName(target)), 'inform')
    end
    return { ok = true }
end)

lib.callback.register('core_wholesaler:fire', function(source, citizenid)
    local ok, err = Boss.Fire(source, citizenid)
    if not ok then return { ok = false, err = err or 'error' } end
    notify(source, _('employee_fired', citizenid), 'success')
    return { ok = true }
end)

lib.callback.register('core_wholesaler:setGrade', function(source, citizenid, grade)
    local ok, err = Boss.SetGrade(source, citizenid, tonumber(grade))
    if not ok then return { ok = false, err = err or 'error' } end
    return { ok = true }
end)

lib.callback.register('core_wholesaler:prepareOrder', function(source, orderId)
    if not Admin.CanPrepare(source) then
        return { ok = false, err = 'no_permission' }
    end
    if not Orders.MarkPrepared(tonumber(orderId)) then
        return { ok = false, err = 'error' }
    end
    return { ok = true }
end)

lib.callback.register('core_wholesaler:calcTotal', function(_, cart)
    if type(cart) ~= 'table' then return { subtotal = 0, tax = 0, vat = 0, total = 0 } end
    local subtotal = 0
    for _, line in ipairs(cart) do
        local product = Stock.Get(line.item)
        if product then
            subtotal = subtotal + product.price * (math.floor(tonumber(line.qty) or 0))
        end
    end
    local tax, vat, total = Wholesaler.CalcTaxes(subtotal)
    return { subtotal = subtotal, tax = tax, vat = vat, total = total }
end)

--- Joueurs proches (recrutement)
lib.callback.register('core_wholesaler:getNearbyPlayers', function(source)
    if not Admin.CanBoss(source) then return {} end
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local list = {}

    local players = exports.qbx_core:GetQBPlayers()
    for src, ply in pairs(players or {}) do
        if src ~= source then
            local tped = GetPlayerPed(src)
            if tped and tped ~= 0 then
                local tcoords = GetEntityCoords(tped)
                if #(coords - tcoords) < 5.0 then
                    list[#list + 1] = {
                        id = src,
                        name = Payment.GetName(ply),
                        citizenid = ply.PlayerData.citizenid,
                    }
                end
            end
        end
    end
    return list
end)
