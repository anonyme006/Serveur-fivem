ShopCreator = ShopCreator or {}

ShopCreator.Resource = GetCurrentResourceName()

ShopCreator.LocationTypes = {
    customer = 'customer',
    management = 'management',
    storage = 'storage',
    delivery = 'delivery',
    garage = 'garage',
    vehicle_spawn = 'vehicle_spawn',
    vehicle_return = 'vehicle_return',
}

ShopCreator.OwnershipModes = {
    none = 'none',
    purchasable = 'purchasable',
    owned = 'owned',
}

ShopCreator.DeliveryMethods = {
    instant = 'instant',
    self = 'self',
    public = 'public',
}

ShopCreator.OrderStatus = {
    pending = 'pending',
    accepted = 'accepted',
    in_transit = 'in_transit',
    delivered = 'delivered',
    cancelled = 'cancelled',
}

ShopCreator.JobStatus = {
    open = 'open',
    accepted = 'accepted',
    completed = 'completed',
    cancelled = 'cancelled',
}

ShopCreator.TransactionTypes = {
    sale = 'sale',
    deposit = 'deposit',
    withdrawal = 'withdrawal',
    ownership = 'ownership',
    stock_order = 'stock_order',
    delivery_payout = 'delivery_payout',
    shop_change = 'shop_change',
    refund = 'refund',
}

ShopCreator.DefaultPermissions = {
    open_business = false,
    control_status = false,
    view_balance = false,
    deposit_funds = false,
    withdraw_funds = false,
    view_activity = false,
    manage_products = false,
    deposit_stock = false,
    withdraw_stock = false,
    create_stock_orders = false,
    collect_stock_orders = false,
    publish_delivery_jobs = false,
    automatic_delivery = false,
    upgrade_storage = false,
    manage_employees = false,
    manage_permissions = false,
    use_garage = false,
    customize_storefront = false,
}

ShopCreator.OwnerPermissions = (function()
    local perms = {}
    for key in pairs(ShopCreator.DefaultPermissions) do
        perms[key] = true
    end
    return perms
end)()

ShopCreator.PermissionGroups = {
    {
        id = 'dashboard',
        label = 'Dashboard and Funds',
        keys = {
            'open_business',
            'control_status',
            'view_balance',
            'deposit_funds',
            'withdraw_funds',
            'view_activity',
        },
    },
    {
        id = 'products',
        label = 'Products and Stock',
        keys = {
            'manage_products',
            'deposit_stock',
            'withdraw_stock',
            'create_stock_orders',
            'collect_stock_orders',
            'publish_delivery_jobs',
            'automatic_delivery',
            'upgrade_storage',
        },
    },
    {
        id = 'team',
        label = 'Team and Operations',
        keys = {
            'manage_employees',
            'manage_permissions',
            'use_garage',
            'customize_storefront',
        },
    },
}