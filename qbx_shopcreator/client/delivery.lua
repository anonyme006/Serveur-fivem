Client = Client or {}
Client.delivery = Client.delivery or nil

local function L(key)
    local locale = Locales[Config.Locale] or Locales.fr or {}
    return locale[key] or key
end

---@param blip number|nil
local function removeBlip(blip)
    if blip and DoesBlipExist(blip) then
        RemoveBlip(blip)
    end
end

---@param coords table|vector3
---@param sprite number
---@param colour number
---@param label string
---@return number
local function createRouteBlip(coords, sprite, colour, label)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, colour)
    SetBlipScale(blip, 0.9)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, colour)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(label)
    EndTextCommandSetBlipName(blip)
    return blip
end

---@param vehicle number
local function deleteDeliveryVehicle(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return end
    SetEntityAsMissionEntity(vehicle, true, true)
    DeleteVehicle(vehicle)
end

function Client.StopDelivery(manual)
    local active = Client.delivery
    if not active then return end

    if active.pickupBlip then
        removeBlip(active.pickupBlip)
    end
    if active.dropoffBlip then
        removeBlip(active.dropoffBlip)
    end

    if active.pickupPoint and active.pickupPoint.remove then
        active.pickupPoint:remove()
    end
    if active.dropoffPoint and active.dropoffPoint.remove then
        active.dropoffPoint:remove()
    end

    if active.vehicle then
        deleteDeliveryVehicle(active.vehicle)
    end

    Client.delivery = nil

    if not manual then
        Client.Notify(L('delivery_failed'), 'error')
    end
end

---@param mission table
---@param prefix string
local function vecFrom(mission, prefix)
    local point = mission[prefix]
    if type(point) == 'table' and point.x then
        return vec3(point.x, point.y, point.z)
    end

    return vec3(
        mission[('%s_x'):format(prefix)],
        mission[('%s_y'):format(prefix)],
        mission[('%s_z'):format(prefix)]
    )
end

---@param mission table
local function normalizeMission(mission)
    if mission.pickup and not mission.pickup_x then
        mission.pickup_x = mission.pickup.x
        mission.pickup_y = mission.pickup.y
        mission.pickup_z = mission.pickup.z
    end
    if mission.dropoff and not mission.dropoff_x then
        mission.dropoff_x = mission.dropoff.x
        mission.dropoff_y = mission.dropoff.y
        mission.dropoff_z = mission.dropoff.z
    end
    return mission
end

---@param shopId number
---@param model? string
local function spawnDeliveryVehicle(shopId, model)
    local shop = Client.GetShop(shopId)
    local spawnLoc

    if shop then
        spawnLoc = Client.GetShopLocation(shop, ShopCreator.LocationTypes.vehicle_spawn)
            or Client.GetShopLocation(shop, ShopCreator.LocationTypes.garage)
    end

    if not spawnLoc then
        local default = Config.Delivery.defaultPickup
        spawnLoc = { x = default.x, y = default.y, z = default.z, w = default.w }
    end

    model = model or Config.Delivery.vehicleModel or 'boxville2'
    local hash = joaat(model)
    if not IsModelInCdimage(hash) then return nil end

    RequestModel(hash)
    local timeout = GetGameTimer() + 10000
    while not HasModelLoaded(hash) do
        if GetGameTimer() > timeout then return nil end
        Wait(0)
    end

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

    if not DoesEntityExist(vehicle) then return nil end

    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleEngineOn(vehicle, true, true, false)

    local ped = cache.ped or PlayerPedId()
    TaskWarpPedIntoVehicle(ped, vehicle, -1)

    return vehicle
end

---@param mission table
local function beginDropoffPhase(mission)
    local active = Client.delivery
    if not active then return end

    active.phase = 'dropoff'

    if active.pickupBlip then
        removeBlip(active.pickupBlip)
        active.pickupBlip = nil
    end
    if active.pickupPoint and active.pickupPoint.remove then
        active.pickupPoint:remove()
        active.pickupPoint = nil
    end

    local dropCoords = vecFrom(mission, 'dropoff')
    active.dropoffBlip = createRouteBlip(dropCoords, 478, 2, mission.dest_label or 'Livraison')

    active.dropoffPoint = lib.points.new({
        coords = dropCoords,
        distance = Config.Delivery.dropoffRadius or 4.0,
        onEnter = function()
            lib.showTextUI('[E] Terminer la livraison')
        end,
        onExit = function()
            lib.hideTextUI()
        end,
        nearby = function()
            if IsControlJustReleased(0, 38) then
                local ok, result = pcall(function()
                    return lib.callback.await('qbx_shopcreator:completeDelivery', false, {
                        jobId = mission.job_id or mission.id,
                        id = mission.job_id or mission.id,
                        phase = 'dropoff',
                    })
                end)

                if ok and result and (result.ok == true or result == true) then
                    Client.Notify(L('delivery_completed'), 'success')
                    Client.StopDelivery(true)
                else
                    local err = result and (result.error or result.message) or L('delivery_failed')
                    Client.Notify(err, 'error')
                end
            end
        end,
    })
end

---@param mission table
local function beginPickupPhase(mission)
    mission = normalizeMission(mission)
    Client.StopDelivery(true)

    local pickupCoords = vecFrom(mission, 'pickup')
    if not pickupCoords.x or not pickupCoords.y or not pickupCoords.z then
        local default = Config.Delivery.defaultPickup
        pickupCoords = vec3(default.x, default.y, default.z)
        mission.pickup_x = default.x
        mission.pickup_y = default.y
        mission.pickup_z = default.z
    end

    local method = mission.method or mission.delivery_method or ShopCreator.DeliveryMethods.self
    local vehicle = nil

    if method == ShopCreator.DeliveryMethods.self or mission.spawn_vehicle then
        vehicle = spawnDeliveryVehicle(mission.shop_id, mission.vehicle_model)
    end

    Client.delivery = {
        mission = mission,
        phase = 'pickup',
        vehicle = vehicle,
        pickupBlip = createRouteBlip(pickupCoords, 478, 5, mission.origin_label or 'Collecte'),
        dropoffBlip = nil,
        pickupPoint = nil,
        dropoffPoint = nil,
    }

    local pickupRadius = Config.Delivery.pickupRadius or 4.0

    Client.delivery.pickupPoint = lib.points.new({
        coords = pickupCoords,
        distance = pickupRadius,
        onEnter = function()
            lib.showTextUI('[E] Collecter la marchandise')
        end,
        onExit = function()
            lib.hideTextUI()
        end,
        nearby = function()
            if IsControlJustReleased(0, 38) then
                local ok, result = pcall(function()
                    return lib.callback.await('qbx_shopcreator:completeDelivery', false, {
                        jobId = mission.job_id or mission.id,
                        id = mission.job_id or mission.id,
                        phase = 'pickup',
                    })
                end)

                if not ok or not result or result == false or (type(result) == 'table' and result.ok == false) then
                    local err = type(result) == 'table' and (result.error or result.message) or L('delivery_failed')
                    Client.Notify(err, 'error')
                    return
                end

                beginDropoffPhase(mission)
            end
        end,
    })

    Client.Notify(L('delivery_accepted'), 'success')
end

---@param mission table
function Client.StartDelivery(mission)
    if not mission then return end
    beginPickupPhase(mission)
end

RegisterNetEvent('qbx_shopcreator:client:startDelivery', function(mission)
    Client.StartDelivery(mission)
end)

RegisterNetEvent('qbx_shopcreator:client:stopDelivery', function()
    Client.StopDelivery(true)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= ShopCreator.Resource then return end
    Client.StopDelivery(true)
end)

exports('StartDelivery', Client.StartDelivery)
exports('StopDelivery', Client.StopDelivery)
