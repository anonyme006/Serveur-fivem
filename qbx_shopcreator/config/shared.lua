Config = {}

Config.Debug = false

Config.AdminCommand = 'shopcreator'
Config.AdminAce = 'qbx_shopcreator.admin'
--- Qbox permission names accepted for admin access (OR with ACE)
Config.AdminPermissions = { 'admin', 'god' }

Config.Locale = 'fr'

Config.Target = {
    distance = 2.0,
    icon = 'fas fa-shopping-basket',
    managementIcon = 'fas fa-briefcase',
    storageIcon = 'fas fa-box',
    deliveryIcon = 'fas fa-truck',
    garageIcon = 'fas fa-warehouse',
}

Config.LowStockThreshold = 5
Config.MaxCategoriesPerShop = 32
Config.MaxProductsPerShop = 250
Config.MaxEmployeesPerShop = 40
Config.MaxCustomerPoints = 12

Config.Payments = {
    cash = true,
    bank = true,
}

Config.Purchase = {
    maxCartItems = 40,
    maxQuantityPerLine = 50,
}

Config.Stock = {
    defaultCapacity = 500,
    orderCapacityBuffer = 0,
}

Config.Delivery = {
    instantEnabled = true,
    selfEnabled = true,
    publicEnabled = true,
    publicRewardPercent = 0.12,
    publicMinReward = 150,
    publicMaxReward = 5000,
    pickupRadius = 4.0,
    dropoffRadius = 4.0,
    vehicleModel = 'boxville2',
    --- Default warehouse pickup when shop has no dedicated delivery point
    defaultPickup = vec4(1197.28, -3253.55, 7.1, 90.0),
}

Config.Ownership = {
    defaultBuyPrice = 50000,
    defaultResalePercent = 70,
    defaultInitialFunds = 0,
}

Config.Blip = {
    enabled = true,
    sprite = 52,
    color = 2,
    scale = 0.75,
}

Config.Npc = {
    enabled = false,
    model = 'mp_m_shopkeep_01',
    scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
}

Config.Garage = {
    maxVehicles = 8,
    returnRadius = 6.0,
}

Config.Hours = {
    --- Server clock uses GetClockHours / GetClockMinutes on client for display;
    --- open checks use os.date on server for authoritative state.
    timezoneOffsetHours = 0,
}

Config.RateLimit = {
    windowMs = 1500,
    purchaseMs = 2000,
    fundsMs = 2000,
    deliveryMs = 2500,
}

Config.Sync = {
    --- Send full shop payload only to players who need management data
    managementRadius = 80.0,
}

Config.Stash = {
    slots = 80,
    weight = 500000,
}

Config.Logging = {
    enabled = true,
    console = true,
    --- Optional Discord webhook (leave empty to disable)
    webhook = '',
}