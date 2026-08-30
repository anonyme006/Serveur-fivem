local zones = {}

local function can(permission)
    return select(1, Rest.GetLocalJob()) ~= nil and (not permission or Rest.Can(permission))
end

local function zone(loc, options)
    if not loc or not loc.coords then return end
    zones[#zones + 1] = exports.ox_target:addBoxZone({
        coords = loc.coords,
        size = loc.size or vec3(1.5, 1.5, 2.0),
        rotation = loc.rotation or 0.0,
        debug = Config.Debug,
        options = options,
    })
end

CreateThread(function()
    for key, restaurant in pairs(Config.Restaurants) do
        local L = restaurant.locations or {}

        if L.Cashier then
            zone(L.Cashier, {
                {
                    name = key .. '_cash',
                    icon = 'fas fa-cash-register',
                    label = 'Ouvrir la caisse',
                    canInteract = function() return can('sales') end,
                    onSelect = function() Rest.OpenTablet('sales') end,
                },
                {
                    name = key .. '_tab',
                    icon = 'fas fa-tablet-screen-button',
                    label = 'Ouvrir la tablette',
                    canInteract = function() return can('tablet') end,
                    onSelect = function() Rest.OpenTablet('dashboard') end,
                },
            })
        end

        if L.Kitchen and Config.EnableCrafting then
            zone(L.Kitchen, {
                {
                    name = key .. '_kit',
                    icon = 'fas fa-utensils',
                    label = 'Ouvrir la cuisine',
                    canInteract = function() return can('kitchen') end,
                    onSelect = function() Rest.OpenCraftMenu() end,
                },
                {
                    name = key .. '_rec',
                    icon = 'fas fa-book',
                    label = 'Recettes',
                    canInteract = function() return can('recipes') end,
                    onSelect = function() Rest.OpenTablet('recipes') end,
                },
            })
        end

        if L.Storage and Config.EnableStock then
            zone(L.Storage, {
                {
                    name = key .. '_stash',
                    icon = 'fas fa-box',
                    label = 'Ouvrir le stock',
                    canInteract = function() return can('stock') end,
                    onSelect = function() TriggerServerEvent('qbox_restaurants:server:openStash') end,
                },
                {
                    name = key .. '_stock',
                    icon = 'fas fa-clipboard-list',
                    label = 'Gestion du stock',
                    canInteract = function() return can('stock') end,
                    onSelect = function() Rest.OpenTablet('stock') end,
                },
            })
        end

        if L.Boss then
            zone(L.Boss, {
                {
                    name = key .. '_boss',
                    icon = 'fas fa-briefcase',
                    label = 'Bureau patron',
                    canInteract = function() return can('employees') or can('settings') end,
                    onSelect = function() Rest.OpenTablet('employees') end,
                },
            })
        end

        if L.Cloakroom then
            zone(L.Cloakroom, {
                {
                    name = key .. '_cloak',
                    icon = 'fas fa-shirt',
                    label = 'Prendre / quitter le service',
                    canInteract = function() return can('service') end,
                    onSelect = function() Rest.ToggleService() end,
                },
            })
        end

        if L.Delivery and Config.EnableDeliveries then
            zone(L.Delivery, {
                {
                    name = key .. '_del_done',
                    icon = 'fas fa-truck',
                    label = 'Déposer la livraison',
                    canInteract = function() return can('deliveries') and Rest.CurrentDelivery ~= nil end,
                    onSelect = function() Rest.CompleteDelivery() end,
                },
                {
                    name = key .. '_del_list',
                    icon = 'fas fa-list',
                    label = 'Voir les livraisons',
                    canInteract = function() return can('deliveries') end,
                    onSelect = function() Rest.OpenTablet('deliveries') end,
                },
            })
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for i = 1, #zones do exports.ox_target:removeZone(zones[i]) end
end)
