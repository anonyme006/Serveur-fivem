Client = Client or {}

local function L(key)
    local locale = Locales[Config.Locale] or Locales.fr or {}
    return locale[key] or key
end

---@param vehicle number
local function deleteVehicleEntity(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return end
    local ped = cache.ped or PlayerPedId()
    if GetVehiclePedIsIn(ped, false) == vehicle then
        TaskLeaveVehicle(ped, vehicle, 16)
        Wait(500)
    end
    SetEntityAsMissionEntity(vehicle, true, true)
    DeleteVehicle(vehicle)
end

function Client.CleanupBusinessVehicle()
    if Client.businessVehicle then
        deleteVehicleEntity(Client.businessVehicle)
        Client.businessVehicle = nil
    end
end

---@param shopId number
---@param model? string
---@param coords? table
local function spawnBusinessVehicle(shopId, model, coords)
    local shop = Client.GetShop(shopId)
    if not shop and not coords then
        Client.Notify(L('invalid_data'), 'error')
        return
    end

    local spawnLoc = coords
    if not spawnLoc and shop then
        spawnLoc = Client.GetShopLocation(shop, ShopCreator.LocationTypes.vehicle_spawn)
        if not spawnLoc then
            spawnLoc = Client.GetShopLocation(shop, ShopCreator.LocationTypes.garage)
        end
    end

    if not spawnLoc then
        Client.Notify(L('invalid_data'), 'error')
        return
    end

    model = model or Config.Delivery.vehicleModel or 'boxville2'
    if not coords and shop and shop.vehicles and shop.vehicles[1] and shop.vehicles[1].enabled then
        model = shop.vehicles[1].model or model
    end

    local hash = joaat(model)
    if not IsModelInCdimage(hash) then
        Client.Notify(L('invalid_data'), 'error')
        return
    end

    RequestModel(hash)
    local timeout = GetGameTimer() + 10000
    while not HasModelLoaded(hash) do
        if GetGameTimer() > timeout then
            Client.Notify(L('invalid_data'), 'error')
            return
        end
        Wait(0)
    end

    Client.CleanupBusinessVehicle()

    local vehicle = CreateVehicle(
        hash,
        spawnLoc.x,
        spawnLoc.y,
        spawnLoc.z,
        spawnLoc.w or 0.0,
        true,
        false
    )
    SetModelAsNoLongerNeeded(hash)

    if not DoesEntityExist(vehicle) then
        Client.Notify(L('invalid_data'), 'error')
        return
    end

    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleNumberPlateText(vehicle, ('SHOP%s'):format(shopId):sub(1, 8))

    local ped = cache.ped or PlayerPedId()
    TaskWarpPedIntoVehicle(ped, vehicle, -1)

    Client.businessVehicle = vehicle
    Entity(vehicle).state:set('shopcreator_shop_id', shopId, true)
end

---@param shopId number
---@param model? string
local function takeOutVehicle(shopId, model)
    shopId = tonumber(shopId)
    if not shopId then return end

    local ok, result = pcall(function()
        return lib.callback.await('qbx_shopcreator:takeVehicle', false, {
            shopId = shopId,
            model = model,
            vehicleId = tonumber(model) -- ignored unless numeric id passed as model
        })
    end)

    if not ok or result == false or (type(result) == 'table' and result.ok == false) then
        local err = type(result) == 'table' and (result.error or result.message) or L('no_permission')
        Client.Notify(err, 'error')
        return
    end

    local payload = type(result) == 'table' and (result.data or result) or {}
    local spawnModel = payload.model or model
    local coords = payload.coords

    spawnBusinessVehicle(shopId, spawnModel, coords)
    Client.Notify(L('vehicle_spawned'), 'success')
end

---@param shopId number
local function storeVehicle(shopId)
    shopId = tonumber(shopId)
    if not shopId then return end

    local shop = Client.GetShop(shopId)
    if not shop then
        Client.Notify(L('invalid_data'), 'error')
        return
    end

    local returnLoc = Client.GetShopLocation(shop, ShopCreator.LocationTypes.vehicle_return)
    if not returnLoc then
        Client.Notify(L('invalid_data'), 'error')
        return
    end

    local ped = cache.ped or PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        vehicle = Client.businessVehicle
    end

    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        Client.Notify(L('invalid_data'), 'error')
        return
    end

    local vehCoords = GetEntityCoords(vehicle)
    local dist = ShopCreator.Distance(vehCoords, returnLoc)
    if dist > (Config.Garage.returnRadius or 6.0) then
        Client.Notify(L('invalid_data'), 'error')
        return
    end

    local ok, result = pcall(function()
        return lib.callback.await('qbx_shopcreator:storeVehicle', false, {
            shopId = shopId,
            netId = VehToNet(vehicle),
        })
    end)

    if not ok or result == false or (type(result) == 'table' and result.ok == false) then
        local err = type(result) == 'table' and (result.error or result.message) or L('no_permission')
        Client.Notify(err, 'error')
        return
    end

    deleteVehicleEntity(vehicle)
    if Client.businessVehicle == vehicle then
        Client.businessVehicle = nil
    end

    Client.Notify(L('vehicle_stored'), 'success')
end

RegisterNetEvent('qbx_shopcreator:client:garage:open', function(shopId, model)
    takeOutVehicle(shopId, model)
end)

RegisterNetEvent('qbx_shopcreator:client:garage:return', function(shopId)
    storeVehicle(shopId)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= ShopCreator.Resource then return end
    Client.CleanupBusinessVehicle()
end)

exports('TakeOutBusinessVehicle', takeOutVehicle)
exports('StoreBusinessVehicle', storeVehicle)
