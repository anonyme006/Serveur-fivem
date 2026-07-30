RegisterNetEvent('esx_core:notify', function(msg, nType)
    Core.Notify(msg, nType)
end)

local lastFuelAlert = 0
local lastHungerAlert = 0
local lastThirstAlert = 0

local hungerPct = 100
local thirstPct = 100

--- Normalise esx_status (souvent 0–1000000) en %
local function statusToPercent(val)
    val = tonumber(val) or 0
    if val > 100 then
        return Core.Percent(val, 1000000)
    end
    return math.floor(val + 0.5)
end

CreateThread(function()
    while true do
        Wait(2000)

        if Config.Alerts.needs.enabled and GetResourceState('esx_status') == 'started' then
            local hungerName = Config.Alerts.needs.hunger or 'hunger'
            local thirstName = Config.Alerts.needs.thirst or 'thirst'

            TriggerEvent('esx_status:getStatus', hungerName, function(status)
                if status and status.val then
                    hungerPct = statusToPercent(status.val)
                end
            end)

            TriggerEvent('esx_status:getStatus', thirstName, function(status)
                if status and status.val then
                    thirstPct = statusToPercent(status.val)
                end
            end)

            local now = GetGameTimer()

            if hungerPct <= (Config.Alerts.needs.hungerThreshold or 20)
                and now - lastHungerAlert > (Config.Alerts.needs.cooldown or 120000) then
                lastHungerAlert = now
                Core.Notify(Core.Locale('alert_hunger', hungerPct), 'warning')
            end

            if thirstPct <= (Config.Alerts.needs.thirstThreshold or 20)
                and now - lastThirstAlert > (Config.Alerts.needs.cooldown or 120000) then
                lastThirstAlert = now
                Core.Notify(Core.Locale('alert_thirst', thirstPct), 'warning')
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(3000)
        if not Config.Alerts.fuel.enabled then
            Wait(5000)
            goto continue
        end

        local ped = PlayerPedId()
        if not IsPedInAnyVehicle(ped, false) then
            goto continue
        end

        local veh = GetVehiclePedIsIn(ped, false)
        if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then
            goto continue
        end

        local fuel = Core.GetFuelLevel(veh)
        local pct = math.floor(tonumber(fuel) or 100)
        if pct > 100 then pct = Core.Percent(pct, 100.0) end

        local now = GetGameTimer()
        if pct <= (Config.Alerts.fuel.threshold or 15)
            and now - lastFuelAlert > (Config.Alerts.fuel.cooldown or 90000) then
            lastFuelAlert = now
            Core.Notify(Core.Locale('alert_fuel', pct), 'error')
        end

        ::continue::
    end
end)
