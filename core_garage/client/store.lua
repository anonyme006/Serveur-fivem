--[[--------------------------------------------------------------------------
    core_garage — rangement via ox_target (sans être assis)
---------------------------------------------------------------------------]]

--- Native GetIsVehicleEngineRunning
local function isEngineRunning(vehicle)
    return Citizen.InvokeNative(0xAE31E7DF9B5B132E, vehicle) == 1
        or Citizen.InvokeNative(0xAE31E7DF9B5B132E, vehicle) == true
end

local function storeVehicle(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return end

    local plate = GarageUtils.NormalizePlate(GetVehicleNumberPlateText(entity))
    local netId = NetworkGetNetworkIdFromEntity(entity)

    local garage = CoreGarage.GetNearestStoreGarage()
    if not garage then
        CoreGarage.Notify(_('too_far'), 'error')
        return
    end

    local can = lib.callback.await('core_garage:canStore', false, netId, garage.name)
    if not can or not can.ok then
        CoreGarage.Notify(_(can and can.error or 'error'), 'error')
        return
    end

    if Config.General.requireEngineOff and isEngineRunning(entity) then
        CoreGarage.Notify(_('engine_must_be_off'), 'error')
        return
    end

    local ped = PlayerPedId()
    -- Ne pas obliger d'être assis — sort du véhicule si dedans
    if IsPedInVehicle(ped, entity, false) then
        TaskLeaveVehicle(ped, entity, 0)
        local timeout = GetGameTimer() + 3000
        while IsPedInVehicle(ped, entity, false) and GetGameTimer() < timeout do
            Wait(50)
        end
    end

    local cfg = Config.Progress.store
    local success = lib.progressCircle({
        duration = cfg.duration or 4000,
        label = _('progress_store'),
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = cfg.disable or { move = true, car = true, combat = true },
        anim = cfg.anim and { dict = cfg.anim.dict, clip = cfg.anim.clip } or nil,
    })

    if not success then
        CoreGarage.Notify(_('cancelled'), 'inform')
        return
    end

    if not DoesEntityExist(entity) then
        CoreGarage.Notify(_('vehicle_not_found'), 'error')
        return
    end

    local props = CoreGarage.GetVehicleProperties(entity)
    local result = lib.callback.await('core_garage:storeVehicle', false, {
        plate = plate,
        netId = netId,
        garage = garage.name,
        props = props,
        engineOff = not isEngineRunning(entity),
    })

    if not result or not result.ok then
        CoreGarage.Notify(_(result and result.error or 'error'), 'error')
        return
    end

    CoreGarage.mileageCache[plate] = nil
    CoreGarage.Notify(_('vehicle_stored'), 'success')
end

CreateThread(function()
    exports.ox_target:addGlobalVehicle({
        {
            name = 'core_garage_store',
            icon = 'fa-solid fa-warehouse',
            label = _('store_target'),
            distance = Config.General.storeTargetDistance or 3.5,
            canInteract = function(entity)
                if not entity or entity == 0 then return false end
                local managed = Entity(entity).state['garageManaged']
                    or Entity(entity).state[Config.General.plateStatebag]
                if managed then return true end
                return CoreGarage.GetNearestStoreGarage() ~= nil
            end,
            onSelect = function(data)
                storeVehicle(data.entity)
            end,
        },
    })
end)

exports('StoreVehicle', storeVehicle)
