if not Config.Keys.enabled then return end

local function playLockAnim()
    if not Config.Keys.useAnim then return end
    local ped = PlayerPedId()
    local dict = 'anim@mp_player_intmenu@key_fob@'
    RequestAnimDict(dict)
    local t = GetGameTimer() + 2000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < t do Wait(10) end
    if HasAnimDictLoaded(dict) then
        TaskPlayAnim(ped, dict, 'fob_click', 8.0, -8.0, 800, 48, 0.0, false, false, false)
    end
end

local function getClosestVehicle(maxDist)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then return veh end

    veh = GetClosestVehicle(coords.x, coords.y, coords.z, maxDist or Config.Keys.lockDistance, 0, 70)
    if veh ~= 0 and DoesEntityExist(veh) then
        return veh
    end
    return 0
end

local function toggleLock()
    local veh = getClosestVehicle()
    if veh == 0 then
        return Core.Notify(Core.Locale('key_no_vehicle'), 'error')
    end

    local plate = Core.NormalizePlate(GetVehicleNumberPlateText(veh))
    local allowed = lib.callback.await('esx_core:keys:canLock', false, plate)
    if not allowed then
        return Core.Notify(Core.Locale('key_no_key'), 'error')
    end

    playLockAnim()

    local status = GetVehicleDoorLockStatus(veh)
    local locking = status == 1 or status == 0
    local netId = NetworkGetNetworkIdFromEntity(veh)
    TriggerServerEvent('esx_core:keys:setLock', netId, plate, locking)
end

RegisterNetEvent('esx_core:keys:applyLock', function(netId, locking, plate, bySrc)
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end

    SetVehicleDoorsLocked(veh, locking and 2 or 1)
    SetVehicleDoorsLockedForAllPlayers(veh, locking)

    if bySrc == GetPlayerServerId(PlayerId()) then
        Core.Notify(
            locking and Core.Locale('key_locked', plate) or Core.Locale('key_unlocked', plate),
            locking and 'inform' or 'success'
        )
        -- Flash lights
        SetVehicleLights(veh, 2)
        Wait(150)
        SetVehicleLights(veh, 0)
        Wait(150)
        SetVehicleLights(veh, 2)
        Wait(150)
        SetVehicleLights(veh, 0)
    end
end)

RegisterCommand(Config.Keys.lockCommand or 'vehiclelock', function()
    toggleLock()
end, false)

RegisterKeyMapping(
    Config.Keys.lockCommand or 'vehiclelock',
    'Verrouiller / déverrouiller véhicule',
    'keyboard',
    Config.Keys.lockKey or 'U'
)

--- Habitations : export pour scripts housing
--- houseId + coords porte
local houseDoors = {} -- id -> { coords, locked }

RegisterNetEvent('esx_core:keys:registerHouse', function(houseId, coords, locked)
    if not houseId or not coords then return end
    houseDoors[tostring(houseId)] = {
        coords = vec3(coords.x, coords.y, coords.z),
        locked = locked ~= false,
    }
end)

RegisterNetEvent('esx_core:keys:setHouseLock', function(houseId, locked)
    local door = houseDoors[tostring(houseId)]
    if door then door.locked = locked and true or false end
end)

exports('ToggleVehicleLock', toggleLock)

exports('IsHouseLocked', function(houseId)
    local door = houseDoors[tostring(houseId)]
    return door and door.locked or false
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local pcoords = GetEntityCoords(ped)

        for houseId, door in pairs(houseDoors) do
            local dist = #(pcoords - door.coords)
            if dist < (Config.Keys.houseDistance or 2.5) + 8.0 then
                sleep = 0
                if dist < (Config.Keys.houseDistance or 2.5) then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName(door.locked and '~INPUT_CONTEXT~ Déverrouiller' or '~INPUT_CONTEXT~ Verrouiller')
                    EndTextCommandDisplayHelp(0, false, true, -1)

                    if IsControlJustReleased(0, 38) then -- E
                        local ok = lib.callback.await('esx_core:keys:canHouse', false, houseId)
                        if not ok then
                            Core.Notify(Core.Locale('key_house_no_key'), 'error')
                        else
                            TriggerServerEvent('esx_core:keys:toggleHouse', houseId, not door.locked)
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)
