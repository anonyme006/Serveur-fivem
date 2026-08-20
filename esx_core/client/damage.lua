if not Config.Damage.enabled then return end

local lastBody = 1000.0
local lastEngine = 1000.0
local tracking = 0

local function trackVehicle(veh)
    if veh == 0 then
        tracking = 0
        return
    end
    tracking = veh
    lastBody = GetVehicleBodyHealth(veh)
    lastEngine = GetVehicleEngineHealth(veh)
end

CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            if GetPedInVehicleSeat(veh, -1) == ped then
                sleep = 100

                if tracking ~= veh then
                    trackVehicle(veh)
                end

                local body = GetVehicleBodyHealth(veh)
                local engine = GetVehicleEngineHealth(veh)
                local speed = GetEntitySpeed(veh) * 3.6

                local bodyDelta = lastBody - body
                local engineDelta = lastEngine - engine

                -- Choc significatif
                if speed >= (Config.Damage.minSpeed or 35.0) and (bodyDelta > 8.0 or engineDelta > 8.0) then
                    local newEngine = math.max(0.0, engine - engineDelta * ((Config.Damage.engineMultiplier or 1.15) - 1.0))
                    local newBody = math.max(0.0, body - bodyDelta * ((Config.Damage.bodyMultiplier or 1.10) - 1.0))

                    SetVehicleEngineHealth(veh, newEngine)
                    SetVehicleBodyHealth(veh, newBody)

                    if Config.Damage.notify and (bodyDelta > 25 or engineDelta > 25) then
                        Core.Notify(Core.Locale('accident_damage'), 'warning')
                    end

                    if newBody < (Config.Damage.stallBodyThreshold or 450.0)
                        and math.random(1, 100) <= (Config.Damage.stallChance or 35) then
                        SetVehicleEngineOn(veh, false, true, true)
                        SetVehicleUndriveable(veh, true)
                        Core.Notify(Core.Locale('accident_stall'), 'error')
                        SetTimeout(4000, function()
                            if DoesEntityExist(veh) then
                                SetVehicleUndriveable(veh, false)
                            end
                        end)
                    end

                    -- Persistance immédiate après gros choc
                    if Config.Persistence.enabled then
                        local plate = Core.NormalizePlate(GetVehicleNumberPlateText(veh))
                        local props = {
                            engineHealth = GetVehicleEngineHealth(veh),
                            bodyHealth = GetVehicleBodyHealth(veh),
                            tankHealth = GetVehiclePetrolTankHealth(veh),
                            fuelLevel = Core.GetFuelLevel(veh),
                            dirtLevel = GetVehicleDirtLevel(veh),
                        }
                        -- déformations portes / pneus basiques
                        props.doors = {}
                        for i = 0, 5 do
                            props.doors[i] = IsVehicleDoorDamaged(veh, i)
                        end
                        props.tyres = {}
                        for i = 0, 7 do
                            props.tyres[i] = IsVehicleTyreBurst(veh, i, false)
                        end
                        TriggerServerEvent('esx_core:persistDamage', plate, props)
                    end
                end

                lastBody = GetVehicleBodyHealth(veh)
                lastEngine = GetVehicleEngineHealth(veh)
            else
                tracking = 0
            end
        else
            tracking = 0
        end

        Wait(sleep)
    end
end)
