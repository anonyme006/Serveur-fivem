local zones = {}

local function canUse(permission)
    local key = select(1, RexDiner.GetLocalJob())
    if not key then return false end
    if permission and not RexDiner.HasLocalPermission(permission) then
        return false
    end
    return true
end

local function addZone(id, loc, options)
    if not loc or not loc.coords then return end
    zones[#zones + 1] = exports.ox_target:addBoxZone({
        coords = loc.coords,
        size = loc.size or vec3(1.5, 1.5, 2.0),
        rotation = loc.rotation or 0.0,
        debug = Config.Debug,
        options = options,
    })
end

local function setupRestaurantTargets(restaurantKey, restaurant)
    local locs = restaurant.locations or {}

    if locs.Cashier then
        addZone(restaurantKey .. '_cashier', locs.Cashier, {
            {
                name = restaurantKey .. '_cashier_open',
                icon = locs.Cashier.icon or 'fas fa-cash-register',
                label = 'Ouvrir la caisse',
                canInteract = function()
                    return canUse('sales')
                end,
                onSelect = function()
                    RexDiner.OpenTablet('sales')
                end,
            },
            {
                name = restaurantKey .. '_cashier_tablet',
                icon = 'fas fa-tablet-screen-button',
                label = 'Ouvrir la tablette',
                canInteract = function()
                    return canUse('tablet')
                end,
                onSelect = function()
                    RexDiner.OpenTablet('dashboard')
                end,
            },
        })
    end

    if locs.Kitchen and Config.EnableCrafting then
        addZone(restaurantKey .. '_kitchen', locs.Kitchen, {
            {
                name = restaurantKey .. '_kitchen_craft',
                icon = locs.Kitchen.icon or 'fas fa-utensils',
                label = 'Ouvrir la cuisine',
                canInteract = function()
                    return canUse('kitchen')
                end,
                onSelect = function()
                    RexDiner.OpenCraftMenu()
                end,
            },
            {
                name = restaurantKey .. '_kitchen_recipes',
                icon = 'fas fa-book',
                label = 'Recettes (tablette)',
                canInteract = function()
                    return canUse('recipes')
                end,
                onSelect = function()
                    RexDiner.OpenTablet('recipes')
                end,
            },
        })
    end

    if locs.Storage and Config.EnableStock then
        addZone(restaurantKey .. '_storage', locs.Storage, {
            {
                name = restaurantKey .. '_storage_open',
                icon = locs.Storage.icon or 'fas fa-box',
                label = 'Ouvrir le stock',
                canInteract = function()
                    return canUse('stock')
                end,
                onSelect = function()
                    TriggerServerEvent('rex_diner:server:openStash')
                end,
            },
            {
                name = restaurantKey .. '_storage_manage',
                icon = 'fas fa-clipboard-list',
                label = 'Gestion du stock',
                canInteract = function()
                    return canUse('stock')
                end,
                onSelect = function()
                    RexDiner.OpenTablet('stock')
                end,
            },
        })
    end

    if locs.Boss then
        addZone(restaurantKey .. '_boss', locs.Boss, {
            {
                name = restaurantKey .. '_boss_menu',
                icon = locs.Boss.icon or 'fas fa-briefcase',
                label = 'Bureau patron',
                canInteract = function()
                    return canUse('employees') or canUse('finances') or canUse('settings')
                end,
                onSelect = function()
                    RexDiner.OpenTablet('employees')
                end,
            },
        })
    end

    if locs.Cloakroom then
        addZone(restaurantKey .. '_cloak', locs.Cloakroom, {
            {
                name = restaurantKey .. '_cloak_service',
                icon = locs.Cloakroom.icon or 'fas fa-shirt',
                label = 'Prendre / quitter le service',
                canInteract = function()
                    return canUse('service')
                end,
                onSelect = function()
                    RexDiner.ToggleService()
                end,
            },
        })
    end

    if locs.Delivery and Config.EnableDeliveries then
        addZone(restaurantKey .. '_delivery', locs.Delivery, {
            {
                name = restaurantKey .. '_delivery_complete',
                icon = locs.Delivery.icon or 'fas fa-truck',
                label = 'Déposer la livraison',
                canInteract = function()
                    return canUse('deliveries') and RexDiner.CurrentDelivery ~= nil
                end,
                onSelect = function()
                    RexDiner.CompleteDelivery()
                end,
            },
            {
                name = restaurantKey .. '_delivery_list',
                icon = 'fas fa-list',
                label = 'Voir les livraisons',
                canInteract = function()
                    return canUse('deliveries')
                end,
                onSelect = function()
                    RexDiner.OpenTablet('deliveries')
                end,
            },
        })
    end
end

CreateThread(function()
    for key, restaurant in pairs(Config.Restaurants) do
        setupRestaurantTargets(key, restaurant)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for i = 1, #zones do
        exports.ox_target:removeZone(zones[i])
    end
end)
