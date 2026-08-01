---@diagnostic disable: undefined-global
--[[
    server/main.lua
    Logique serveur sécurisée : permissions, CRUD radars, flash + amendes ESX.
]]

local ESX = exports['es_extended']:getSharedObject()

--- Cache mémoire des radars (rechargé après chaque mutation)
local radarCache = {} ---@type table[]
local radarById = {}  ---@type table<number, table>

--- Rate-limit anti-spam flash : source -> lastTimestamp
local flashRateLimit = {} ---@type table<number, number>
local FLASH_MIN_INTERVAL = 2000

-- =============================================================================
-- HELPERS
-- =============================================================================

---@param src number
---@return table|nil
local function getPlayer(src)
    return ESX.GetPlayerFromId(src)
end

---@param xPlayer table
---@return boolean
local function isAdmin(xPlayer)
    if not xPlayer then
        return false
    end

    local group = xPlayer.getGroup and xPlayer.getGroup() or 'user'
    for i = 1, #Config.AdminGroups do
        if group == Config.AdminGroups[i] then
            return true
        end
    end

    if Config.AdminAce and Config.AdminAce ~= '' then
        if IsPlayerAceAllowed(xPlayer.source, Config.AdminAce) then
            return true
        end
    end

    return false
end

---@param list table[]
local function rebuildCache(list)
    radarCache = list or {}
    radarById = {}
    for i = 1, #radarCache do
        local r = radarCache[i]
        -- Normaliser enabled en bool côté logique
        r.enabled = (r.enabled == 1 or r.enabled == true)
        radarById[r.id] = r
    end
end

local function loadAndSync()
    local list = RadarDB.GetAllRadars()
    rebuildCache(list)
    TriggerClientEvent('esx_radar:client:syncRadars', -1, radarCache)
end

---@param src number|nil
local function syncTo(src)
    if src then
        TriggerClientEvent('esx_radar:client:syncRadars', src, radarCache)
    else
        TriggerClientEvent('esx_radar:client:syncRadars', -1, radarCache)
    end
end

---@param value any
---@param allowed number[]
---@return boolean
local function isAllowedNumber(value, allowed)
    local n = tonumber(value)
    if not n then
        return false
    end
    for i = 1, #allowed do
        if tonumber(allowed[i]) == n then
            return true
        end
    end
    return false
end

---@param direction string
---@return boolean
local function isValidDirection(direction)
    for i = 1, #Config.Directions do
        if Config.Directions[i].value == direction then
            return true
        end
    end
    return false
end

--- Validation payload création / édition
---@param data table
---@param requireCoords boolean
---@return boolean, string|nil
local function validateRadarPayload(data, requireCoords)
    if type(data) ~= 'table' then
        return false, 'Données invalides.'
    end

    if type(data.name) ~= 'string' or #data.name < 2 or #data.name > 64 then
        return false, 'Nom du radar invalide.'
    end

    if type(data.road_name) ~= 'string' or #data.road_name < 2 or #data.road_name > 128 then
        return false, 'Nom de route invalide.'
    end

    if not isAllowedNumber(data.speed_limit, Config.SpeedLimits) then
        return false, 'Limitation invalide.'
    end

    if not isAllowedNumber(data.tolerance, Config.ToleranceOptions) then
        return false, 'Tolérance invalide.'
    end

    if not isAllowedNumber(data.detection_distance, Config.DetectionDistances) then
        return false, 'Distance de détection invalide.'
    end

    if not isValidDirection(data.direction) then
        return false, 'Sens invalide.'
    end

    if requireCoords then
        if type(data.x) ~= 'number' or type(data.y) ~= 'number' or type(data.z) ~= 'number' then
            return false, 'Position invalide.'
        end
        if type(data.heading) ~= 'number' then
            return false, 'Orientation invalide.'
        end
    end

    return true
end

-- =============================================================================
-- CALLBACKS
-- =============================================================================

lib.callback.register('esx_radar:server:isAdmin', function(source)
    local xPlayer = getPlayer(source)
    return isAdmin(xPlayer)
end)

lib.callback.register('esx_radar:server:getRadars', function(source)
    local xPlayer = getPlayer(source)
    if not isAdmin(xPlayer) then
        return nil
    end
    return radarCache
end)

-- =============================================================================
-- SYNC
-- =============================================================================

