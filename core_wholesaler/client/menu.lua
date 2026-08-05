--[[
    Menus ox_lib — menu principal, achat, stock, historique, commandes
]]

local function ensureAccess()
    if not Client.access then
        Client.RefreshAccess()
    end
    return Client.access
end

--- Menu principal
---@param focus string|nil 'main'|'buy'
function OpenWholesalerMenu(focus)
    local access = ensureAccess()
    if not access or not access.ok then
        return Client.NotifyErr('error')
    end

    if focus == 'buy' then
        return OpenBuyMenu()
    end

    local options = {}

    if access.isBuyer or access.isWholesaler or access.isAdmin then
        options[#options + 1] = {
            title = _('menu_buy'),
            description = '',
            icon = 'cart-shopping',
            onSelect = OpenBuyMenu,
        }
        options[#options + 1] = {
            title = _('menu_stock'),
            icon = 'boxes-stacked',
            onSelect = OpenStockMenu,
        }
        options[#options + 1] = {
            title = _('menu_history'),
            icon = 'clock-rotate-left',
            onSelect = OpenHistoryMenu,
        }
        options[#options + 1] = {
            title = _('menu_orders'),
            icon = 'clipboard-list',
            onSelect = OpenOrdersMenu,
        }
        options[#options + 1] = {
            title = _('menu_pickup'),
            icon = 'box-open',
            onSelect = OpenPickupMenu,
        }
    end

    if access.isTransporter and Config.Delivery.enabled then
        options[#options + 1] = {
            title = _('menu_delivery'),
            icon = 'truck',
            onSelect = OpenDeliveryMenu,
        }
    end

    if access.isWholesaler or access.isAdmin then
        options[#options + 1] = {
            title = _('menu_export'),
            icon = 'ship',
            onSelect = OpenExportMenu,
        }
    end

    if access.isAdmin or access.isBoss then
        options[#options + 1] = {
            title = _('menu_admin'),
            icon = 'screwdriver-wrench',
            onSelect = OpenAdminMenu,
        }
    end

    if access.isBoss then
        options[#options + 1] = {
            title = _('menu_boss'),
            icon = 'briefcase',
            onSelect = OpenBossMenu,
        }
    end

    if #options == 0 then
        return Client.NotifyErr('not_authorized')
    end

    lib.registerContext({
        id = 'wholesaler_main',
        title = _('menu_title'),
        options = options,
    })
    lib.showContext('wholesaler_main')
end

