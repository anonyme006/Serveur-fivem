ShopCreator = ShopCreator or {}
ShopCreator.Repository = ShopCreator.Repository or {}

local Repo = ShopCreator.Repository

---@param value any
---@return boolean
local function toBool(value)
    return value == true or value == 1 or value == '1'
end

---@param row table
---@return table
function Repo.NormalizeShopRow(row)
    if not row then return nil end
    return {
        id = row.id,
        slug = row.slug,
        name = row.name,
        description = row.description or '',
        logo_url = row.logo_url or '',
        enabled = toBool(row.enabled),
        infinite_stock = toBool(row.infinite_stock),
        default_stock = tonumber(row.default_stock) or 0,
        storage_capacity = tonumber(row.storage_capacity) or Config.Stock.defaultCapacity,
        auto_hours = toBool(row.auto_hours),
        open_hour = tonumber(row.open_hour) or 8,
        close_hour = tonumber(row.close_hour) or 22,
        is_open = toBool(row.is_open),
        ownership_mode = row.ownership_mode or 'none',
        owner_citizenid = row.owner_citizenid,
        buy_price = tonumber(row.buy_price) or 0,
        resale_enabled = toBool(row.resale_enabled),
        resale_percent = tonumber(row.resale_percent) or Config.Ownership.defaultResalePercent,
        balance = tonumber(row.balance) or 0,
        allow_cash = toBool(row.allow_cash),
        allow_bank = toBool(row.allow_bank),
        blip = {
            enabled = toBool(row.blip_enabled),
            sprite = tonumber(row.blip_sprite) or Config.Blip.sprite,
            color = tonumber(row.blip_color) or Config.Blip.color,
            scale = tonumber(row.blip_scale) or Config.Blip.scale,
            name = row.blip_name or row.name or '',
        },
        npc = {
            enabled = toBool(row.npc_enabled),
            model = row.npc_model or Config.Npc.model,
            scenario = row.npc_scenario or Config.Npc.scenario,
            x = row.npc_x,
            y = row.npc_y,
            z = row.npc_z,
            w = row.npc_w,
        },
        created_at = row.created_at,
        updated_at = row.updated_at,
    }
end

function Repo.RunMigration()
    local sql = LoadResourceFile(ShopCreator.Resource, 'sql/install.sql')
    if not sql or sql == '' then
        ShopCreator.Log('migration_skipped', { reason = 'empty_sql' })
        return false
    end

    for statement in sql:gmatch('([^;]+);') do
        local trimmed = statement:match('^%s*(.-)%s*$')
        if trimmed and trimmed ~= '' then
            MySQL.query.await(trimmed)
        end
    end

    ShopCreator.Log('migration_complete', {})
    return true
end

function Repo.LoadAdmins()
    local rows = MySQL.query.await('SELECT id, identifier, label FROM shopcreator_admins ORDER BY id ASC') or {}
    local list = {}
    local map = {}

    for i = 1, #rows do
        local row = rows[i]
        list[#list + 1] = {
            id = row.id,
            identifier = row.identifier,
            label = row.label or '',
        }
        map[row.identifier] = true
    end

    return list, map
end

function Repo.InsertAdmin(identifier, label)
    return MySQL.insert.await(
        'INSERT INTO shopcreator_admins (identifier, label) VALUES (?, ?)',
        { identifier, label }
    )
end

function Repo.DeleteAdmin(id)
    return MySQL.update.await('DELETE FROM shopcreator_admins WHERE id = ?', { id })
end

function Repo.AdminExists(identifier)
    local id = MySQL.scalar.await(
        'SELECT id FROM shopcreator_admins WHERE identifier = ? LIMIT 1',
        { identifier }
    )
    return id ~= nil
end

function Repo.LoadShopRows()
    return MySQL.query.await('SELECT * FROM shopcreator_shops ORDER BY id ASC') or {}
end

function Repo.LoadLocationsForShops(shopIds)
    if not shopIds or #shopIds == 0 then return {} end
    local placeholders = table.concat((function()
        local t = {}
        for _ = 1, #shopIds do t[#t + 1] = '?' end
        return t
    end)(), ',')
    return MySQL.query.await(
        ('SELECT * FROM shopcreator_locations WHERE shop_id IN (%s) ORDER BY shop_id ASC, id ASC'):format(placeholders),
        shopIds
    ) or {}
