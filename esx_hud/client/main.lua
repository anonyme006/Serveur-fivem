local ESX = nil

local hunger = 100
local thirst = 100
local isLoggedIn = false
local vehicleHudVisible = false
local editMode = false

local KVP_KEY = 'esx_hud:positions'

local function copyPositions(src)
    return {
        status = {
            left = src.status.left,
            top = src.status.top,
        },
        vehicle = {
            left = src.vehicle.left,
            top = src.vehicle.top,
        },
    }
end

local positions = copyPositions(Config.DefaultPositions)

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

    TriggerEvent('esx:getSharedObject', function(obj)
        ESX = obj
    end)

    local timeout = GetGameTimer() + 5000
    while not ESX and GetGameTimer() < timeout do
        Wait(100)
    end

    return ESX ~= nil
end

local function loadPositions()
    local raw = GetResourceKvpString(KVP_KEY)
    if not raw or raw == '' then
        positions = copyPositions(Config.DefaultPositions)
        return
    end

    local ok, decoded = pcall(json.decode, raw)
    if ok and decoded and decoded.status and decoded.vehicle then
        positions = {
            status = {
                left = tonumber(decoded.status.left) or Config.DefaultPositions.status.left,
                top = tonumber(decoded.status.top) or Config.DefaultPositions.status.top,
            },
            vehicle = {
                left = tonumber(decoded.vehicle.left) or Config.DefaultPositions.vehicle.left,
                top = tonumber(decoded.vehicle.top) or Config.DefaultPositions.vehicle.top,
            },
        }
    else
        positions = copyPositions(Config.DefaultPositions)
    end
end

local function savePositions(data)
    if not data or not data.status or not data.vehicle then
        return
    end

    positions = {
        status = {
            left = tonumber(data.status.left) or positions.status.left,
            top = tonumber(data.status.top) or positions.status.top,
        },
        vehicle = {
            left = tonumber(data.vehicle.left) or positions.vehicle.left,
            top = tonumber(data.vehicle.top) or positions.vehicle.top,
        },
    }

    SetResourceKvp(KVP_KEY, json.encode(positions))
end

local function notify(msg)
    if ESX and ESX.ShowNotification then
        ESX.ShowNotification(msg)
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(msg)
        EndTextCommandThefeedPostTicker(false, true)
    end
end

local function setHudVisible(visible)
    SendNUIMessage({
        action = 'setVisible',
        visible = visible,
    })
end

local function sendPositions()
    SendNUIMessage({
        action = 'setPositions',
        positions = positions,
    })
end

local function hideDefaultHudComponents()
    HideHudComponentThisFrame(1)
    HideHudComponentThisFrame(2)
    HideHudComponentThisFrame(3)
    HideHudComponentThisFrame(4)
    HideHudComponentThisFrame(6)
    HideHudComponentThisFrame(7)
    HideHudComponentThisFrame(8)
    HideHudComponentThisFrame(9)
    DisplayRadar(not Config.HideRadar)
end

local function applyMinimapOffset()
    if not Config.OffsetMinimap then
        return
    end

    local offsetY = Config.MinimapOffsetY or 0.028
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

local function openEditMode()
    if editMode or not isLoggedIn then
        return
    end

    editMode = true
    setHudVisible(true)
    sendPositions()
    sendStatus()
    sendVehicle(true, {
        speed = 96,
        rpm = 60,
        fuel = 75,
        engine = 90,
        plate = 'EDIT',
    })

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)

    SendNUIMessage({
        action = 'editMode',
        enabled = true,
        positions = positions,
    })

    notify('Mode édition HUD — glisse les éléments, Entrée pour sauver')
end

local function closeEditMode()
    if not editMode then
        return
    end

    editMode = false
    SetNuiFocus(false, false)

    SendNUIMessage({
        action = 'editMode',
        enabled = false,
    })

    -- Masquer le speedo si on n'est pas en véhicule
    local ped = PlayerPedId()
    if GetVehiclePedIsIn(ped, false) == 0 then
        sendVehicle(false)
        vehicleHudVisible = false
    end
end

local function resetHudPositions()
    positions = copyPositions(Config.DefaultPositions)
    DeleteResourceKvp(KVP_KEY)
    sendPositions()
    SendNUIMessage({
        action = 'resetPositions',
        defaults = Config.DefaultPositions,
    })
    notify('Positions HUD réinitialisées')
end

RegisterNUICallback('savePositions', function(data, cb)
    if data and data.positions then
        savePositions(data.positions)
        notify('Positions HUD sauvegardées')
    end
    cb({ ok = true })
end)

RegisterNUICallback('closeEdit', function(_, cb)
    closeEditMode()
    cb({ ok = true })
end)

RegisterNUICallback('requestReset', function(_, cb)
    resetHudPositions()
    cb({ ok = true })
end)

RegisterCommand(Config.EditCommand, function()
    if editMode then
        closeEditMode()
    else
        openEditMode()
    end
end, false)

RegisterCommand(Config.ResetCommand, function()
    resetHudPositions()
end, false)

RegisterNetEvent('esx:playerLoaded', function()
    isLoggedIn = true
    loadPositions()
    setHudVisible(true)
    sendPositions()
    CreateThread(applyMinimapOffset)
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    isLoggedIn = false
    if editMode then
        closeEditMode()
    end
    setHudVisible(false)
    sendVehicle(false)
    vehicleHudVisible = false
end)

CreateThread(function()
    loadPositions()

    while not initESX() do
        Wait(500)
    end

    local timeout = GetGameTimer() + 10000
    while GetGameTimer() < timeout do
        if ESX.PlayerLoaded or (ESX.GetPlayerData and ESX.GetPlayerData().job) then
            isLoggedIn = true
            setHudVisible(true)
            sendPositions()
            applyMinimapOffset()
            break
        end
        Wait(200)
    end
end)

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

CreateThread(function()
    while true do
        if isLoggedIn then
            hideDefaultHudComponents()

            if editMode then
                Wait(100)
            elseif Config.ShowVehicleHud then
                local ped = PlayerPedId()
                local vehicle = GetVehiclePedIsIn(ped, false)

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

CreateThread(function()
    local wasPaused = false

    while true do
        Wait(200)

        if not isLoggedIn or editMode then
            goto continue
        end

        local paused = IsPauseMenuActive()
        if paused ~= wasPaused then
            wasPaused = paused
            setHudVisible(not paused)
            if paused then
                sendVehicle(false)
                vehicleHudVisible = false
            else
                sendPositions()
            end
        end

        ::continue::
    end
end)
