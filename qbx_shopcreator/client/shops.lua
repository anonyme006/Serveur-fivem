Client = Client or {}
Client.shops = Client.shops or {}

---@param key string
---@return string
local function L(key)
    local locale = Locales[Config.Locale] or Locales.fr or {}
    return locale[key] or key
end

---@param shopId number
---@return table|nil
function Client.GetShop(shopId)
    shopId = tonumber(shopId)
    if not shopId then return nil end
    return Client.shops[shopId]
end

---@param shop table
---@param locationType string
---@return table|nil
function Client.GetShopLocation(shop, locationType)
    if not shop or type(shop.locations) ~= 'table' then return nil end
    for i = 1, #shop.locations do
        local loc = shop.locations[i]
        if loc.location_type == locationType then
            return loc
        end
    end
    return nil
end

---@param shop table
---@param locationType string
---@return table[]
function Client.GetShopLocations(shop, locationType)
    local list = {}
    if not shop or type(shop.locations) ~= 'table' then return list end
    for i = 1, #shop.locations do
        local loc = shop.locations[i]
        if loc.location_type == locationType then
            list[#list + 1] = loc
        end
    end
    return list
end

---@param shop table
---@return table|nil
function Client.GetPrimaryCoords(shop)
    local loc = Client.GetShopLocation(shop, ShopCreator.LocationTypes.customer)
    if not loc then
        loc = Client.GetShopLocation(shop, ShopCreator.LocationTypes.management)
    end
    return loc
end

---@param shop table
---@return boolean
function Client.IsShopOpenLocal(shop)
    if not shop then return false end
    return ShopCreator.IsShopOpen(shop, GetClockHours(), GetClockMinutes())
end

---@param message string
---@param nType? string
function Client.Notify(message, nType)
    lib.notify({
        title = 'Shop Creator',
        description = message,
        type = nType or 'inform',
    })
end

---@param shopId number
---@param shop table
---@param isPatch boolean|nil
function Client.ApplyShopUpdate(shopId, shop, isPatch)
    shopId = tonumber(shopId) or tonumber(shop and shop.id)
    if not shopId or type(shop) ~= 'table' then return end

    shop.id = shopId

    if isPatch and Client.shops[shopId] then
        local existing = Client.shops[shopId]
        for key, value in pairs(shop) do
            if type(value) == 'table' and type(existing[key]) == 'table' and key ~= 'blip' and key ~= 'npc' then
                existing[key] = value
            else
                existing[key] = value
            end
        end
    else
        Client.shops[shopId] = shop
    end

    TriggerEvent('qbx_shopcreator:internal:shopUpdated', shopId)
end

---@param shopId number
function Client.RemoveShop(shopId)
    shopId = tonumber(shopId)
    if not shopId then return end
    Client.shops[shopId] = nil
    TriggerEvent('qbx_shopcreator:internal:shopRemoved', shopId)
end

---@param shops table
function Client.SyncShops(shops)
    Client.shops = {}

    if type(shops) == 'table' then
        if shops[1] then
            for i = 1, #shops do
                local shop = shops[i]
                if shop and shop.id then
                    Client.shops[shop.id] = shop
                end
            end
        else
            for id, shop in pairs(shops) do
                if type(shop) == 'table' then
                    local shopId = tonumber(shop.id) or tonumber(id)
                    if shopId then
                        shop.id = shopId
                        Client.shops[shopId] = shop
                    end
                end
            end
        end
    end

    TriggerEvent('qbx_shopcreator:internal:shopsSynced')
end

---@return table[]
function Client.GetAllShops()
    local list = {}
    for _, shop in pairs(Client.shops) do
        list[#list + 1] = shop
    end
    return list
end

---@return string
function Client.StashId(shopId)
    return ('shopcreator_%s'):format(tonumber(shopId) or 0)
end

local function unwrapList(result)
    if type(result) ~= 'table' then return nil end
    if result.ok and type(result.data) == 'table' then return result.data end
    if result[1] ~= nil or next(result) == nil then return result end
    return nil
end

local function requestInitialShops()
    local ok, result = pcall(function()
        return lib.callback.await('qbx_shopcreator:requestShops', false)
    end)

    local list = ok and unwrapList(result) or nil
    if list then
        Client.SyncShops(list)
        return
    end

    ok, result = pcall(function()
        return lib.callback.await('qbx_shopcreator:syncShops', false)
    end)

    list = ok and unwrapList(result) or nil
    if list then
        Client.SyncShops(list)
    end
end

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(500)
    end
    Wait(1000)
    requestInitialShops()
end)

RegisterNetEvent('qbx_shopcreator:client:refreshShop', function(shopId, shop, isPatch)
    Client.ApplyShopUpdate(shopId, shop, isPatch)
end)

RegisterNetEvent('qbx_shopcreator:client:removeShop', function(shopId)
    Client.RemoveShop(shopId)
end)

RegisterNetEvent('qbx_shopcreator:client:syncShops', function(shops)
    Client.SyncShops(shops)
end)

exports('GetShop', Client.GetShop)
exports('GetAllShops', Client.GetAllShops)
