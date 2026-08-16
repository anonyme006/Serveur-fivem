ShopCreator = ShopCreator or {}

ShopCreator.Garage = ShopCreator.Garage or {
    active = {},
}

---@param source number
---@return table|nil
local function getActive(source)
    return ShopCreator.Garage.active[source]
end

---@param source number
local function clearActive(source)
    ShopCreator.Garage.active[source] = nil
end

AddEventHandler('playerDropped', function()
    clearActive(source)
end)

---@param shop table
---@param locationType string
---@return table|nil
local function getShopLocation(shop, locationType)
    for i = 1, #(shop.locations or {}) do
        local loc = shop.locations[i]
        if loc.location_type == locationType then
            return loc
        end
    end
    return nil
end

---@param source number
---@param shopId number
---@param vehicleId number
---@return table
function ShopCreator.TakeVehicle(source, shopId, vehicleId)
    shopId = tonumber(shopId)
    vehicleId = tonumber(vehicleId)

    if not shopId or not vehicleId then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    if not ShopCreator.HasShopPermission(source, shopId, 'use_garage') then
        return { ok = false, error = ShopCreator.L('no_permission') }
    end

    if getActive(source) then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    local shop = ShopCreator.Cache.shops[shopId]
    if not shop then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    local vehicleDef
    for i = 1, #(shop.vehicles or {}) do
        local veh = shop.vehicles[i]
        if veh.id == vehicleId and veh.enabled then
            vehicleDef = veh
            break
        end
    end

    if not vehicleDef then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    local spawnLoc = getShopLocation(shop, ShopCreator.LocationTypes.vehicle_spawn)
        or getShopLocation(shop, ShopCreator.LocationTypes.garage)

    if not spawnLoc then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    ShopCreator.Garage.active[source] = {
        shopId = shopId,
        vehicleId = vehicleId,
        model = vehicleDef.model,
        label = vehicleDef.label,
        spawnedAt = os.time(),
    }

    ShopCreator.Log('vehicle_taken', {
        shopId = shopId,
        vehicleId = vehicleId,
        model = vehicleDef.model,
        citizenid = ShopCreator.GetCitizenId(source),
    })

    ShopCreator.Notify(source, ShopCreator.L('vehicle_spawned'), 'success')

    return {
        ok = true,
        data = {
            model = vehicleDef.model,
            label = vehicleDef.label,
            coords = {
                x = spawnLoc.x,
                y = spawnLoc.y,
                z = spawnLoc.z,
                w = spawnLoc.w or 0,
            },
        },
    }
end

---@param source number
---@param shopId number
---@param netId number|nil
---@return table
function ShopCreator.StoreVehicle(source, shopId, netId)
    shopId = tonumber(shopId)
    local active = getActive(source)

    if not active or active.shopId ~= shopId then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    if not ShopCreator.HasShopPermission(source, shopId, 'use_garage') then
        return { ok = false, error = ShopCreator.L('no_permission') }
    end

    clearActive(source)

    ShopCreator.Log('vehicle_stored', {
        shopId = shopId,
        vehicleId = active.vehicleId,
        netId = netId,
        citizenid = ShopCreator.GetCitizenId(source),
    })

    ShopCreator.Notify(source, ShopCreator.L('vehicle_stored'), 'success')
    return { ok = true, data = { vehicleId = active.vehicleId } }
end

---@param source number
---@return boolean
function ShopCreator.HasActiveVehicle(source)
    return getActive(source) ~= nil
end