--- Achat — catégories
function OpenBuyMenu()
    local categories = lib.callback.await('core_wholesaler:getCategories', false)
    if not categories or #categories == 0 then
        return Client.NotifyErr('not_authorized')
    end

    local options = {}
    for _, cat in ipairs(categories) do
        options[#options + 1] = {
            title = cat.label,
            icon = cat.icon or 'tag',
            onSelect = function()
                OpenCategoryProducts(cat.id, cat.label)
            end,
        }
    end

    if #Client.cart > 0 then
        options[#options + 1] = {
            title = _('cart_title') .. (' (%s)'):format(#Client.cart),
            icon = 'basket-shopping',
            arrow = true,
            onSelect = OpenCartMenu,
        }
    end

    lib.registerContext({
        id = 'wholesaler_buy',
        title = _('menu_buy'),
        menu = 'wholesaler_main',
        options = options,
    })
    lib.showContext('wholesaler_buy')
end

--- Produits d'une catégorie
---@param catId string
---@param catLabel string
function OpenCategoryProducts(catId, catLabel)
    local stock = lib.callback.await('core_wholesaler:getStock', false, { catId })
    if not stock or #stock == 0 then
        return Client.Notify(_('stock_empty'), 'inform')
    end

    local options = {}
    for _, product in ipairs(stock) do
        options[#options + 1] = {
            title = product.label,
            description = ('%s  •  %s'):format(
                _('product_stock', product.quantity),
                _('product_price', Wholesaler.FormatMoney(product.price))
            ),
            icon = 'nui://ox_inventory/web/images/' .. (product.image or product.item) .. '.png',
            metadata = {
                { label = 'Stock', value = product.quantity },
                { label = 'Prix', value = '$' .. Wholesaler.FormatMoney(product.price) },
                { label = 'Catégorie', value = product.categoryLabel or catLabel },
            },
            onSelect = function()
                OpenProductBuy(product)
            end,
        }
    end

    lib.registerContext({
        id = 'wholesaler_cat_' .. catId,
        title = catLabel,
        menu = 'wholesaler_buy',
        options = options,
    })
    lib.showContext('wholesaler_cat_' .. catId)
end

--- Dialog quantité
---@param product table
function OpenProductBuy(product)
    if product.quantity < 1 then
        return Client.NotifyErr('out_of_stock')
    end

    local input = lib.inputDialog(product.label, {
        {
            type = 'number',
            label = _('product_qty'),
            description = _('product_stock', product.quantity),
            required = true,
            min = 1,
            max = math.min(product.quantity, Config.Orders.maxQtyPerLine),
            default = 1,
        },
    })

    if not input then return end
    local qty = math.floor(tonumber(input[1]) or 0)
    if qty < 1 then return Client.NotifyErr('invalid_amount') end

    if Client.AddToCart(product.item, product.label, product.price, qty, product.image) then
        Client.Notify(_('cart_add'), 'success')
    end

    OpenCartMenu()
end

--- Panier + checkout
function OpenCartMenu()
    if #Client.cart == 0 then
        return Client.Notify(_('cart_empty'), 'inform')
    end

    local totals = lib.callback.await('core_wholesaler:calcTotal', false, Client.cart)
    local options = {}

    for i, line in ipairs(Client.cart) do
        options[#options + 1] = {
            title = ('%s × %s'):format(line.qty, line.label),
            description = ('$%s'):format(Wholesaler.FormatMoney(line.price * line.qty)),
            icon = line.image and ('nui://ox_inventory/web/images/%s.png'):format(line.image) or 'box',
            onSelect = function()
                table.remove(Client.cart, i)
                OpenCartMenu()
            end,
        }
    end

    options[#options + 1] = {
        title = _('cart_checkout'),
        description = _('cart_total', Wholesaler.FormatMoney(totals.total)),
        icon = 'credit-card',
        iconColor = 'green',
        onSelect = function()
            OpenCheckout(totals)
        end,
    }

    options[#options + 1] = {
        title = _('cart_clear'),
        icon = 'trash',
        iconColor = 'red',
        onSelect = function()
            Client.ClearCart()
            Client.Notify(_('cart_empty'), 'inform')
        end,
    }

    lib.registerContext({
        id = 'wholesaler_cart',
        title = _('cart_title'),
        menu = 'wholesaler_buy',
        options = options,
    })
    lib.showContext('wholesaler_cart')
end

---@param totals table
function OpenCheckout(totals)
    local access = ensureAccess()
    local methods = {}
    local pm = access and access.paymentMethods or Config.Payment.methods

    if pm.society then
        methods[#methods + 1] = { value = 'society', label = _('pay_society') }
    end
    if pm.bank then
        methods[#methods + 1] = { value = 'bank', label = _('pay_bank') }
    end
    if pm.cash then
        methods[#methods + 1] = { value = 'cash', label = _('pay_cash') }
    end

    local fulfillOpts = {
        { value = 'pickup', label = _('mode_pickup') },
    }
    if Config.Delivery.enabled then
        fulfillOpts[#fulfillOpts + 1] = { value = 'delivery', label = _('mode_delivery') }
    end

    local input = lib.inputDialog(_('cart_checkout'), {
        {
            type = 'select',
            label = _('payment_method'),
            options = methods,
            required = true,
            default = methods[1] and methods[1].value,
        },
        {
            type = 'select',
            label = _('delivery_mode'),
            options = fulfillOpts,
            required = true,
            default = 'pickup',
        },
        {
            type = 'textarea',
            label = _('vat_included', Wholesaler.FormatMoney(totals.vat)),
            disabled = true,
            default = ('HT: $%s | Taxe: $%s | TVA: $%s | TTC: $%s'):format(
                Wholesaler.FormatMoney(totals.subtotal),
                Wholesaler.FormatMoney(totals.tax),
                Wholesaler.FormatMoney(totals.vat),
                Wholesaler.FormatMoney(totals.total)
            ),
        },
    })

    if not input then return end

    local method = input[1]
    local fulfillment = input[2]
    local deliveryCoords

    if fulfillment == 'delivery' then
        local ped = cache.ped
        local c = GetEntityCoords(ped)
        deliveryCoords = { x = c.x, y = c.y, z = c.z }
    end

    local result = lib.callback.await('core_wholesaler:createOrder', false, {
        cart = Client.cart,
        method = method,
        fulfillment = fulfillment,
        deliveryCoords = deliveryCoords,
    })

    if not result or not result.ok then
        return Client.NotifyErr(result and result.err)
    end

    Client.ClearCart()
end

--- Stock disponible (lecture)
function OpenStockMenu()
    local stock = lib.callback.await('core_wholesaler:getStock', false)
    if not stock or #stock == 0 then
        return Client.Notify(_('stock_empty'), 'inform')
    end

    local options = {}
    for _, product in ipairs(stock) do
        options[#options + 1] = {
            title = product.label,
            description = _('stock_qty', product.quantity, product.categoryLabel or product.category, Wholesaler.FormatMoney(product.price)),
            icon = 'nui://ox_inventory/web/images/' .. (product.image or product.item) .. '.png',
            metadata = {
                { label = 'Stock', value = product.quantity },
                { label = 'Prix', value = '$' .. Wholesaler.FormatMoney(product.price) },
                { label = 'Catégorie', value = product.categoryLabel or product.category },
            },
            readOnly = true,
        }
    end

    lib.registerContext({
        id = 'wholesaler_stock',
        title = _('stock_title'),
        menu = 'wholesaler_main',
        options = options,
    })
    lib.showContext('wholesaler_stock')
end

--- Historique
function OpenHistoryMenu()
    local rows = lib.callback.await('core_wholesaler:getHistory', false)
    if not rows or #rows == 0 then
        return Client.Notify(_('history_empty'), 'inform')
    end

    local options = {}
    for _, row in ipairs(rows) do
        options[#options + 1] = {
            title = _('history_entry', row.order_id or row.id, Wholesaler.FormatMoney(row.amount or 0), row.action),
            description = tostring(row.created_at or ''),
            icon = 'receipt',
            readOnly = true,
        }
    end

    lib.registerContext({
        id = 'wholesaler_history',
        title = _('history_title'),
        menu = 'wholesaler_main',
        options = options,
    })
    lib.showContext('wholesaler_history')
end

--- Mes commandes
function OpenOrdersMenu()
    local rows = lib.callback.await('core_wholesaler:getMyOrders', false)
    if not rows or #rows == 0 then
        return Client.Notify(_('orders_empty'), 'inform')
    end

    local options = {}
    for _, row in ipairs(rows) do
        local itemCount = type(row.items) == 'table' and #row.items or 0
        options[#options + 1] = {
            title = ('#%s — %s'):format(row.id, row.statusLabel or row.status),
            description = _('order_total', Wholesaler.FormatMoney(row.total)),
            icon = 'file-invoice',
            metadata = {
                { label = 'Statut', value = row.statusLabel or row.status },
                { label = 'Total', value = '$' .. Wholesaler.FormatMoney(row.total) },
                { label = 'Articles', value = itemCount },
                { label = 'Mode', value = row.fulfillment },
                { label = 'Date', value = tostring(row.created_at or '') },
            },
            readOnly = true,
        }
    end

    lib.registerContext({
        id = 'wholesaler_orders',
        title = _('orders_title'),
        menu = 'wholesaler_main',
        options = options,
    })
    lib.showContext('wholesaler_orders')
end

--- Retrait
function OpenPickupMenu()
    local rows = lib.callback.await('core_wholesaler:getPickupOrders', false)
    if not rows or #rows == 0 then
        return Client.Notify(_('pickup_none'), 'inform')
    end

    local options = {}
    for _, row in ipairs(rows) do
        local desc = {}
        for _, line in ipairs(row.items or {}) do
            desc[#desc + 1] = ('%sx %s'):format(line.qty, line.label or line.item)
        end
        options[#options + 1] = {
            title = ('#%s — $%s'):format(row.id, Wholesaler.FormatMoney(row.total)),
            description = table.concat(desc, ', '),
            icon = 'box-open',
            onSelect = function()
                local result = lib.callback.await('core_wholesaler:withdrawOrder', false, row.id)
                if not result or not result.ok then
                    Client.NotifyErr(result and result.err)
                end
            end,
        }
    end

    lib.registerContext({
        id = 'wholesaler_pickup',
        title = _('pickup_title'),
        options = options,
    })
    lib.showContext('wholesaler_pickup')
end

--- Admin rapide (stock / prix / import)
function OpenAdminMenu()
    lib.registerContext({
        id = 'wholesaler_admin',
        title = _('admin_title'),
        menu = 'wholesaler_main',
        options = {
            {
                title = _('boss_add_stock'),
                icon = 'plus',
                onSelect = AdminAddStock,
            },
            {
                title = _('boss_remove_stock'),
                icon = 'minus',
                onSelect = AdminRemoveStock,
            },
            {
                title = _('boss_edit_price'),
                icon = 'dollar-sign',
                onSelect = AdminEditPrice,
            },
            {
                title = _('boss_import'),
                icon = 'truck-ramp-box',
                onSelect = AdminImport,
            },
        },
    })
    lib.showContext('wholesaler_admin')
end

function AdminAddStock()
    local stock = lib.callback.await('core_wholesaler:getStock', false)
    if not stock or #stock == 0 then return end

    local opts = {}
    for _, p in ipairs(stock) do
        opts[#opts + 1] = { value = p.item, label = ('%s (%s)'):format(p.label, p.quantity) }
    end

    local input = lib.inputDialog(_('boss_add_stock'), {
        { type = 'select', label = 'Produit', options = opts, required = true },
        { type = 'number', label = 'Quantité', min = 1, required = true, default = 10 },
    })
    if not input then return end

    local result = lib.callback.await('core_wholesaler:addStock', false, input[1], input[2])
    if not result or not result.ok then Client.NotifyErr(result and result.err) end
end

function AdminRemoveStock()
    local stock = lib.callback.await('core_wholesaler:getStock', false)
    if not stock or #stock == 0 then return end

    local opts = {}
    for _, p in ipairs(stock) do
        opts[#opts + 1] = { value = p.item, label = ('%s (%s)'):format(p.label, p.quantity) }
    end

    local input = lib.inputDialog(_('boss_remove_stock'), {
        { type = 'select', label = 'Produit', options = opts, required = true },
        { type = 'number', label = 'Quantité', min = 1, required = true, default = 1 },
    })
    if not input then return end

    local result = lib.callback.await('core_wholesaler:removeStock', false, input[1], input[2])
    if not result or not result.ok then Client.NotifyErr(result and result.err) end
end

function AdminEditPrice()
    local stock = lib.callback.await('core_wholesaler:getStock', false)
    if not stock or #stock == 0 then return end

    local opts = {}
    for _, p in ipairs(stock) do
        opts[#opts + 1] = { value = p.item, label = ('%s — $%s'):format(p.label, p.price) }
    end

    local input = lib.inputDialog(_('boss_edit_price'), {
        { type = 'select', label = 'Produit', options = opts, required = true },
        { type = 'number', label = 'Nouveau prix', min = 0, required = true },
    })
    if not input then return end

    local result = lib.callback.await('core_wholesaler:setPrice', false, input[1], input[2])
    if not result or not result.ok then Client.NotifyErr(result and result.err) end
end

function AdminImport()
    local stock = lib.callback.await('core_wholesaler:getStock', false)
    if not stock or #stock == 0 then return end

    local opts = {}
    for _, p in ipairs(stock) do
        opts[#opts + 1] = { value = p.item, label = p.label }
    end

    local input = lib.inputDialog(_('boss_import'), {
        { type = 'select', label = 'Produit', options = opts, required = true },
        { type = 'number', label = 'Quantité', min = 1, required = true, default = 50 },
    })
    if not input then return end

    local result = lib.callback.await('core_wholesaler:importDelivery', false, {
        { item = input[1], qty = input[2] },
    })
    if not result or not result.ok then Client.NotifyErr(result and result.err) end
end
