local ESX = nil

local hunger = 100
local thirst = 100
local isLoggedIn = false
local vehicleHudVisible = false

local function initESX()
    if GetResourceState('es_extended') ~= 'started' then
        return false
    end

    local ok, obj = pcall(function()
        return exports['es_extended']:getSharedObject()
    end)

    if ok and obj then
        ESX = obj
        return true
    end

    -- Fallback ancien ESX
    TriggerEvent('esx:getSharedObject', function(obj)
        ESX = obj
    end)

    local timeout = GetGameTimer() + 5000
    while not ESX and GetGameTimer() < timeout do
        Wait(100)
    end

    return ESX ~= nil
end

local function setHudVisible(visible)
    SendNUIMessage({
        action = 'setVisible',
        visible = visible,
        statusBottom = Config.StatusPosition.bottom,
        statusLeft = Config.StatusPosition.left,
        vehicleBottom = Config.VehiclePosition.bottom,
    })
end

local function hideDefaultHudComponents()
    -- Santé, armure, argent, véhicule natif, etc.
    HideHudComponentThisFrame(1)  -- Wanted stars
    HideHudComponentThisFrame(2)  -- Weapon icon
    HideHudComponentThisFrame(3)  -- Cash
    HideHudComponentThisFrame(4)  -- MP cash
    HideHudComponentThisFrame(6)  -- Vehicle name
    HideHudComponentThisFrame(7)  -- Area name
    HideHudComponentThisFrame(8)  -- Vehicle class
    HideHudComponentThisFrame(9)  -- Street name
    DisplayRadar(not Config.HideRadar)
end

-- Remonte la minimap pour dégager l'espace des barres status en dessous
local function applyMinimapOffset()
    if not Config.OffsetMinimap then
        return
    end

    local offsetY = Config.MinimapOffsetY or 0.028

    -- Refresh scaleform puis reposition
    local defaultAspectRatio = 1920 / 1080
    local resolutionX, resolutionY = GetActiveScreenResolution()
    local aspectRatio = resolutionX / resolutionY
    local minimapOffset = 0.0

    if aspectRatio > defaultAspectRatio then
        minimapOffset = ((defaultAspectRatio - aspectRatio) / 3.6) - 0.008
    end

    RequestStreamedTextureDict('squaremap', false)
    SetMinimapClipType(0)

    SetMinimapComponentPosition('minimap', 'L', 'B', 0.0 + minimapOffset, 0.0 + offsetY, 0.1638, 0.183)
    SetMinimapComponentPosition('minimap_mask', 'L', 'B', 0.0 + minimapOffset, 0.0 + offsetY, 0.128, 0.20)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.01 + minimapOffset, 0.025 + offsetY, 0.262, 0.300)

    SetRadarBigmapEnabled(true, false)
    Wait(50)
    SetRadarBigmapEnabled(false, false)
end

local function getFuelLevel(vehicle)
    if GetResourceState('LegacyFuel') == 'started' then
        local ok, value = pcall(function()
            return exports['LegacyFuel']:GetFuel(vehicle)
        end)
        if ok and value then return value end
    end

    if GetResourceState('cdn-fuel') == 'started' then
        local ok, value = pcall(function()
            return exports['cdn-fuel']:GetFuel(vehicle)
        end)
        if ok and value then return value end
    end

    return GetVehicleFuelLevel(vehicle) or 0.0
end

local function getPlate(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle) or ''
    return plate:gsub('%s+', '')
end

local function getHealthPercent(ped)
    local health = GetEntityHealth(ped)
    local maxHealth = GetEntityMaxHealth(ped)

    if maxHealth > 100 then
        return math.max(0, math.min(100, ((health - 100) / (maxHealth - 100)) * 100))
    end

    return math.max(0, math.min(100, health))
end

local function sendStatus()
    local ped = PlayerPedId()

    SendNUIMessage({
        action = 'updateStatus',
        health = getHealthPercent(ped),
        armour = GetPedArmour(ped),
        hunger = hunger,
        thirst = thirst,
    })