RegisterNetEvent('esx_radar:server:requestSync', function()
    local src = source
    syncTo(src)
end)

-- =============================================================================
-- CRUD RADARS
-- =============================================================================

RegisterNetEvent('esx_radar:server:createRadar', function(data)
    local src = source
    local xPlayer = getPlayer(src)
    if not isAdmin(xPlayer) then
        return
    end

    local ok, err = validateRadarPayload(data, true)
    if not ok then
        TriggerClientEvent('esx_radar:client:notify', src, err, 'error')
        return
    end

    -- Vérifier que le joueur est bien proche de la position envoyée (anti-cheat)
    local ped = GetPlayerPed(src)
    local pCoords = GetEntityCoords(ped)
    local dist = #(pCoords - vector3(data.x, data.y, data.z))
    if dist > 10.0 then
        TriggerClientEvent('esx_radar:client:notify', src, 'Position trop éloignée.', 'error')
        return
    end

    local insertId = RadarDB.InsertRadar({
        name = data.name,
        road_name = data.road_name,
        speed_limit = tonumber(data.speed_limit),
        tolerance = tonumber(data.tolerance),
        detection_distance = tonumber(data.detection_distance),
        direction = data.direction,
        x = data.x + 0.0,
        y = data.y + 0.0,
        z = data.z + 0.0,
        heading = data.heading + 0.0,
        created_by = xPlayer.getIdentifier and xPlayer.getIdentifier() or xPlayer.identifier,
    })

    if not insertId then
        TriggerClientEvent('esx_radar:client:notify', src, 'Erreur base de données.', 'error')
        return
    end

    loadAndSync()
    TriggerClientEvent('esx_radar:client:notify', src, ('Radar « %s » créé.'):format(data.name), 'success')
    print(('[esx_radar] %s a créé le radar #%s (%s)'):format(GetPlayerName(src), insertId, data.name))
end)

RegisterNetEvent('esx_radar:server:updateRadar', function(data)
    local src = source
    local xPlayer = getPlayer(src)
    if not isAdmin(xPlayer) then
        return
    end

    if type(data) ~= 'table' or not data.id then
        return
    end

    local existing = radarById[tonumber(data.id)]
    if not existing then
        TriggerClientEvent('esx_radar:client:notify', src, 'Radar introuvable.', 'error')
        return
    end

    local ok, err = validateRadarPayload(data, false)
    if not ok then
        TriggerClientEvent('esx_radar:client:notify', src, err, 'error')
        return
    end

    RadarDB.UpdateRadar({
        id = tonumber(data.id),
        name = data.name,
        road_name = data.road_name,
        speed_limit = tonumber(data.speed_limit),
        tolerance = tonumber(data.tolerance),
        detection_distance = tonumber(data.detection_distance),
        direction = data.direction,
    })

    loadAndSync()
    TriggerClientEvent('esx_radar:client:notify', src, 'Radar mis à jour.', 'success')
end)

RegisterNetEvent('esx_radar:server:setEnabled', function(id, enabled)
    local src = source
    local xPlayer = getPlayer(src)
    if not isAdmin(xPlayer) then
        return
    end

    id = tonumber(id)
    if not id or radarById[id] == nil then
        TriggerClientEvent('esx_radar:client:notify', src, 'Radar introuvable.', 'error')
        return
    end

    RadarDB.SetEnabled(id, enabled == true)
    loadAndSync()
    TriggerClientEvent(
        'esx_radar:client:notify',
        src,
        enabled and 'Radar activé.' or 'Radar désactivé.',
        'success'
    )
end)

RegisterNetEvent('esx_radar:server:deleteRadar', function(id)
    local src = source
    local xPlayer = getPlayer(src)
    if not isAdmin(xPlayer) then
        return
    end

    id = tonumber(id)
    if not id or radarById[id] == nil then
        TriggerClientEvent('esx_radar:client:notify', src, 'Radar introuvable.', 'error')
        return
    end

    local name = radarById[id].name
    RadarDB.DeleteRadar(id)
    loadAndSync()
    TriggerClientEvent('esx_radar:client:notify', src, ('Radar « %s » supprimé.'):format(name), 'success')
    print(('[esx_radar] %s a supprimé le radar #%s (%s)'):format(GetPlayerName(src), id, name))
end)

-- =============================================================================
-- FLASH + AMENDE
-- =============================================================================

