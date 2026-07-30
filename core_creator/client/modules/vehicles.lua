RegisterNetEvent('core_creator:vehicles:spawn', function(payload)
    if type(payload) ~= 'table' then return end
    local hash = joaat(payload.model)
    RequestModel(hash)
    local t = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < t do Wait(10) end
    if not HasModelLoaded(hash) then return end

    local c = payload.coords
    local veh = CreateVehicle(hash, c.x, c.y, c.z, payload.heading or c.w or 0.0, true, false)
    SetVehicleNumberPlateText(veh, payload.plate or '')
    SetVehicleOnGroundProperly(veh)
    SetPedIntoVehicle(PlayerPedId(), veh, -1)

    if payload.props then
        if payload.props.color1 then
            SetVehicleColours(veh, payload.props.color1 or 0, payload.props.color2 or 0)
        end
    end
    SetModelAsNoLongerNeeded(hash)
end)

RegisterNetEvent('core_creator:vehicles:setLock', function(netId, plate, bySrc)
    if not netId then return end
    local ent = NetworkGetEntityFromNetworkId(netId)
    if ent and DoesEntityExist(ent) then
        local status = GetVehicleDoorLockStatus(ent)
        if status == 1 or status == 0 then
            SetVehicleDoorsLocked(ent, 2)
            if bySrc == GetPlayerServerId(PlayerId()) then
                Bridge.Notify(('Verrouillé (%s)'):format(plate or ''), 'inform')
            end
        else
            SetVehicleDoorsLocked(ent, 1)
            if bySrc == GetPlayerServerId(PlayerId()) then
                Bridge.Notify(('Déverrouillé (%s)'):format(plate or ''), 'inform')
            end
        end
    end
end)

RegisterCommand('cclock', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        veh = GetClosestVehicle(GetEntityCoords(ped), 5.0, 0, 70)
    end
    if veh == 0 then return end
    local plate = GetVehicleNumberPlateText(veh)
    TriggerServerEvent('core_creator:vehicles:toggleLock', plate, NetworkGetNetworkIdFromEntity(veh))
end, false)
