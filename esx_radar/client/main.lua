---@diagnostic disable: undefined-global
--[[
    client/main.lua
    Détection optimisée des radars + sync props/blips/ox_target.
    Idle loin des radars / hors véhicule → Wait long (≈ 0.00 ms).
]]

RadarClient = {}

local radars = {}           ---@type table[]
local radarProps = {}       ---@type table<number, number> id -> entity
local radarBlips = {}       ---@type table<number, number> id -> blip
local targetZones = {}      ---@type table<number, string|number>
local flashCooldowns = {}   ---@type table<string, number> "radarId:plate" -> gameTimer
local isReady = false

--- Accès public pour les menus
---@return table[]
function RadarClient.GetRadars()
    return radars
end

--- Nettoie prop / blip / target d'un radar
---@param id number
local function cleanupRadarVisuals(id)
    if radarProps[id] and DoesEntityExist(radarProps[id]) then
        DeleteEntity(radarProps[id])
    end
    radarProps[id] = nil

    if radarBlips[id] then
        RemoveBlip(radarBlips[id])
        radarBlips[id] = nil
    end

    if targetZones[id] then
        if Config.UseOxTarget then
            pcall(function()
                exports.ox_target:removeZone(targetZones[id])
            end)
        end
        targetZones[id] = nil
    end
end

--- Spawn prop + blip + ox_target pour un radar
---@param radar table
local function setupRadarVisuals(radar)
    cleanupRadarVisuals(radar.id)

    -- Prop
    if Config.RadarProp and Config.RadarProp ~= '' then
        local model = joaat(Config.RadarProp)
        lib.requestModel(model, 5000)
        local obj = CreateObject(model, radar.x, radar.y, radar.z + (Config.RadarPropZOffset or 0.0), false, false, false)
        SetEntityHeading(obj, radar.heading or 0.0)
        FreezeEntityPosition(obj, true)
        SetEntityCollision(obj, true, true)
        SetModelAsNoLongerNeeded(model)
        radarProps[radar.id] = obj
    end

    -- Blip
    if Config.ShowBlips then
        local blip = AddBlipForCoord(radar.x, radar.y, radar.z)
        SetBlipSprite(blip, Config.Blip.sprite)
        SetBlipColour(blip, Config.Blip.color)
        SetBlipScale(blip, Config.Blip.scale)
        SetBlipAsShortRange(blip, Config.Blip.shortRange)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(('%s — %s'):format(Config.Blip.label, radar.name))
        EndTextCommandSetBlipName(blip)
        radarBlips[radar.id] = blip
    end

    -- ox_target (admin)
    if Config.UseOxTarget then
        local zoneId = exports.ox_target:addSphereZone({
            coords = vec3(radar.x, radar.y, radar.z),
            radius = Config.TargetDistance or 2.5,
            debug = false,
            options = {
                {
                    name = ('esx_radar_manage_%s'):format(radar.id),
                    icon = 'fa-solid fa-camera',
                    label = 'Gérer le radar',
                    distance = Config.TargetDistance or 2.5,
                    onSelect = function()
                        local ok = lib.callback.await('esx_radar:server:isAdmin', false)
                        if not ok then
                            RadarEffects.Notify('Vous n\'avez pas la permission.', 'error')
                            return
                        end
                        RadarMenu.OpenAdmin()
                    end,
                },
            },
        })
        targetZones[radar.id] = zoneId
    end
end

--- Recharge toute la liste visuelle
local function rebuildAllVisuals()
    for id in pairs(radarProps) do
        cleanupRadarVisuals(id)
    end
    for id in pairs(radarBlips) do
        cleanupRadarVisuals(id)
    end

    for i = 1, #radars do
        setupRadarVisuals(radars[i])
    end
end

--- Sync depuis le serveur
---@param list table[]
local function applyRadarList(list)
    radars = list or {}
    rebuildAllVisuals()
    isReady = true
end

--- Clé de cooldown
---@param radarId number
---@param plate string
---@return string
local function cooldownKey(radarId, plate)
    return ('%s:%s'):format(radarId, plate)
end

--- Vérifie cooldown local
---@param radarId number
---@param plate string
---@return boolean
local function isOnCooldown(radarId, plate)
    local key = cooldownKey(radarId, plate)
    local untilT = flashCooldowns[key]
    if untilT and GetGameTimer() < untilT then
        return true
    end
    return false
end

---@param radarId number
---@param plate string
local function setCooldown(radarId, plate)
    flashCooldowns[cooldownKey(radarId, plate)] = GetGameTimer() + (Config.FlashCooldown or 15000)
end

--- Trouve le radar le plus proche dans MaxCheckDistance
---@param coords vector3
---@return table|nil, number
local function getNearbyRadar(coords)
    local best, bestDist = nil, Config.MaxCheckDistance or 80.0

    for i = 1, #radars do
        local r = radars[i]
        if r.enabled == 1 or r.enabled == true then
            local d = Utils.Dist2D(coords, r)
            if d < bestDist then
                bestDist = d
                best = r
            end
        end
    end

    return best, bestDist
