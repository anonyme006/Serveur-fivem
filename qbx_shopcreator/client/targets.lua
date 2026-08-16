Client = Client or {}
Client.targetZones = Client.targetZones or {}

local function L(key)
    local locale = Locales[Config.Locale] or Locales.fr or {}
    return locale[key] or key
end

local targetDistance = Config.Target.distance or 2.0

---@param shopId number
local function clearShopTargets(shopId)
    local zones = Client.targetZones[shopId]
    if not zones then return end

    for i = 1, #zones do
        local zoneId = zones[i]
        if zoneId then
            exports.ox_target:removeZone(zoneId)
        end
    end

    Client.targetZones[shopId] = nil
end

---@param shopId number
---@param zoneId number|string
local function trackZone(shopId, zoneId)
    if not Client.targetZones[shopId] then
        Client.targetZones[shopId] = {}
    end
    Client.targetZones[shopId][#Client.targetZones[shopId] + 1] = zoneId
end

---@param shop table
---@param loc table
---@param options table
local function addLocationZone(shop, loc, options)
    local zoneId = exports.ox_target:addSphereZone({
        coords = vec3(loc.x, loc.y, loc.z),
        radius = targetDistance,
        debug = Config.Debug,
        options = options,
    })
    trackZone(shop.id, zoneId)
end

---@param shop table
local function buildCustomerTargets(shop)
    local locations = Client.GetShopLocations(shop, ShopCreator.LocationTypes.customer)
    for i = 1, #locations do
        local loc = locations[i]
        local options = {
            {
                name = ('shopcreator_customer_%s_%s'):format(shop.id, i),
                icon = Config.Target.icon,
                label = L('open_shop'),
                distance = targetDistance,
                canInteract = function()
                    return shop.enabled and Client.IsShopOpenLocal(shop)
                end,
                onSelect = function()
                    Client.OpenStorefront(shop.id, 'storefront')
                end,
            },
        }

        if shop.ownership_mode == ShopCreator.OwnershipModes.purchasable then
            options[#options + 1] = {
                name = ('shopcreator_buy_%s_%s'):format(shop.id, i),
                icon = 'fas fa-store',
                label = L('buy_shop'),
                distance = targetDistance,
                onSelect = function()
                    Client.OpenStorefront(shop.id, 'storefront')
                end,
            }
        end

        addLocationZone(shop, loc, options)
    end
end

---@param shop table
local function buildManagementTargets(shop)
    local loc = Client.GetShopLocation(shop, ShopCreator.LocationTypes.management)
    if not loc then return end

    addLocationZone(shop, loc, {
        {
            name = ('shopcreator_management_%s'):format(shop.id),
            icon = Config.Target.managementIcon,
            label = L('open_management'),
            distance = targetDistance,
            onSelect = function()
                Client.OpenManagement(shop.id)
            end,
        },
    })
end

---@param shop table
local function buildStorageTargets(shop)
    local loc = Client.GetShopLocation(shop, ShopCreator.LocationTypes.storage)
    if not loc then return end

    addLocationZone(shop, loc, {
        {
            name = ('shopcreator_storage_%s'):format(shop.id),
            icon = Config.Target.storageIcon,
            label = L('open_storage'),
            distance = targetDistance,
            onSelect = function()
                exports.ox_inventory:openInventory('stash', Client.StashId(shop.id))
            end,
        },
    })
end

---@param shop table
local function buildDeliveryTargets(shop)
    local loc = Client.GetShopLocation(shop, ShopCreator.LocationTypes.delivery)
    if not loc then return end

    addLocationZone(shop, loc, {
        {
            name = ('shopcreator_delivery_%s'):format(shop.id),
            icon = Config.Target.deliveryIcon,
            label = L('open_delivery'),
            distance = targetDistance,
            onSelect = function()
                Client.OpenDeliveries()
            end,
        },
    })
end

---@param shop table
local function buildGarageTargets(shop)
    local garageLoc = Client.GetShopLocation(shop, ShopCreator.LocationTypes.garage)
    if garageLoc then
        addLocationZone(shop, garageLoc, {
            {
                name = ('shopcreator_garage_%s'):format(shop.id),
                icon = Config.Target.garageIcon,
                label = L('open_garage'),
                distance = targetDistance,
                onSelect = function()
                    TriggerEvent('qbx_shopcreator:client:garage:open', shop.id)
                end,
            },
        })
    end

    local returnLoc = Client.GetShopLocation(shop, ShopCreator.LocationTypes.vehicle_return)
    if returnLoc then
        addLocationZone(shop, returnLoc, {
            {
                name = ('shopcreator_vehicle_return_%s'):format(shop.id),
                icon = Config.Target.garageIcon,
                label = L('return_vehicle'),
                distance = Config.Garage.returnRadius or 6.0,
                onSelect = function()
                    TriggerEvent('qbx_shopcreator:client:garage:return', shop.id)
                end,
            },
        })
    end
end

---@param shop table
local function buildShopTargets(shop)
    if not shop or not shop.id then return end
    if not shop.enabled or shop.enabled == 0 or shop.enabled == false then
        clearShopTargets(shop.id)
        return
    end

    clearShopTargets(shop.id)
    buildCustomerTargets(shop)
    buildManagementTargets(shop)
    buildStorageTargets(shop)
    buildDeliveryTargets(shop)
    buildGarageTargets(shop)
end

function Client.RebuildTargets(shopId)
    local shop = Client.GetShop(shopId)
    if shop then
        buildShopTargets(shop)
    else
        clearShopTargets(shopId)
    end
end

function Client.RebuildAllTargets()
    for shopId in pairs(Client.targetZones) do
        clearShopTargets(shopId)
    end

    for _, shop in pairs(Client.shops) do
        buildShopTargets(shop)
    end
end

function Client.CleanupTargets()
    for shopId in pairs(Client.targetZones) do
        clearShopTargets(shopId)
    end
end

AddEventHandler('qbx_shopcreator:internal:shopUpdated', function(shopId)
    Client.RebuildTargets(shopId)
end)

AddEventHandler('qbx_shopcreator:internal:shopRemoved', function(shopId)
    clearShopTargets(shopId)
end)

AddEventHandler('qbx_shopcreator:internal:shopsSynced', function()
    Client.RebuildAllTargets()
end)

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(500)
    end
    Wait(2000)
    Client.RebuildAllTargets()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= ShopCreator.Resource then return end
    Client.CleanupTargets()
end)
