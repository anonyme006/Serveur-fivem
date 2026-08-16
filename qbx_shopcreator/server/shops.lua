ShopCreator = ShopCreator or {}

ShopCreator.Cache = ShopCreator.Cache or {
    shops = {},
    ready = false,
}

local Repo = ShopCreator.Repository

---@param value any
---@return boolean
local function toBool(value)
    return value == true or value == 1 or value == '1'
end

---@return table
function ShopCreator.DefaultSettings()
    return {
        low_stock_threshold = Config.LowStockThreshold,
        max_categories = Config.MaxCategoriesPerShop,
        max_products = Config.MaxProductsPerShop,
        max_employees = Config.MaxEmployeesPerShop,
        default_capacity = Config.Stock.defaultCapacity,
        instant_delivery = Config.Delivery.instantEnabled,
        self_delivery = Config.Delivery.selfEnabled,
        public_delivery = Config.Delivery.publicEnabled,
        public_reward_percent = math.floor((Config.Delivery.publicRewardPercent or 0.12) * 100),
        allow_cash_default = Config.Payments.cash,
        allow_bank_default = Config.Payments.bank,
    }
end

---@param settings table|nil
---@return table
function ShopCreator.MergeSettings(settings)
    local merged = ShopCreator.DefaultSettings()
    if type(settings) == 'table' then
        for k, v in pairs(settings) do
            merged[k] = v
        end
    end
    return merged
end

ShopCreator.Settings = ShopCreator.MergeSettings({})