end

--- Traitement flash d'un véhicule
---@param vehicle number
---@param radar table
local function processVehicle(vehicle, radar)
    if not DoesEntityExist(vehicle) then
        return
    end

    local speed = Utils.Round(Utils.MsToKmh(GetEntitySpeed(vehicle)))
    local threshold = Utils.GetFlashThreshold(radar.speed_limit, radar.tolerance)

    if speed <= threshold then
        return
    end

    local vehCoords = GetEntityCoords(vehicle)
    local radarCoords = vector3(radar.x, radar.y, radar.z)

    -- Uniquement devant le radar
    if not Utils.IsInFrontOfRadar(radarCoords, radar.heading, vehCoords, Config.FrontAngle) then
        return
    end

    -- Sens configuré
    local vehHeading = GetEntityHeading(vehicle)
    if not Utils.IsCorrectDirection(radar.heading, vehHeading, radar.direction) then
        return
    end

    local plate = Utils.NormalizePlate(GetVehicleNumberPlateText(vehicle))
    if isOnCooldown(radar.id, plate) then
        return
    end

    setCooldown(radar.id, plate)

    local retained = Utils.GetRetainedSpeed(speed, radar.tolerance)
    local model = GetEntityModel(vehicle)
    local modelName = GetDisplayNameFromVehicleModel(model) or 'UNKNOWN'

    -- Envoi serveur (amende + log). Les effets locaux attendent la réponse.
    TriggerServerEvent('esx_radar:server:flash', {
        radarId = radar.id,
        speed = speed,
        retainedSpeed = retained,
        plate = plate,
        vehicleModel = modelName,
        netId = NetworkGetNetworkIdFromEntity(vehicle),
    })
end

-- =============================================================================
-- BOUCLE PRINCIPALE (optimisée)
-- =============================================================================

CreateThread(function()
    while not isReady do
        Wait(500)
    end

    while true do
        local sleep = Config.IdleWait or 1500
        local ped = PlayerPedId()

        -- Uniquement conducteur d'un véhicule
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
                local coords = GetEntityCoords(vehicle)
                local radar, dist = getNearbyRadar(coords)

                if radar then
                    sleep = Config.NearWait or 100
                    local detection = tonumber(radar.detection_distance) or 20.0

                    if dist <= detection then
                        sleep = Config.ActiveWait or 50
                        processVehicle(vehicle, radar)
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- Nettoyage périodique des cooldowns expirés (évite une table qui grossit)
CreateThread(function()
    while true do
        Wait(60000)
        local now = GetGameTimer()
        for k, t in pairs(flashCooldowns) do
            if now >= t then
                flashCooldowns[k] = nil
            end
        end
    end
end)

-- =============================================================================
-- EVENTS / COMMANDES
-- =============================================================================

RegisterNetEvent('esx_radar:client:syncRadars', function(list)
    applyRadarList(list)
end)

RegisterNetEvent('esx_radar:client:flashResult', function(data)
    if not data then
        return
    end
    RadarEffects.TriggerFlash({
        title = Config.Notify.title,
        subtitle = Config.Notify.subtitle,
        flashed = Config.Notify.flashed,
        roadName = data.roadName,
        speedLimit = data.speedLimit,
        speed = data.speed,
        retainedSpeed = data.retainedSpeed,
        plate = data.plate,
        authorized = data.authorized,
        fineAmount = data.fineAmount,
    })
end)

RegisterNetEvent('esx_radar:client:notify', function(msg, nType)
    RadarEffects.Notify(msg, nType)
end)

-- Commandes client (permission vérifiée serveur via callback avant ouverture)
RegisterCommand(Config.Commands.create, function()
    local ok = lib.callback.await('esx_radar:server:isAdmin', false)
    if not ok then
        RadarEffects.Notify('Vous n\'avez pas la permission.', 'error')
        return
    end
    RadarMenu.OpenCreate()
end, false)

RegisterCommand(Config.Commands.delete, function()
    local ok = lib.callback.await('esx_radar:server:isAdmin', false)
    if not ok then
        RadarEffects.Notify('Vous n\'avez pas la permission.', 'error')
        return
    end
    RadarMenu.OpenDeleteNearest()
end, false)

RegisterCommand(Config.Commands.manage, function()
    local ok = lib.callback.await('esx_radar:server:isAdmin', false)
    if not ok then
        RadarEffects.Notify('Vous n\'avez pas la permission.', 'error')
        return
    end
    RadarMenu.OpenAdmin()
end, false)

-- Demande sync au démarrage
CreateThread(function()
    Wait(1500)
    TriggerServerEvent('esx_radar:server:requestSync')
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then
        return
    end
    for id in pairs(radarProps) do
        cleanupRadarVisuals(id)
    end
end)