RegisterNetEvent('esx_radar:server:flash', function(payload)
    local src = source
    local now = GetGameTimer()

    -- Rate limit
    local last = flashRateLimit[src] or 0
    if now - last < FLASH_MIN_INTERVAL then
        return
    end
    flashRateLimit[src] = now

    local xPlayer = getPlayer(src)
    if not xPlayer or type(payload) ~= 'table' then
        return
    end

    local radarId = tonumber(payload.radarId)
    local radar = radarId and radarById[radarId] or nil
    if not radar or not radar.enabled then
        return
    end

    local speed = tonumber(payload.speed)
    local retainedClient = tonumber(payload.retainedSpeed)
    local plate = Utils.NormalizePlate(payload.plate)
    local vehicleModel = type(payload.vehicleModel) == 'string' and payload.vehicleModel:sub(1, 64) or 'UNKNOWN'

    if not speed or speed < 0 or speed > (Config.MaxPlausibleSpeed or 400) then
        return
    end

    -- Vérifier distance joueur ↔ radar
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then
        return
    end
    local pCoords = GetEntityCoords(ped)
    local rCoords = vector3(radar.x, radar.y, radar.z)
    local dist = #(pCoords - rCoords)
    if dist > (Config.MaxFlashDistance or 80.0) then
        return
    end

    -- Recalcul serveur (ne jamais faire confiance au client pour l'amende)
    local threshold = Utils.GetFlashThreshold(radar.speed_limit, radar.tolerance)
    if speed <= threshold then
        return
    end

    local retained = Utils.GetRetainedSpeed(speed, radar.tolerance)
    -- Tolérance anti-desync : écart max 15 km/h avec le client
    if retainedClient and math.abs(retainedClient - retained) > 15 then
        retained = retained -- on garde la valeur serveur
    end

    local jobName = xPlayer.job and xPlayer.job.name or nil
    local authorized = Utils.IsAllowedJob(jobName)

    local excess = retained - radar.speed_limit
    local fineAmount = 0

    if not authorized then
        fineAmount = Utils.GetFineAmount(excess)
        if fineAmount > 0 then
            -- Prélèvement compte bancaire ESX
            local bank = xPlayer.getAccount('bank')
            local balance = bank and bank.money or 0
            if balance >= fineAmount then
                xPlayer.removeAccountMoney('bank', fineAmount, 'Radar automatique')
            else
                -- Solde insuffisant : prélève tout le disponible + reste en cash si possible
                if balance > 0 then
                    xPlayer.removeAccountMoney('bank', balance, 'Radar automatique')
                end
                local remaining = fineAmount - balance
                local cash = xPlayer.getAccount('money')
                local cashBal = cash and cash.money or 0
                if remaining > 0 and cashBal > 0 then
                    xPlayer.removeAccountMoney('money', math.min(remaining, cashBal), 'Radar automatique')
                end
            end
        end
    end

    local identifier = xPlayer.getIdentifier and xPlayer.getIdentifier() or xPlayer.identifier
    local playerName = xPlayer.getName and xPlayer.getName() or GetPlayerName(src)

    RadarDB.InsertFlash({
        identifier = identifier,
        player_name = playerName,
        plate = plate,
        vehicle_model = vehicleModel,
        position = Utils.CoordsToString(pCoords),
        radar_id = radar.id,
        radar_name = radar.name,
        road_name = radar.road_name,
        speed = Utils.Round(speed),
        retained_speed = retained,
        speed_limit = radar.speed_limit,
        fine_amount = fineAmount,
        authorized = authorized,
    })

    TriggerClientEvent('esx_radar:client:flashResult', src, {
        roadName = radar.road_name,
        speedLimit = radar.speed_limit,
        speed = Utils.Round(speed),
        retainedSpeed = retained,
        plate = plate,
        authorized = authorized,
        fineAmount = fineAmount,
    })
end)

-- =============================================================================
-- DÉMARRAGE
-- =============================================================================

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then
        return
    end

    RadarDB.EnsureTables()
    loadAndSync()
    print(('[esx_radar] %s radar(s) chargé(s).'):format(#radarCache))
end)

AddEventHandler('playerDropped', function()
    flashRateLimit[source] = nil
end)

-- Sync quand un joueur ESX est chargé
AddEventHandler('esx:playerLoaded', function(playerId)
    syncTo(playerId)
end)
