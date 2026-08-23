local visible = Config.Enabled

local function nui(action, data)
    SendNUIMessage({ action = action, data = data, show = data, name = data })
end

local function setVisible(state)
    visible = state and Config.Enabled
    SendNUIMessage({ action = 'toggle', show = visible })
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    SendNUIMessage({ action = 'brand', name = Config.Brand })
    setVisible(true)
end)

RegisterNetEvent('qbx_core:client:playerLoggedOut', function()
    setVisible(false)
end)

CreateThread(function()
    Wait(800)
    SendNUIMessage({ action = 'brand', name = Config.Brand })
    if LocalPlayer.state.isLoggedIn then
        setVisible(true)
    end
end)

CreateThread(function()
    while true do
        if visible and LocalPlayer.state.isLoggedIn then
            local ped = cache.ped or PlayerPedId()
            local health = math.max(0, GetEntityHealth(ped) - 100)
            local payload = {
                health = health,
                armor = GetPedArmour(ped),
                talking = NetworkIsPlayerTalking(PlayerId()),
                vehicle = false,
            }

            if Config.ShowVehicle and cache.vehicle then
                local veh = cache.vehicle
                payload.vehicle = true
                payload.speed = math.floor(GetEntitySpeed(veh) * 3.6)
                payload.fuel = Entity(veh).state.fuel or GetVehicleFuelLevel(veh)
            end

            if Config.ShowLocation then
                local c = GetEntityCoords(ped)
                local a, b = GetStreetNameAtCoord(c.x, c.y, c.z)
                local street = GetStreetNameFromHashKey(a)
                if b ~= 0 then
                    street = street .. ' · ' .. GetStreetNameFromHashKey(b)
                end
                payload.street = street
            end

            SendNUIMessage({ action = 'update', data = payload })
            Wait(Config.RefreshMs)
        else
            Wait(1200)
        end
    end
end)

CreateThread(function()
    while true do
        if visible and LocalPlayer.state.isLoggedIn and Config.ShowNeeds then
            local pd = exports.qbx_core:GetPlayerData()
            if pd and pd.metadata then
                SendNUIMessage({
                    action = 'needs',
                    data = {
                        hunger = pd.metadata.hunger or 100,
                        thirst = pd.metadata.thirst or 100,
                        stress = pd.metadata.stress or 0,
                        showStress = Config.ShowStress,
                    }
                })
            end
            Wait(Config.NeedsRefreshMs)
        else
            Wait(2000)
        end
    end
end)

CreateThread(function()
    local wasPause = false
    while true do
        if Config.HideWhenPaused then
            local pause = IsPauseMenuActive()
            if pause ~= wasPause then
                if pause then
                    SendNUIMessage({ action = 'toggle', show = false })
                elseif visible then
                    SendNUIMessage({ action = 'toggle', show = true })
                end
                wasPause = pause
            end
        end
        Wait(400)
    end
end)

RegisterCommand('hud', function()
    setVisible(not visible)
end, false)

exports('SetHudVisible', setVisible)
