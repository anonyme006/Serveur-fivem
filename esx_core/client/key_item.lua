--- Utilisation de l'item clé (ox_inventory client export)

local function useKeyFromMetadata(metadata)
    if type(metadata) ~= 'table' then
        return Core.Notify(Core.Locale('key_no_key'), 'error')
    end

    local plate = Core.NormalizePlate(metadata.plate or metadata.Plate or '')
    if plate == '' then
        return Core.Notify(Core.Locale('key_no_key'), 'error')
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        veh = GetClosestVehicle(coords.x, coords.y, coords.z, Config.Keys.lockDistance or 6.0, 0, 70)
    end

    if veh == 0 or not DoesEntityExist(veh) then
        return Core.Notify(Core.Locale('key_no_vehicle'), 'error')
    end

    local vehPlate = Core.NormalizePlate(GetVehicleNumberPlateText(veh))
    if vehPlate ~= plate then
        return Core.Notify(Core.Locale('key_wrong_vehicle', plate), 'error')
    end

    ExecuteCommand(Config.Keys.lockCommand or 'vehiclelock')
end

--- ox_inventory : client = { export = 'esx_core.useVehicleKey' }
exports('useVehicleKey', function(data, slotData)
    local meta = (slotData and slotData.metadata) or (data and data.metadata) or data or {}
    useKeyFromMetadata(meta)
end)