end

function Repo.LoadCategoriesForShops(shopIds)
    if not shopIds or #shopIds == 0 then return {} end
    local placeholders = table.concat((function()
        local t = {}
        for _ = 1, #shopIds do t[#t + 1] = '?' end
        return t
    end)(), ',')
    return MySQL.query.await(
        ('SELECT * FROM shopcreator_categories WHERE shop_id IN (%s) ORDER BY shop_id ASC, sort_order ASC, id ASC'):format(placeholders),
        shopIds
    ) or {}
end

function Repo.LoadProductsForShops(shopIds)
    if not shopIds or #shopIds == 0 then return {} end
    local placeholders = table.concat((function()
        local t = {}
        for _ = 1, #shopIds do t[#t + 1] = '?' end
        return t
    end)(), ',')
    return MySQL.query.await(
        ('SELECT * FROM shopcreator_products WHERE shop_id IN (%s) ORDER BY shop_id ASC, sort_order ASC, id ASC'):format(placeholders),
        shopIds
    ) or {}
end

function Repo.LoadEmployeesForShops(shopIds)
    if not shopIds or #shopIds == 0 then return {} end
    local placeholders = table.concat((function()
        local t = {}
        for _ = 1, #shopIds do t[#t + 1] = '?' end
        return t
    end)(), ',')
    return MySQL.query.await(
        ('SELECT * FROM shopcreator_employees WHERE shop_id IN (%s) ORDER BY shop_id ASC, id ASC'):format(placeholders),
        shopIds
    ) or {}
end

function Repo.LoadVehiclesForShops(shopIds)
    if not shopIds or #shopIds == 0 then return {} end
    local placeholders = table.concat((function()
        local t = {}
        for _ = 1, #shopIds do t[#t + 1] = '?' end
        return t
    end)(), ',')
    return MySQL.query.await(
        ('SELECT * FROM shopcreator_business_vehicles WHERE shop_id IN (%s) ORDER BY shop_id ASC, id ASC'):format(placeholders),
        shopIds
    ) or {}
end

function Repo.CountPendingOrders(shopId)
    return MySQL.scalar.await(
        [[SELECT COUNT(*) FROM shopcreator_stock_orders
          WHERE shop_id = ? AND status IN ('pending', 'accepted', 'in_transit')]],
        { shopId }
    ) or 0
end

function Repo.SlugExists(slug, excludeId)
    if excludeId then
        local id = MySQL.scalar.await(
            'SELECT id FROM shopcreator_shops WHERE slug = ? AND id <> ? LIMIT 1',
            { slug, excludeId }
        )
        return id ~= nil
    end
    local id = MySQL.scalar.await('SELECT id FROM shopcreator_shops WHERE slug = ? LIMIT 1', { slug })
    return id ~= nil
end