end

local function sendVehicle(show, data)
    SendNUIMessage({
        action = 'updateVehicle',
        show = show,
        speed = data and data.speed or 0,
        rpm = data and data.rpm or 0,
        fuel = data and data.fuel or 0,
        engine = data and data.engine or 0,
        plate = data and data.plate or '',
        unit = Config.SpeedUnit,
    })
end

local function refreshHungerThirst()
    if GetResourceState('esx_status') ~= 'started' then
        return
    end

    TriggerEvent('esx_status:getStatus', Config.Status.hunger, function(status)
        if status and status.val then
            hunger = math.floor((status.val / 1000000) * 100 + 0.5)
        end
    end)

    TriggerEvent('esx_status:getStatus', Config.Status.thirst, function(status)
        if status and status.val then
            thirst = math.floor((status.val / 1000000) * 100 + 0.5)
        end
    end)
end

RegisterNetEvent('esx:playerLoaded', function()
    isLoggedIn = true
    setHudVisible(true)
    CreateThread(applyMinimapOffset)
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    isLoggedIn = false
    setHudVisible(false)
    sendVehicle(false)
    vehicleHudVisible = false
end)

-- Init
CreateThread(function()
    while not initESX() do
        Wait(500)
    end

    -- Déjà connecté (restart ressource)
    local timeout = GetGameTimer() + 10000
    while GetGameTimer() < timeout do
        if ESX.PlayerLoaded or (ESX.GetPlayerData and ESX.GetPlayerData().job) then
            isLoggedIn = true
            setHudVisible(true)
            applyMinimapOffset()
            break
        end
        Wait(200)
    end
end)

-- Faim / soif
CreateThread(function()
    while true do
        if isLoggedIn then
            refreshHungerThirst()
            Wait(500)
        else
            Wait(1000)
        end
    end
end)

-- Santé / status UI
CreateThread(function()
    while true do
        if isLoggedIn then
            sendStatus()
            Wait(Config.StatusUpdateMs)
        else
            Wait(500)
        end
    end
end)

-- Véhicule + masquage HUD natif
CreateThread(function()
    while true do
        if isLoggedIn then
            hideDefaultHudComponents()

            if Config.ShowVehicleHud then
                local ped = PlayerPedId()
                local vehicle = GetVehiclePedIsIn(ped, false)

                -- Affiché uniquement dans un véhicule (toute place)
                if vehicle ~= 0 then
                    local speedRaw = GetEntitySpeed(vehicle)
                    local speed = Config.SpeedUnit == 'mph'
                        and math.floor(speedRaw * 2.236936 + 0.5)
                        or math.floor(speedRaw * 3.6 + 0.5)

                    local rpm = GetVehicleCurrentRpm(vehicle)
                    local rpmPct = math.max(0, math.min(100, ((rpm - 0.2) / 0.8) * 100))
                    local enginePct = math.max(0, math.min(100, GetVehicleEngineHealth(vehicle) / 10))
                    local fuel = math.max(0, math.min(100, getFuelLevel(vehicle)))

                    sendVehicle(true, {
                        speed = speed,
                        rpm = rpmPct,
                        fuel = fuel,
                        engine = enginePct,
                        plate = getPlate(vehicle),
                    })
                    vehicleHudVisible = true
                    Wait(Config.VehicleUpdateMs)
                else
                    if vehicleHudVisible then
                        sendVehicle(false)
                        vehicleHudVisible = false
                    end
                    Wait(200)
                end
            else
                Wait(500)
            end
        else
            Wait(500)
        end
    end
end)

-- Menu pause
CreateThread(function()
    local wasPaused = false

    while true do
        Wait(200)

        if not isLoggedIn then
            goto continue
        end

        local paused = IsPauseMenuActive()
        if paused ~= wasPaused then
            wasPaused = paused
            setHudVisible(not paused)
            if paused then
                sendVehicle(false)
                vehicleHudVisible = false
            end
        end

        ::continue::
    end
end)