---@param tbl table
---@param shopId number
---@param row table
local function pushGrouped(tbl, shopId, row)
    tbl[shopId] = tbl[shopId] or {}
    tbl[shopId][#tbl[shopId] + 1] = row
end

---@param shop table
function ShopCreator.ComputeDerived(shop)
    shop.product_count = #(shop.products or {})
    shop.employee_count = 0
    for i = 1, #(shop.employees or {}) do
        if shop.employees[i].active then
            shop.employee_count = shop.employee_count + 1
        end
    end

    shop.low_stock_count = 0
    shop.storage_used = 0
    for i = 1, #(shop.products or {}) do
        local prod = shop.products[i]
        shop.storage_used = shop.storage_used + (prod.stock or 0)
        if prod.enabled and not shop.infinite_stock and (prod.stock or 0) <= Config.LowStockThreshold then
            shop.low_stock_count = shop.low_stock_count + 1
        end
    end

    shop.pending_orders = Repo.CountPendingOrders(shop.id)
    shop.is_effectively_open = ShopCreator.IsShopOpen(shop)
end

---@param row table
---@return table
local function normalizeLocation(row)
    return {
        id = row.id,
        location_type = row.location_type,
        label = row.label,
        x = row.x,
        y = row.y,
        z = row.z,
        w = row.w or 0,
    }
end

---@param row table
---@return table
local function normalizeCategory(row)
    return {
        id = row.id,
        label = row.label,
        icon = row.icon or 'package',
        sort_order = row.sort_order or 0,
        enabled = toBool(row.enabled),
    }
end

---@param row table
---@return table
local function normalizeProduct(row)
    return {
        id = row.id,
        category_id = row.category_id,
        item_name = row.item_name,
        label = row.label or row.item_name,
        image = row.image,
        price = tonumber(row.price) or 0,
        wholesale_price = tonumber(row.wholesale_price) or 0,
        stock = tonumber(row.stock) or 0,
        max_stock = tonumber(row.max_stock) or 100,
        enabled = toBool(row.enabled),
        sort_order = row.sort_order or 0,
    }
end

---@param row table
---@return table
local function normalizeEmployee(row)
    return {
        id = row.id,
        citizenid = row.citizenid,
        name = row.name,
        permissions = ShopCreator.NormalizePermissions(row.permissions),
        active = toBool(row.active),
        hired_at = row.hired_at,
    }
end

---@param row table
---@return table
local function normalizeVehicle(row)
    return {
        id = row.id,
        model = row.model,
        label = row.label,
        enabled = toBool(row.enabled),
    }
end

---@param shopRow table
---@param grouped table
---@return table
function ShopCreator.BuildShopFromParts(shopRow, grouped)
    local shop = Repo.NormalizeShopRow(shopRow)
    local shopId = shop.id

    shop.locations = {}
    for i = 1, #(grouped.locations[shopId] or {}) do
        shop.locations[#shop.locations + 1] = normalizeLocation(grouped.locations[shopId][i])
    end

    shop.categories = {}
    for i = 1, #(grouped.categories[shopId] or {}) do
        shop.categories[#shop.categories + 1] = normalizeCategory(grouped.categories[shopId][i])
    end

    shop.products = {}
    for i = 1, #(grouped.products[shopId] or {}) do
        shop.products[#shop.products + 1] = normalizeProduct(grouped.products[shopId][i])
    end

    shop.employees = {}
    for i = 1, #(grouped.employees[shopId] or {}) do
        shop.employees[#shop.employees + 1] = normalizeEmployee(grouped.employees[shopId][i])
    end

    shop.vehicles = {}
    for i = 1, #(grouped.vehicles[shopId] or {}) do
        shop.vehicles[#shop.vehicles + 1] = normalizeVehicle(grouped.vehicles[shopId][i])
    end

    ShopCreator.ComputeDerived(shop)
    return shop
end

---@param shopId number|nil
function ShopCreator.RegisterShopStash(shopId)
    if not shopId then return end
    local shop = ShopCreator.Cache.shops[shopId]
    local slots = Config.Stash.slots
    local weight = Config.Stash.weight
    local capacity = shop and shop.storage_capacity or Config.Stock.defaultCapacity

    pcall(function()
        exports.ox_inventory:RegisterStash(
            ('shopcreator_%s'):format(shopId),
            shop and shop.name or ('Shop %s'):format(shopId),
            slots,
            weight + (capacity * 100),
            nil
        )
    end)
end

function ShopCreator.LoadShopsIntoCache()
    local shopRows = Repo.LoadShopRows()
    local shopIds = {}
    for i = 1, #shopRows do
        shopIds[#shopIds + 1] = shopRows[i].id
    end

    local grouped = {
        locations = {},
        categories = {},
        products = {},
        employees = {},
        vehicles = {},
    }

    local locRows = Repo.LoadLocationsForShops(shopIds)
    for i = 1, #locRows do pushGrouped(grouped.locations, locRows[i].shop_id, locRows[i]) end

    local catRows = Repo.LoadCategoriesForShops(shopIds)
    for i = 1, #catRows do pushGrouped(grouped.categories, catRows[i].shop_id, catRows[i]) end

    local prodRows = Repo.LoadProductsForShops(shopIds)
    for i = 1, #prodRows do pushGrouped(grouped.products, prodRows[i].shop_id, prodRows[i]) end

    local empRows = Repo.LoadEmployeesForShops(shopIds)
    for i = 1, #empRows do pushGrouped(grouped.employees, empRows[i].shop_id, empRows[i]) end

    local vehRows = Repo.LoadVehiclesForShops(shopIds)
    for i = 1, #vehRows do pushGrouped(grouped.vehicles, vehRows[i].shop_id, vehRows[i]) end

    ShopCreator.Cache.shops = {}
    for i = 1, #shopRows do
        local shop = ShopCreator.BuildShopFromParts(shopRows[i], grouped)
        ShopCreator.Cache.shops[shop.id] = shop
        ShopCreator.RegisterShopStash(shop.id)
    end

    ShopCreator.Cache.ready = true
    return ShopCreator.Cache.shops
end

---@param shopId number
---@return table|nil
function ShopCreator.ReloadShop(shopId)
    local row = MySQL.single.await('SELECT * FROM shopcreator_shops WHERE id = ?', { shopId })
    if not row then
        ShopCreator.Cache.shops[shopId] = nil
        return nil
    end

    local grouped = {
        locations = { [shopId] = Repo.LoadLocationsForShops({ shopId }) },
        categories = { [shopId] = Repo.LoadCategoriesForShops({ shopId }) },
        products = { [shopId] = Repo.LoadProductsForShops({ shopId }) },
        employees = { [shopId] = Repo.LoadEmployeesForShops({ shopId }) },
        vehicles = { [shopId] = Repo.LoadVehiclesForShops({ shopId }) },
    }

    local shop = ShopCreator.BuildShopFromParts(row, grouped)
    ShopCreator.Cache.shops[shopId] = shop
    ShopCreator.RegisterShopStash(shopId)
    return shop
end

---@param shop table
---@return table
function ShopCreator.BuildPublicPayload(shop)
    if not shop then return nil end

    local locations = {}
    for i = 1, #(shop.locations or {}) do
        local loc = shop.locations[i]
        locations[#locations + 1] = {
            id = loc.id,
            location_type = loc.location_type,
            label = loc.label,
            x = loc.x,
            y = loc.y,
            z = loc.z,
            w = loc.w,
        }
    end

    local categories = {}
    for i = 1, #(shop.categories or {}) do
        local cat = shop.categories[i]
        if cat.enabled then
            categories[#categories + 1] = {
                id = cat.id,
                label = cat.label,
                icon = cat.icon,
                sort_order = cat.sort_order,
                enabled = cat.enabled,
            }
        end
    end

    local products = {}
    for i = 1, #(shop.products or {}) do
        local prod = shop.products[i]
        if prod.enabled then
            products[#products + 1] = {
                id = prod.id,
                category_id = prod.category_id,
                item_name = prod.item_name,
                label = prod.label,
                image = prod.image,
                price = prod.price,
                stock = shop.infinite_stock and 999999 or prod.stock,
                max_stock = prod.max_stock,
                enabled = prod.enabled,
                sort_order = prod.sort_order,
            }
        end
    end

    return {
        id = shop.id,
        slug = shop.slug,
        name = shop.name,
        description = shop.description,
        logo_url = shop.logo_url,
        enabled = shop.enabled,
        infinite_stock = shop.infinite_stock,
        is_open = shop.is_effectively_open,
        auto_hours = shop.auto_hours,
        open_hour = shop.open_hour,
        close_hour = shop.close_hour,
        ownership_mode = shop.ownership_mode,
        owner_citizenid = shop.owner_citizenid,
        buy_price = shop.buy_price,
        resale_enabled = shop.resale_enabled,
        allow_cash = shop.allow_cash,
        allow_bank = shop.allow_bank,
        blip = shop.blip,
        npc = shop.npc,
        locations = locations,
        categories = categories,
        products = products,
    }
end

---@param shop table
---@return table
function ShopCreator.BuildSummary(shop)
    return {
        id = shop.id,
        slug = shop.slug,
        name = shop.name,
        description = shop.description,
        logo_url = shop.logo_url,
        enabled = shop.enabled,
        is_open = shop.is_effectively_open,
        ownership_mode = shop.ownership_mode,
        buy_price = shop.buy_price,
        product_count = shop.product_count or 0,
        employee_count = shop.employee_count or 0,
    }
end

---@param shopId number
---@param target? number
function ShopCreator.SyncShopToClients(shopId, target)
    local shop = ShopCreator.Cache.shops[shopId]
    if not shop then return end
    ShopCreator.ComputeDerived(shop)
    local payload = ShopCreator.BuildPublicPayload(shop)
    if target then
        TriggerClientEvent('qbx_shopcreator:client:refreshShop', target, payload)
    else
        TriggerClientEvent('qbx_shopcreator:client:refreshShop', -1, payload)
    end
end

---@param target number
function ShopCreator.SyncAllPublicShops(target)
    local list = {}
    for _, shop in pairs(ShopCreator.Cache.shops) do
        if shop.enabled then
            list[#list + 1] = ShopCreator.BuildPublicPayload(shop)
        end
    end
    TriggerClientEvent('qbx_shopcreator:client:syncShops', target, list)
end

---@param payload table|nil
---@param isCreate boolean
---@return table|nil, string|nil
function ShopCreator.ValidateShopPayload(payload, isCreate)
    if type(payload) ~= 'table' then
        return nil, ShopCreator.L('invalid_data')
    end

    local name = ShopCreator.SanitizeString(payload.name, 96)
    if not name then
        return nil, ShopCreator.L('invalid_data')
    end

    local slug = ShopCreator.SanitizeString(payload.slug, 48) or ShopCreator.Slugify(name)
    slug = slug:lower():gsub('[^%w_%-]', '_')

    local ownershipMode = payload.ownership_mode
    if ownershipMode ~= 'none' and ownershipMode ~= 'purchasable' and ownershipMode ~= 'owned' then
        ownershipMode = 'none'
    end

    local blip = type(payload.blip) == 'table' and payload.blip or {}
    local npc = type(payload.npc) == 'table' and payload.npc or {}

    local shop = {
        slug = slug,
        name = name,
        description = ShopCreator.SanitizeString(payload.description, 512) or '',
        logo_url = ShopCreator.SanitizeString(payload.logo_url, 512) or '',
        enabled = payload.enabled ~= false,
        infinite_stock = payload.infinite_stock == true,
        default_stock = ShopCreator.ClampInt(payload.default_stock, 0, 100000) or 0,
        storage_capacity = ShopCreator.ClampInt(payload.storage_capacity, 1, 100000)
            or Config.Stock.defaultCapacity,
        auto_hours = payload.auto_hours == true,
        open_hour = ShopCreator.ParseHour(payload.open_hour),
        close_hour = ShopCreator.ParseHour(payload.close_hour),
        is_open = payload.is_open ~= false,
        ownership_mode = ownershipMode,
        owner_citizenid = ShopCreator.SanitizeString(payload.owner_citizenid, 64),
        buy_price = ShopCreator.ClampInt(payload.buy_price, 0, 100000000) or Config.Ownership.defaultBuyPrice,
        resale_enabled = payload.resale_enabled == true,
        resale_percent = tonumber(payload.resale_percent) or Config.Ownership.defaultResalePercent,
        balance = ShopCreator.ClampInt(payload.balance, 0, 999999999999) or 0,
        allow_cash = payload.allow_cash ~= false,
        allow_bank = payload.allow_bank ~= false,
        blip = {
            enabled = blip.enabled ~= false,
            sprite = ShopCreator.ClampInt(blip.sprite, 0, 1000) or Config.Blip.sprite,
            color = ShopCreator.ClampInt(blip.color, 0, 100) or Config.Blip.color,
            scale = tonumber(blip.scale) or Config.Blip.scale,
            name = ShopCreator.SanitizeString(blip.name, 96) or name,
        },
        npc = {
            enabled = npc.enabled == true,
            model = ShopCreator.SanitizeString(npc.model, 64) or Config.Npc.model,
            scenario = ShopCreator.SanitizeString(npc.scenario, 96) or Config.Npc.scenario,
            x = tonumber(npc.x),
            y = tonumber(npc.y),
            z = tonumber(npc.z),
            w = tonumber(npc.w) or 0,
        },
        locations = {},
        categories = {},
        products = {},
        vehicles = {},
    }

    if ownershipMode ~= 'owned' then
        shop.owner_citizenid = nil
    end

    local locations = payload.locations
    if type(locations) == 'table' then
        if #locations > Config.MaxCustomerPoints then
            return nil, ShopCreator.L('invalid_data')
        end
        for i = 1, #locations do
            local loc = locations[i]
            local locType = loc.location_type
            local validType = false
            for _, t in pairs(ShopCreator.LocationTypes) do
                if t == locType then validType = true break end
            end
            if validType and tonumber(loc.x) and tonumber(loc.y) and tonumber(loc.z) then
                shop.locations[#shop.locations + 1] = {
                    location_type = locType,
                    label = ShopCreator.SanitizeString(loc.label, 96),
                    x = loc.x + 0.0,
                    y = loc.y + 0.0,
                    z = loc.z + 0.0,
                    w = tonumber(loc.w) or 0,
                }
            end
        end
    end

    local categories = payload.categories
    if type(categories) == 'table' then
        if #categories > Config.MaxCategoriesPerShop then
            return nil, ShopCreator.L('invalid_data')
        end
        for i = 1, #categories do
            local cat = categories[i]
            local label = ShopCreator.SanitizeString(cat.label, 96)
            if label then
                shop.categories[#shop.categories + 1] = {
                    tempId = cat.tempId,
                    id = cat.id,
                    label = label,
                    icon = ShopCreator.SanitizeString(cat.icon, 64) or 'package',
                    sort_order = tonumber(cat.sort_order) or (i - 1),
                    enabled = cat.enabled ~= false,
                }
            end
        end
    end

    local products = payload.products
    if type(products) == 'table' then
        if #products > Config.MaxProductsPerShop then
            return nil, ShopCreator.L('invalid_data')
        end
        for i = 1, #products do
            local prod = products[i]
            local itemName = ShopCreator.SanitizeItemName(prod.item_name)
            if itemName and ShopCreator.ItemExists(itemName) then
                shop.products[#shop.products + 1] = {
                    id = prod.id,
                    category_id = prod.category_id,
                    categoryTempId = prod.categoryTempId,
                    item_name = itemName,
                    label = ShopCreator.SanitizeString(prod.label, 96) or itemName,
                    image = ShopCreator.SanitizeString(prod.image, 512),
                    price = ShopCreator.ClampInt(prod.price, 0, 10000000) or 0,
                    wholesale_price = ShopCreator.ClampInt(prod.wholesale_price, 0, 10000000) or 0,
                    stock = ShopCreator.ClampInt(prod.stock, 0, 1000000) or shop.default_stock,
                    max_stock = ShopCreator.ClampInt(prod.max_stock, 1, 1000000) or 100,
                    enabled = prod.enabled ~= false,
                    sort_order = tonumber(prod.sort_order) or (i - 1),
                }
            end
        end
    end

    local vehicles = payload.vehicles
    if type(vehicles) == 'table' then
        if #vehicles > Config.Garage.maxVehicles then
            return nil, ShopCreator.L('invalid_data')
        end
        for i = 1, #vehicles do
            local veh = vehicles[i]
            local model = ShopCreator.SanitizeString(veh.model, 64)
            local label = ShopCreator.SanitizeString(veh.label, 96)
            if model and label then
                shop.vehicles[#shop.vehicles + 1] = {
                    model = model,
                    label = label,
                    enabled = veh.enabled ~= false,
                }
            end
        end
    end

    if isCreate and not shop.slug then
        return nil, ShopCreator.L('invalid_data')
    end

    return shop, nil
end

---@param source number
---@param payload table
---@return table
function ShopCreator.AdminCreateShop(source, payload)
    local shop, err = ShopCreator.ValidateShopPayload(payload, true)
    if not shop then
        return { ok = false, error = err }
    end

    if Repo.SlugExists(shop.slug) then
        shop.slug = ('%s_%s'):format(shop.slug, os.time() % 100000)
    end

    if shop.ownership_mode == 'owned' and not shop.owner_citizenid then
        shop.owner_citizenid = ShopCreator.GetCitizenId(source)
    end

    shop.balance = shop.balance > 0 and shop.balance or Config.Ownership.defaultInitialFunds

    local shopId = Repo.InsertShop(shop)
    if not shopId then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    Repo.ReplaceLocations(shopId, shop.locations)
    local catMap = Repo.ReplaceCategories(shopId, shop.categories)
    Repo.ReplaceProducts(shopId, shop.products, catMap)
    Repo.ReplaceVehicles(shopId, shop.vehicles)

    local loaded = ShopCreator.ReloadShop(shopId)
    ShopCreator.SyncShopToClients(shopId)

    ShopCreator.Log('shop_created', {
        shopId = shopId,
        admin = ShopCreator.GetCitizenId(source),
        name = shop.name,
    })

    return { ok = true, data = loaded }
end

---@param source number
---@param shopId number
---@param payload table
---@return table
function ShopCreator.AdminUpdateShop(source, shopId, payload)
    shopId = tonumber(shopId)
    if not shopId or not ShopCreator.Cache.shops[shopId] then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    payload = payload or {}
    payload.id = shopId

    local shop, err = ShopCreator.ValidateShopPayload(payload, false)
    if not shop then
        return { ok = false, error = err }
    end

    if Repo.SlugExists(shop.slug, shopId) then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    local existing = ShopCreator.Cache.shops[shopId]
    shop.balance = existing.balance
    if shop.ownership_mode ~= 'owned' then
        shop.owner_citizenid = nil
    elseif not shop.owner_citizenid then
        shop.owner_citizenid = existing.owner_citizenid
    end

    Repo.UpdateShop(shopId, shop)
    Repo.ReplaceLocations(shopId, shop.locations)
    local catMap = Repo.ReplaceCategories(shopId, shop.categories)
    Repo.ReplaceProducts(shopId, shop.products, catMap)
    Repo.ReplaceVehicles(shopId, shop.vehicles)

    local loaded = ShopCreator.ReloadShop(shopId)
    ShopCreator.SyncShopToClients(shopId)

    ShopCreator.Log('shop_updated', {
        shopId = shopId,
        admin = ShopCreator.GetCitizenId(source),
    })

    return { ok = true, data = loaded }
end

---@param source number
---@param shopId number
---@return table
function ShopCreator.AdminDeleteShop(source, shopId)
    shopId = tonumber(shopId)
    if not shopId or not ShopCreator.Cache.shops[shopId] then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    Repo.DeleteShop(shopId)
    ShopCreator.Cache.shops[shopId] = nil
    TriggerClientEvent('qbx_shopcreator:client:removeShop', -1, shopId)

    ShopCreator.Log('shop_deleted', {
        shopId = shopId,
        admin = ShopCreator.GetCitizenId(source),
    })

    return { ok = true }
end

---@param source number
---@param shopId number
---@param mode 'storefront'|'management'|'admin'
---@return table
function ShopCreator.GetShopForClient(source, shopId, mode)
    shopId = tonumber(shopId)
    local shop = ShopCreator.Cache.shops[shopId]
    if not shop then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    if mode == 'admin' and ShopCreator.IsAdmin(source) then
        return { ok = true, data = ShopCreator.DeepCopy(shop) }
    end

    if mode == 'storefront' then
        if not shop.enabled then
            return { ok = false, error = ShopCreator.L('shop_closed') }
        end
        return { ok = true, data = ShopCreator.BuildPublicPayload(shop) }
    end

    if mode == 'management' then
        if not ShopCreator.HasShopPermission(source, shopId, 'open_business')
            and not ShopCreator.IsOwner(source, shopId)
            and not ShopCreator.IsAdmin(source) then
            return { ok = false, error = ShopCreator.L('no_permission') }
        end
        return { ok = true, data = ShopCreator.DeepCopy(shop) }
    end

    return { ok = false, error = ShopCreator.L('no_permission') }
end

---@param source number
---@param shopId number
---@return table
function ShopCreator.BuyShop(source, shopId)
    shopId = tonumber(shopId)
    local shop = ShopCreator.Cache.shops[shopId]
    if not shop or not shop.enabled then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    if shop.ownership_mode ~= 'purchasable' then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    local citizenid = ShopCreator.GetCitizenId(source)
    if not citizenid then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    local price = shop.buy_price or 0
    if price <= 0 then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    local paid = false
    if shop.allow_bank and ShopCreator.GetMoney(source, 'bank') >= price then
        paid = ShopCreator.RemoveMoney(source, price, 'bank', 'shop_purchase')
    elseif shop.allow_cash and ShopCreator.GetMoney(source, 'cash') >= price then
        paid = ShopCreator.RemoveMoney(source, price, 'cash', 'shop_purchase')
    end

    if not paid then
        return { ok = false, error = ShopCreator.L('not_enough_money') }
    end

    Repo.SetOwnership(shopId, 'owned', citizenid, shop.balance)
    ShopCreator.ReloadShop(shopId)
    ShopCreator.SyncShopToClients(shopId)

    Repo.InsertTransaction(
        shopId,
        ShopCreator.TransactionTypes.ownership,
        -price,
        citizenid,
        ShopCreator.GetPlayerName(source),
        'Achat du commerce',
        nil
    )

    ShopCreator.Log('shop_purchased', { shopId = shopId, citizenid = citizenid, price = price })
    ShopCreator.Notify(source, ShopCreator.L('shop_purchased'), 'success')

    return { ok = true, data = ShopCreator.Cache.shops[shopId] }
end

---@param source number
---@param shopId number
---@return table
function ShopCreator.SellShop(source, shopId)
    shopId = tonumber(shopId)
    local shop = ShopCreator.Cache.shops[shopId]
    if not shop then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    if not ShopCreator.IsOwner(source, shopId) then
        return { ok = false, error = ShopCreator.L('no_permission') }
    end

    if not shop.resale_enabled then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    local payout = math.floor((shop.buy_price or 0) * ((shop.resale_percent or 70) / 100))
    if payout > 0 then
        ShopCreator.AddMoney(source, payout, 'bank', 'shop_resale')
    end

    Repo.SetOwnership(shopId, 'purchasable', nil, shop.balance)
    ShopCreator.ReloadShop(shopId)
    ShopCreator.SyncShopToClients(shopId)

    Repo.InsertTransaction(
        shopId,
        ShopCreator.TransactionTypes.ownership,
        payout,
        ShopCreator.GetCitizenId(source),
        ShopCreator.GetPlayerName(source),
        'Revente du commerce',
        nil
    )

    ShopCreator.Notify(source, ShopCreator.L('shop_sold'), 'success')
    return { ok = true, data = ShopCreator.Cache.shops[shopId] }
end

---@param source number
---@param shopId number
---@param targetCitizenId string
---@return table
function ShopCreator.TransferOwnership(source, shopId, targetCitizenId)
    shopId = tonumber(shopId)
    local shop = ShopCreator.Cache.shops[shopId]
    if not shop then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    if not ShopCreator.IsOwner(source, shopId) and not ShopCreator.IsAdmin(source) then
        return { ok = false, error = ShopCreator.L('no_permission') }
    end

    targetCitizenId = ShopCreator.SanitizeString(targetCitizenId, 64)
    if not targetCitizenId then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    Repo.SetOwnership(shopId, 'owned', targetCitizenId, shop.balance)
    ShopCreator.ReloadShop(shopId)
    ShopCreator.SyncShopToClients(shopId)

    ShopCreator.Log('shop_transferred', {
        shopId = shopId,
        from = ShopCreator.GetCitizenId(source),
        to = targetCitizenId,
    })

    return { ok = true, data = ShopCreator.Cache.shops[shopId] }
end

---@param source number
---@param shopId number
---@param isOpen boolean
---@param autoHours boolean|nil
---@return table
function ShopCreator.UpdateShopStatus(source, shopId, isOpen, autoHours)
    shopId = tonumber(shopId)
    if not ShopCreator.HasShopPermission(source, shopId, 'control_status') then
        return { ok = false, error = ShopCreator.L('no_permission') }
    end

    Repo.UpdateShopStatus(shopId, isOpen, autoHours)
    ShopCreator.ReloadShop(shopId)
    ShopCreator.SyncShopToClients(shopId)
    return { ok = true, data = ShopCreator.Cache.shops[shopId] }
end

---@param source number
---@param shopId number
---@param amount number
---@return table
function ShopCreator.DepositFunds(source, shopId, amount)
    shopId = tonumber(shopId)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    if not ShopCreator.HasShopPermission(source, shopId, 'deposit_funds') then
        return { ok = false, error = ShopCreator.L('no_permission') }
    end

    if not ShopCreator.RateLimit(source, 'deposit', Config.RateLimit.fundsMs) then
        return { ok = false, error = ShopCreator.L('rate_limited') }
    end

    local shop = ShopCreator.Cache.shops[shopId]
    if not shop then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    local account = shop.allow_bank and 'bank' or 'cash'
    if not ShopCreator.RemoveMoney(source, amount, account, 'shop_deposit') then
        return { ok = false, error = ShopCreator.L('not_enough_money') }
    end

    Repo.AddBalance(shopId, amount)
    ShopCreator.ReloadShop(shopId)

    Repo.InsertTransaction(
        shopId,
        ShopCreator.TransactionTypes.deposit,
        amount,
        ShopCreator.GetCitizenId(source),
        ShopCreator.GetPlayerName(source),
        'Dépôt compte entreprise',
        nil
    )

    ShopCreator.Notify(source, ShopCreator.L('deposit_success'), 'success')
    return { ok = true, data = { balance = ShopCreator.Cache.shops[shopId].balance } }
end

---@param source number
---@param shopId number
---@param amount number
---@return table
function ShopCreator.WithdrawFunds(source, shopId, amount)
    shopId = tonumber(shopId)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    if not ShopCreator.HasShopPermission(source, shopId, 'withdraw_funds') then
        return { ok = false, error = ShopCreator.L('no_permission') }
    end

    if not ShopCreator.RateLimit(source, 'withdraw', Config.RateLimit.fundsMs) then
        return { ok = false, error = ShopCreator.L('rate_limited') }
    end

    local affected = Repo.WithdrawBalance(shopId, amount)
    if not affected or affected < 1 then
        return { ok = false, error = ShopCreator.L('not_enough_money') }
    end

    ShopCreator.AddMoney(source, amount, 'bank', 'shop_withdraw')
    ShopCreator.ReloadShop(shopId)

    Repo.InsertTransaction(
        shopId,
        ShopCreator.TransactionTypes.withdrawal,
        -amount,
        ShopCreator.GetCitizenId(source),
        ShopCreator.GetPlayerName(source),
        'Retrait fonds',
        nil
    )

    ShopCreator.Notify(source, ShopCreator.L('withdraw_success'), 'success')
    return { ok = true, data = { balance = ShopCreator.Cache.shops[shopId].balance } }
end

---@param source number
---@param shopId number
---@param categories table
---@return table
function ShopCreator.SaveCategories(source, shopId, categories)
    shopId = tonumber(shopId)
    if not ShopCreator.HasShopPermission(source, shopId, 'manage_products') then
        return { ok = false, error = ShopCreator.L('no_permission') }
    end

    if type(categories) ~= 'table' or #categories > Config.MaxCategoriesPerShop then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    Repo.SaveCategories(shopId, categories)
    ShopCreator.ReloadShop(shopId)
    ShopCreator.SyncShopToClients(shopId)

    Repo.InsertTransaction(
        shopId,
        ShopCreator.TransactionTypes.shop_change,
        0,
        ShopCreator.GetCitizenId(source),
        ShopCreator.GetPlayerName(source),
        'Mise à jour catégories',
        nil
    )

    return { ok = true, data = ShopCreator.Cache.shops[shopId].categories }
end

---@param source number
---@param shopId number
---@param products table
---@return table
function ShopCreator.SaveProducts(source, shopId, products)
    shopId = tonumber(shopId)
    if not ShopCreator.HasShopPermission(source, shopId, 'manage_products') then
        return { ok = false, error = ShopCreator.L('no_permission') }
    end

    if type(products) ~= 'table' or #products > Config.MaxProductsPerShop then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    for i = 1, #products do
        local itemName = ShopCreator.SanitizeItemName(products[i].item_name)
        if not itemName or not ShopCreator.ItemExists(itemName) then
            return { ok = false, error = ShopCreator.L('invalid_data') }
        end
        products[i].item_name = itemName
    end

    Repo.SaveProducts(shopId, products)
    ShopCreator.ReloadShop(shopId)
    ShopCreator.SyncShopToClients(shopId)

    Repo.InsertTransaction(
        shopId,
        ShopCreator.TransactionTypes.shop_change,
        0,
        ShopCreator.GetCitizenId(source),
        ShopCreator.GetPlayerName(source),
        'Mise à jour produits',
        nil
    )

    return { ok = true, data = ShopCreator.Cache.shops[shopId].products }
end

---@param source number
---@param shopId number
---@return table
function ShopCreator.GetManagementData(source, shopId)
    shopId = tonumber(shopId)
    local shop = ShopCreator.Cache.shops[shopId]
    if not shop then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    local canAccess = ShopCreator.IsOwner(source, shopId)
        or ShopCreator.HasShopPermission(source, shopId, 'open_business')
        or ShopCreator.IsAdmin(source)

    if not canAccess then
        return { ok = false, error = ShopCreator.L('no_permission') }
    end

    local txRows = Repo.GetRecentTransactions(shopId, 50)
    local transactions = {}
    for i = 1, #txRows do
        local row = txRows[i]
        transactions[#transactions + 1] = {
            id = row.id,
            tx_type = row.tx_type,
            amount = tonumber(row.amount) or 0,
            citizenid = row.citizenid,
            player_name = row.player_name,
            description = row.description or '',
            created_at = row.created_at,
        }
    end

    local orderRows = Repo.GetStockOrders(shopId, 30)
    local stockOrders = {}
    for i = 1, #orderRows do
        local order = orderRows[i]
        local items = {}
        for j = 1, #(order.items or {}) do
            local item = order.items[j]
            items[#items + 1] = {
                product_id = item.product_id,
                item_name = item.item_name,
                quantity = item.quantity,
                unit_cost = item.unit_cost,
            }
        end
        stockOrders[#stockOrders + 1] = {
            id = order.id,
            method = order.method,
            status = order.status,
            total_cost = order.total_cost,
            ordered_by_name = order.ordered_by_name,
            created_at = order.created_at,
            items = items,
        }
    end

    local employees = {}
    for i = 1, #(shop.employees or {}) do
        local emp = shop.employees[i]
        if emp.active then
            employees[#employees + 1] = ShopCreator.DeepCopy(emp)
        end
    end

    local perms = ShopCreator.GetEffectivePermissions(source, shopId)
    local managementShop = ShopCreator.DeepCopy(shop)
    if not perms.view_balance and not ShopCreator.IsOwner(source, shopId) and not ShopCreator.IsAdmin(source) then
        managementShop.balance = nil
    end

    return {
        ok = true,
        data = {
            shop = managementShop,
            employees = employees,
            transactions = transactions,
            stock_orders = stockOrders,
            permissions = perms,
            storage_used = shop.storage_used or 0,
            is_owner = ShopCreator.IsOwner(source, shopId),
        },
    }
end

function ShopCreator.LoadSettings()
    local stored = Repo.GetSettings()
    ShopCreator.Settings = ShopCreator.MergeSettings(stored)
    return ShopCreator.Settings
end

---@param source number
---@param settings table
---@return table
function ShopCreator.SaveSettings(source, settings)
    if not ShopCreator.IsAdmin(source) then
        return { ok = false, error = ShopCreator.L('no_permission') }
    end

    if type(settings) ~= 'table' then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    local merged = ShopCreator.MergeSettings(settings)
    Repo.SaveSettings(merged)
    ShopCreator.Settings = merged
    return { ok = true, data = merged }
end

function ShopCreator.GetInventoryItems()
    local items = {}
    local ok, allItems = pcall(function()
        return exports.ox_inventory:Items()
    end)

    if ok and type(allItems) == 'table' then
        for name, data in pairs(allItems) do
            items[#items + 1] = {
                name = name,
                label = data.label or name,
                image = data.client and data.client.image or nil,
                weight = data.weight,
            }
        end
        table.sort(items, function(a, b) return a.label < b.label end)
    end

    return { ok = true, data = items }
end
