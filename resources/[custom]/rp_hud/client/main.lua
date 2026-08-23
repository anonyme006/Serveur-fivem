local visible = Config.Enabled
local lastVehicle = false

local function setHud(data)
    if not visible then return end
    SendNUIMessage({ action = 'update', data = data })
end

local function hideHud()
    SendNUIMessage({ action = 'toggle', show = false })
end

local function showHud()
    if not Config.Enabled then return end
    SendNUIMessage({ action = 'toggle', show = true })
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    visible = Config.Enabled
    showHud()
end)

RegisterNetEvent('qbx_core:client:playerLoggedOut', function()
    visible = false
    hideHud()
end)

-- Stats vie / armure / stamina via event frame throttlé
CreateThread(function()
    while true do
        if visible and LocalPlayer.state.isLoggedIn then
            local ped = cache.ped or PlayerPedId()
            local data = {
                health = math.max(0, GetEntityHealth(ped) - 100),
                armor = GetPedArmour(ped),
                stamina = math.floor(100 - GetPlayerSprintStaminaRemaining(PlayerId())),
                talking = NetworkIsPlayerTalking(PlayerId()),
            }
            if Config.ShowVehicle and cache.vehicle then
                local veh = cache.vehicle
                data.vehicle = true
                data.speed = math.floor(GetEntitySpeed(veh) * 3.6)
                data.fuel = Entity(veh).state.fuel or GetVehicleFuelLevel(veh)
                lastVehicle = true
            else
                data.vehicle = false
                lastVehicle = false
            end
            if Config.ShowLocation then
                local coords = GetEntityCoords(ped)
                local s1, s2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
                data.street = GetStreetNameFromHashKey(s1)
                if s2 ~= 0 then
                    data.street = data.street .. ' / ' .. GetStreetNameFromHashKey(s2)
                end
            end
            setHud(data)
            Wait(Config.RefreshMs)
        else
            Wait(1000)
        end
    end
end)

-- Needs via metadata (event-driven + soft poll)
CreateThread(function()
    while true do
        if visible and LocalPlayer.state.isLoggedIn and Config.Needs then
            local pd = exports.qbx_core:GetPlayerData()
            if pd and pd.metadata then
                SendNUIMessage({
                    action = 'needs',
                    data = {
                        hunger = pd.metadata.hunger or 100,
                        thirst = pd.metadata.thirst or 100,
                        stress = pd.metadata.stress or 0,
                        cash = Config.ShowMoney and pd.money and pd.money.cash or nil,
                        bank = Config.ShowMoney and pd.money and pd.money.bank or nil,
                    }
                })
            end
            Wait(Config.NeedsRefreshMs)
        else
            Wait(2000)
        end
    end
end)

RegisterCommand('hud', function()
    visible = not visible
    SendNUIMessage({ action = 'toggle', show = visible })
end, false)

-- Pause menu hide
CreateThread(function()
    local wasPause = false
    while true do
        local pause = IsPauseMenuActive()
        if pause and not wasPause then
            hideHud()
        elseif not pause and wasPause and visible then
            showHud()
        end
        wasPause = pause
        Wait(500)
    end
end)