function Repo.InsertShop(shop)
    return MySQL.insert.await([[
        INSERT INTO shopcreator_shops (
            slug, name, description, logo_url, enabled, infinite_stock, default_stock, storage_capacity,
            auto_hours, open_hour, close_hour, is_open, ownership_mode, owner_citizenid, buy_price,
            resale_enabled, resale_percent, balance, allow_cash, allow_bank,
            blip_enabled, blip_sprite, blip_color, blip_scale, blip_name,
            npc_enabled, npc_model, npc_scenario, npc_x, npc_y, npc_z, npc_w
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        shop.slug,
        shop.name,
        shop.description,
        shop.logo_url,
        shop.enabled and 1 or 0,
        shop.infinite_stock and 1 or 0,
        shop.default_stock,
        shop.storage_capacity,
        shop.auto_hours and 1 or 0,
        shop.open_hour,
        shop.close_hour,
        shop.is_open and 1 or 0,
        shop.ownership_mode,
        shop.owner_citizenid,
        shop.buy_price,
        shop.resale_enabled and 1 or 0,
        shop.resale_percent,
        shop.balance or 0,
        shop.allow_cash and 1 or 0,
        shop.allow_bank and 1 or 0,
        shop.blip.enabled and 1 or 0,
        shop.blip.sprite,
        shop.blip.color,
        shop.blip.scale,
        shop.blip.name,
        shop.npc.enabled and 1 or 0,
        shop.npc.model,
        shop.npc.scenario,
        shop.npc.x,
        shop.npc.y,
        shop.npc.z,
        shop.npc.w,
    })
end

function Repo.UpdateShop(shopId, shop)
    return MySQL.update.await([[
        UPDATE shopcreator_shops SET
            slug = ?, name = ?, description = ?, logo_url = ?, enabled = ?, infinite_stock = ?,
            default_stock = ?, storage_capacity = ?, auto_hours = ?, open_hour = ?, close_hour = ?,
            is_open = ?, ownership_mode = ?, owner_citizenid = ?, buy_price = ?, resale_enabled = ?,
            resale_percent = ?, allow_cash = ?, allow_bank = ?,
            blip_enabled = ?, blip_sprite = ?, blip_color = ?, blip_scale = ?, blip_name = ?,
            npc_enabled = ?, npc_model = ?, npc_scenario = ?, npc_x = ?, npc_y = ?, npc_z = ?, npc_w = ?
        WHERE id = ?
    ]], {
        shop.slug,
        shop.name,
        shop.description,
        shop.logo_url,
        shop.enabled and 1 or 0,
        shop.infinite_stock and 1 or 0,
        shop.default_stock,
        shop.storage_capacity,
        shop.auto_hours and 1 or 0,
        shop.open_hour,
        shop.close_hour,
        shop.is_open and 1 or 0,
        shop.ownership_mode,
        shop.owner_citizenid,
        shop.buy_price,
        shop.resale_enabled and 1 or 0,
        shop.resale_percent,
        shop.allow_cash and 1 or 0,
        shop.allow_bank and 1 or 0,
        shop.blip.enabled and 1 or 0,
        shop.blip.sprite,
        shop.blip.color,
        shop.blip.scale,
        shop.blip.name,
        shop.npc.enabled and 1 or 0,
        shop.npc.model,
        shop.npc.scenario,
        shop.npc.x,
        shop.npc.y,
        shop.npc.z,
        shop.npc.w,
        shopId,
    })
end

function Repo.DeleteShop(shopId)
    return MySQL.update.await('DELETE FROM shopcreator_shops WHERE id = ?', { shopId })
end

function Repo.ReplaceLocations(shopId, locations)
    MySQL.update.await('DELETE FROM shopcreator_locations WHERE shop_id = ?', { shopId })
    for i = 1, #(locations or {}) do
        local loc = locations[i]
        MySQL.insert.await(
            'INSERT INTO shopcreator_locations (shop_id, location_type, label, x, y, z, w) VALUES (?, ?, ?, ?, ?, ?, ?)',
            { shopId, loc.location_type, loc.label, loc.x, loc.y, loc.z, loc.w or 0 }
        )
    end
end

function Repo.ReplaceCategories(shopId, categories)
    MySQL.update.await('DELETE FROM shopcreator_categories WHERE shop_id = ?', { shopId })
    local idMap = {}
    for i = 1, #(categories or {}) do
        local cat = categories[i]
        local newId = MySQL.insert.await(
            'INSERT INTO shopcreator_categories (shop_id, label, icon, sort_order, enabled) VALUES (?, ?, ?, ?, ?)',
            { shopId, cat.label, cat.icon or 'package', cat.sort_order or 0, cat.enabled and 1 or 0 }
        )
        if cat.tempId then
            idMap[cat.tempId] = newId
        end
        idMap[cat.id or ('idx:' .. i)] = newId
    end
    return idMap
end

function Repo.ReplaceProducts(shopId, products, categoryIdMap)
    MySQL.update.await('DELETE FROM shopcreator_products WHERE shop_id = ?', { shopId })
    for i = 1, #(products or {}) do
        local prod = products[i]
        local categoryId = prod.category_id
        if not categoryId and prod.categoryTempId and categoryIdMap then
            categoryId = categoryIdMap[prod.categoryTempId]
        end
        MySQL.insert.await([[
            INSERT INTO shopcreator_products (
                shop_id, category_id, item_name, label, image, price, wholesale_price,
                stock, max_stock, enabled, sort_order
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]], {
            shopId,
            categoryId,
            prod.item_name,
            prod.label,
            prod.image,
            prod.price,
            prod.wholesale_price,
            prod.stock or 0,
            prod.max_stock or 100,
            prod.enabled and 1 or 0,
            prod.sort_order or 0,
        })
    end
end

function Repo.SaveCategories(shopId, categories)
    for i = 1, #(categories or {}) do
        local cat = categories[i]
        if cat.id then
            MySQL.update.await(
                'UPDATE shopcreator_categories SET label = ?, icon = ?, sort_order = ?, enabled = ? WHERE id = ? AND shop_id = ?',
                { cat.label, cat.icon or 'package', cat.sort_order or 0, cat.enabled and 1 or 0, cat.id, shopId }
            )
        else
            MySQL.insert.await(
                'INSERT INTO shopcreator_categories (shop_id, label, icon, sort_order, enabled) VALUES (?, ?, ?, ?, ?)',
                { shopId, cat.label, cat.icon or 'package', cat.sort_order or 0, cat.enabled and 1 or 0 }
            )
        end
    end
end

function Repo.SaveProducts(shopId, products)
    for i = 1, #(products or {}) do
        local prod = products[i]
        if prod.id then
            MySQL.update.await([[
                UPDATE shopcreator_products SET
                    category_id = ?, item_name = ?, label = ?, image = ?, price = ?, wholesale_price = ?,
                    stock = ?, max_stock = ?, enabled = ?, sort_order = ?
                WHERE id = ? AND shop_id = ?
            ]], {
                prod.category_id,
                prod.item_name,
                prod.label,
                prod.image,
                prod.price,
                prod.wholesale_price,
                prod.stock or 0,
                prod.max_stock or 100,
                prod.enabled and 1 or 0,
                prod.sort_order or 0,
                prod.id,
                shopId,
            })
        else
            MySQL.insert.await([[
                INSERT INTO shopcreator_products (
                    shop_id, category_id, item_name, label, image, price, wholesale_price,
                    stock, max_stock, enabled, sort_order
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ]], {
                shopId,
                prod.category_id,
                prod.item_name,
                prod.label,
                prod.image,
                prod.price,
                prod.wholesale_price,
                prod.stock or 0,
                prod.max_stock or 100,
                prod.enabled and 1 or 0,
                prod.sort_order or 0,
            })
        end
    end
end

function Repo.ReplaceVehicles(shopId, vehicles)
    MySQL.update.await('DELETE FROM shopcreator_business_vehicles WHERE shop_id = ?', { shopId })
    for i = 1, #(vehicles or {}) do
        local veh = vehicles[i]
        MySQL.insert.await(
            'INSERT INTO shopcreator_business_vehicles (shop_id, model, label, enabled) VALUES (?, ?, ?, ?)',
            { shopId, veh.model, veh.label, veh.enabled and 1 or 0 }
        )
    end
end

function Repo.UpdateShopStatus(shopId, isOpen, autoHours)
    return MySQL.update.await(
        'UPDATE shopcreator_shops SET is_open = ?, auto_hours = ? WHERE id = ?',
        { isOpen and 1 or 0, autoHours and 1 or 0, shopId }
    )
end

function Repo.AddBalance(shopId, amount)
    return MySQL.update.await(
        'UPDATE shopcreator_shops SET balance = balance + ? WHERE id = ?',
        { amount, shopId }
    )
end

function Repo.WithdrawBalance(shopId, amount)
    return MySQL.update.await(
        'UPDATE shopcreator_shops SET balance = balance - ? WHERE id = ? AND balance >= ?',
        { amount, shopId, amount }
    )
end

function Repo.SetOwnership(shopId, mode, ownerCitizenId, balance)
    if balance ~= nil then
        return MySQL.update.await(
            'UPDATE shopcreator_shops SET ownership_mode = ?, owner_citizenid = ?, balance = ? WHERE id = ?',
            { mode, ownerCitizenId, balance, shopId }
        )
    end
    return MySQL.update.await(
        'UPDATE shopcreator_shops SET ownership_mode = ?, owner_citizenid = ? WHERE id = ?',
        { mode, ownerCitizenId, shopId }
    )
end

function Repo.DecrementProductStock(productId, quantity)
    return MySQL.update.await(
        'UPDATE shopcreator_products SET stock = stock - ? WHERE id = ? AND stock >= ?',
        { quantity, productId, quantity }
    )
end

function Repo.IncrementProductStock(productId, quantity, maxStock)
    if maxStock then
        return MySQL.update.await(
            'UPDATE shopcreator_products SET stock = LEAST(max_stock, stock + ?) WHERE id = ?',
            { quantity, productId }
        )
    end
    return MySQL.update.await(
        'UPDATE shopcreator_products SET stock = stock + ? WHERE id = ?',
        { quantity, productId }
    )
end

function Repo.InsertTransaction(shopId, txType, amount, citizenid, playerName, description, meta)
    return MySQL.insert.await([[
        INSERT INTO shopcreator_transactions (shop_id, tx_type, amount, citizenid, player_name, description, meta)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        shopId,
        txType,
        amount,
        citizenid,
        playerName,
        description,
        meta and json.encode(meta) or nil,
    })
end

function Repo.GetRecentTransactions(shopId, limit)
    limit = limit or 50
    return MySQL.query.await(
        'SELECT * FROM shopcreator_transactions WHERE shop_id = ? ORDER BY created_at DESC LIMIT ?',
        { shopId, limit }
    ) or {}
end

function Repo.GetStockOrders(shopId, limit)
    limit = limit or 30
    local orders = MySQL.query.await(
        'SELECT * FROM shopcreator_stock_orders WHERE shop_id = ? ORDER BY created_at DESC LIMIT ?',
        { shopId, limit }
    ) or {}

    for i = 1, #orders do
        orders[i].items = MySQL.query.await(
            'SELECT * FROM shopcreator_stock_order_items WHERE order_id = ?',
            { orders[i].id }
        ) or {}
    end

    return orders
end

function Repo.InsertStockOrder(shopId, orderedBy, orderedByName, method, totalCost, status)
    return MySQL.insert.await([[
        INSERT INTO shopcreator_stock_orders (shop_id, ordered_by, ordered_by_name, method, status, total_cost)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], { shopId, orderedBy, orderedByName, method, status or 'pending', totalCost })
end

function Repo.InsertStockOrderItem(orderId, productId, itemName, quantity, unitCost)
    return MySQL.insert.await(
        'INSERT INTO shopcreator_stock_order_items (order_id, product_id, item_name, quantity, unit_cost) VALUES (?, ?, ?, ?, ?)',
        { orderId, productId, itemName, quantity, unitCost }
    )
end

function Repo.UpdateStockOrderStatus(orderId, status)
    return MySQL.update.await(
        'UPDATE shopcreator_stock_orders SET status = ? WHERE id = ?',
        { status, orderId }
    )
end

function Repo.GetStockOrder(orderId)
    local order = MySQL.single.await('SELECT * FROM shopcreator_stock_orders WHERE id = ?', { orderId })
    if not order then return nil end
    order.items = MySQL.query.await(
        'SELECT * FROM shopcreator_stock_order_items WHERE order_id = ?',
        { orderId }
    ) or {}
    return order
end

function Repo.InsertDeliveryJob(orderId, shopId, reward, origin, dest)
    return MySQL.insert.await([[
        INSERT INTO shopcreator_delivery_jobs (
            order_id, shop_id, status, reward, origin_x, origin_y, origin_z, dest_x, dest_y, dest_z
        ) VALUES (?, ?, 'open', ?, ?, ?, ?, ?, ?, ?)
    ]], {
        orderId,
        shopId,
        reward,
        origin.x,
        origin.y,
        origin.z,
        dest.x,
        dest.y,
        dest.z,
    })
end

function Repo.AcceptDeliveryJob(jobId, citizenid, playerName)
    return MySQL.update.await(
        [[UPDATE shopcreator_delivery_jobs
          SET status = 'accepted', accepted_by = ?, accepted_by_name = ?
          WHERE id = ? AND status = 'open']],
        { citizenid, playerName, jobId }
    )
end

function Repo.MarkDeliveryInTransit(jobId, citizenid)
    return MySQL.update.await(
        [[UPDATE shopcreator_delivery_jobs
          SET status = 'accepted', updated_at = CURRENT_TIMESTAMP
          WHERE id = ? AND status = 'accepted' AND accepted_by = ?]],
        { jobId, citizenid }
    )
end

function Repo.CompleteDeliveryJob(jobId, citizenid)
    return MySQL.update.await(
        [[UPDATE shopcreator_delivery_jobs
          SET status = 'completed'
          WHERE id = ? AND status = 'accepted' AND accepted_by = ?]],
        { jobId, citizenid }
    )
end

function Repo.CancelDeliveryJob(jobId, citizenid)
    return MySQL.update.await(
        [[UPDATE shopcreator_delivery_jobs
          SET status = 'cancelled'
          WHERE id = ? AND status IN ('open', 'accepted') AND (accepted_by IS NULL OR accepted_by = ?)]],
        { jobId, citizenid }
    )
end

function Repo.GetDeliveryJob(jobId)
    return MySQL.single.await('SELECT * FROM shopcreator_delivery_jobs WHERE id = ?', { jobId })
end

function Repo.ListOpenDeliveryJobs()
    return MySQL.query.await([[
        SELECT j.*, s.name AS shop_name,
               (SELECT COALESCE(SUM(quantity), 0) FROM shopcreator_stock_order_items WHERE order_id = j.order_id) AS item_count
        FROM shopcreator_delivery_jobs j
        INNER JOIN shopcreator_shops s ON s.id = j.shop_id
        WHERE j.status = 'open'
        ORDER BY j.created_at DESC
    ]]) or {}
end

function Repo.GetEmployee(shopId, citizenid)
    return MySQL.single.await(
        'SELECT * FROM shopcreator_employees WHERE shop_id = ? AND citizenid = ? AND active = 1 LIMIT 1',
        { shopId, citizenid }
    )
end

function Repo.ListEmployees(shopId)
    return MySQL.query.await(
        'SELECT * FROM shopcreator_employees WHERE shop_id = ? ORDER BY hired_at ASC',
        { shopId }
    ) or {}
end

function Repo.CountEmployees(shopId)
    return MySQL.scalar.await(
        'SELECT COUNT(*) FROM shopcreator_employees WHERE shop_id = ? AND active = 1',
        { shopId }
    ) or 0
end

function Repo.InsertEmployee(shopId, citizenid, name, permissions)
    return MySQL.insert.await(
        'INSERT INTO shopcreator_employees (shop_id, citizenid, name, permissions, active) VALUES (?, ?, ?, ?, 1)',
        { shopId, citizenid, name, json.encode(permissions) }
    )
end

function Repo.UpdateEmployeePermissions(employeeId, shopId, permissions)
    return MySQL.update.await(
        'UPDATE shopcreator_employees SET permissions = ? WHERE id = ? AND shop_id = ?',
        { json.encode(permissions), employeeId, shopId }
    )
end

function Repo.FireEmployee(employeeId, shopId)
    return MySQL.update.await(
        'UPDATE shopcreator_employees SET active = 0 WHERE id = ? AND shop_id = ?',
        { employeeId, shopId }
    )
end

function Repo.GetSettings()
    local rows = MySQL.query.await('SELECT setting_key, setting_value FROM shopcreator_settings') or {}
    local settings = {}
    for i = 1, #rows do
        local row = rows[i]
        local ok, decoded = pcall(json.decode, row.setting_value)
        settings[row.setting_key] = ok and decoded or row.setting_value
    end
    return settings
end

function Repo.SaveSetting(key, value)
    local encoded = type(value) == 'string' and value or json.encode(value)
    MySQL.insert.await(
        'INSERT INTO shopcreator_settings (setting_key, setting_value) VALUES (?, ?) ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)',
        { key, encoded }
    )
end

function Repo.SaveSettings(settings)
    for key, value in pairs(settings) do
        Repo.SaveSetting(key, value)
    end
end
