if Config.Modules and Config.Modules.core == false then return end

RegisterNetEvent('qbx_ressources:notify', function(msg, nType)
    Core.Notify(msg, nType)
end)

local lastFuelAlert = 0
local lastHungerAlert = 0
local lastThirstAlert = 0

local function readNeedsPercent()
    local hunger, thirst = 100, 100
    local hungerKey = (Config.Alerts.needs and Config.Alerts.needs.hunger) or 'hunger'
    local thirstKey = (Config.Alerts.needs and Config.Alerts.needs.thirst) or 'thirst'

    local meta
    local ok, pd = pcall(function()
        return exports.qbx_core:GetPlayerData()
    end)
    if ok and pd and pd.metadata then
        meta = pd.metadata
    elseif LocalPlayer and LocalPlayer.state and LocalPlayer.state.metadata then
        meta = LocalPlayer.state.metadata
    elseif LocalPlayer and LocalPlayer.state and LocalPlayer.state.PlayerData and LocalPlayer.state.PlayerData.metadata then
        meta = LocalPlayer.state.PlayerData.metadata
    end

    if meta then
        hunger = math.floor(tonumber(meta[hungerKey]) or 100)
        thirst = math.floor(tonumber(meta[thirstKey]) or 100)
    end

    if hunger > 100 then hunger = Core.Percent(hunger, 100) end
    if thirst > 100 then thirst = Core.Percent(thirst, 100) end
    if hunger < 0 then hunger = 0 end
    if thirst < 0 then thirst = 0 end
    return hunger, thirst
end

CreateThread(function()
    while true do
        Wait(2000)

        if not Config.Alerts or not Config.Alerts.needs or not Config.Alerts.needs.enabled then
            goto continue
        end

        local hungerPct, thirstPct = readNeedsPercent()
        local now = GetGameTimer()
        local cooldown = Config.Alerts.needs.cooldown or 120000

        if hungerPct <= (Config.Alerts.needs.hungerThreshold or 20)
            and now - lastHungerAlert > cooldown then
            lastHungerAlert = now
            Core.Notify(Core.Locale('alert_hunger', hungerPct), 'warning')
        end

        if thirstPct <= (Config.Alerts.needs.thirstThreshold or 20)
            and now - lastThirstAlert > cooldown then
            lastThirstAlert = now
            Core.Notify(Core.Locale('alert_thirst', thirstPct), 'warning')
        end

        ::continue::
    end
end)

CreateThread(function()
    while true do
        Wait(3000)
        if not Config.Alerts or not Config.Alerts.fuel or not Config.Alerts.fuel.enabled then
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
