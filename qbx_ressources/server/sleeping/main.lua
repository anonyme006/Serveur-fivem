if Config.Modules and Config.Modules.sleeping == false then return end

--[[
    qbx_ressources — SERVER
    Autorité : position, apparence, SQL, sync clients, admin
]]

local QBX = exports.qbx_core

---@type table<string, table> citizenid -> body payload
local Bodies = {}

---@type table<number, table> source -> last client cache { coords, heading, appearance, model, bucket?, at }
local PlayerCache = {}

---@type table<string, number> citizenid -> source (connectés)
local OnlineByCitizen = {}

---@type table<string, number> citizenid -> os.time() anti double-drop
local RecentlyCreated = {}

local function isResourceStarted(name)
    return GetResourceState(name) == 'started'
end

local function detectAppearanceSystem()
    local configured = Config.Sleeping.AppearanceSystem or 'auto'
    if configured ~= 'auto' then return configured end
    if isResourceStarted('illenium-appearance') then return 'illenium-appearance' end
    if isResourceStarted('fivem-appearance') then return 'fivem-appearance' end
    if isResourceStarted('qb-clothing') then return 'qb-clothing' end
    return 'none'
end

---@param source number
---@return table|nil appearance, string|nil model
function GetPlayerAppearance(source)
    local system = detectAppearanceSystem()
    local ped = GetPlayerPed(source)
    local model

    if ped and ped ~= 0 then
        model = GetEntityModel(ped)
    end

    local appearance

    if system == 'illenium-appearance' then
        local ok, data = pcall(function()
            return exports['illenium-appearance']:getPedAppearance(ped)
        end)
        if ok and type(data) == 'table' then appearance = data end
    elseif system == 'fivem-appearance' then
        local ok, data = pcall(function()
            return exports['fivem-appearance']:getPedAppearance(ped)
        end)
        if ok and type(data) == 'table' then appearance = data end
    elseif system == 'qb-clothing' then
        local player = QBX:GetPlayer(source)
        if player and player.PlayerData and player.PlayerData.charinfo then
            -- qb-clothing stocke souvent dans playerskin / metadata
            appearance = player.PlayerData.skin or player.PlayerData.metadata and player.PlayerData.metadata.skin
        end
        if not appearance then
            local cache = PlayerCache[source]
            if cache and cache.appearance then appearance = cache.appearance end
        end
    end

    -- Fallback : cache client périodique
    if not appearance and PlayerCache[source] and PlayerCache[source].appearance then
        appearance = PlayerCache[source].appearance
        if PlayerCache[source].model then
            model = PlayerCache[source].model
        end
    end

    if appearance and appearance.model and not model then
        model = appearance.model
    end

    return appearance, model and tostring(model) or nil
end

local function isAdmin(source)
    if source == 0 then return true end
    if Config.Sleeping.AdminAce and IsPlayerAceAllowed(source, Config.Sleeping.AdminAce) then
        return true
    end
    for _, group in ipairs(Config.Sleeping.AdminGroups or {}) do
        local allowed = false
        pcall(function()
            allowed = exports.qbx_core:HasPermission(source, group) == true
        end)
        if allowed or IsPlayerAceAllowed(source, 'group.' .. group) then
            return true
        end
    end
    return false
end

local function getCitizenId(source)
    local player = QBX:GetPlayer(source)
    if not player or not player.PlayerData then return nil end
    return player.PlayerData.citizenid
end

local function getCharNames(source)
    local player = QBX:GetPlayer(source)
    if not player or not player.PlayerData or not player.PlayerData.charinfo then
        return nil, nil
    end
    local c = player.PlayerData.charinfo
    return c.firstname, c.lastname
end

local function getBucket(source)
    local ok, bucket = pcall(GetPlayerRoutingBucket, source)
    if ok and type(bucket) == 'number' then return bucket end
    return 0
end

local function broadcast(event, payload, bucketFilter)
    if bucketFilter == nil then
        TriggerClientEvent(event, -1, payload)
        return
    end
    for _, id in ipairs(GetPlayers()) do
        local src = tonumber(id)
        if src and getBucket(src) == bucketFilter then
            TriggerClientEvent(event, src, payload)
        end
    end
end

local function upsertSql(body)
    MySQL.insert.await([[
        INSERT INTO sleeping_bodies
            (citizenid, firstname, lastname, model, appearance, x, y, z, heading, bucket)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            firstname = VALUES(firstname),
            lastname = VALUES(lastname),
            model = VALUES(model),
            appearance = VALUES(appearance),
            x = VALUES(x),
            y = VALUES(y),
            z = VALUES(z),
            heading = VALUES(heading),
            bucket = VALUES(bucket)
    ]], {
        body.citizenid,
        body.firstname,
        body.lastname,
        body.model,
        body.appearance and SleepBodies.EncodeJson(body.appearance) or nil,
        body.x, body.y, body.z, body.heading, body.bucket,
    })
end

local function deleteSql(citizenid)
    MySQL.update.await('DELETE FROM sleeping_bodies WHERE citizenid = ?', { citizenid })
end

---@param citizenid string
function RemoveSleepingBody(citizenid)
    citizenid = tostring(citizenid or '')
    if citizenid == '' then return false end

    local existed = Bodies[citizenid] ~= nil
    Bodies[citizenid] = nil
    deleteSql(citizenid)
    TriggerClientEvent('qbx_ressources:sleeping:client:remove', -1, citizenid)
    SleepBodies.Debug('Body removed (%s)', citizenid)
    return existed
end

exports('RemoveSleepingBody', RemoveSleepingBody)

local function createBodyFromPlayer(source, reason)
    local citizenid = getCitizenId(source)
    if not citizenid then
        SleepBodies.Debug('Drop without citizenid (src %s)', source)
        return
    end

    local now = os.time()
    if RecentlyCreated[citizenid] and (now - RecentlyCreated[citizenid]) < 8 then
        SleepBodies.Debug('Skip duplicate drop for %s', citizenid)
        PlayerCache[source] = nil
        OnlineByCitizen[citizenid] = nil
        return
    end
    RecentlyCreated[citizenid] = now

    local ped = GetPlayerPed(source)
    local coords, heading

    if ped and ped ~= 0 and DoesEntityExist(ped) then
        coords = GetEntityCoords(ped)
        heading = GetEntityHeading(ped)
    end

    local cache = PlayerCache[source]
    if cache and cache.coords then
        if not coords then
            coords = cache.coords
            heading = cache.heading or 0.0
        else
            local delta = #(coords - cache.coords)
            if delta > (Config.Sleeping.MaxDropDistanceDelta or 80.0) then
                -- Ped déjà despawn / téléporté : privilégier le cache récent
                SleepBodies.Debug('Drop delta %.1fm — using cache for %s', delta, citizenid)
                coords = cache.coords
                heading = cache.heading or heading or 0.0
            end
        end
    end

    if not coords then
        SleepBodies.Debug('No coords for %s — skip body', citizenid)
        PlayerCache[source] = nil
        OnlineByCitizen[citizenid] = nil
        return
    end

    local appearance, model = GetPlayerAppearance(source)
    if cache then
        if not appearance and cache.appearance then appearance = cache.appearance end
        if not model and cache.model then model = cache.model end
    end

    local firstname, lastname = getCharNames(source)
    local bucket = getBucket(source)

    local body = {
        citizenid = citizenid,
        firstname = firstname,
        lastname = lastname,
        model = model and tostring(model) or (cache and cache.model and tostring(cache.model)) or nil,
        appearance = appearance,
        x = coords.x + 0.0,
        y = coords.y + 0.0,
        z = coords.z + (Config.Sleeping.ZOffset or 0.0),
        heading = (heading or 0.0) + (Config.Sleeping.RotationOffset or 0.0),
        bucket = bucket,
    }

    Bodies[citizenid] = body
    upsertSql(body)

    broadcast('qbx_ressources:sleeping:client:add', body, bucket)
    -- Aussi envoyer à tous : le client filtre par bucket local
    TriggerClientEvent('qbx_ressources:sleeping:client:add', -1, body)

    local name = SleepBodies.DisplayName(body)
    SleepBodies.Debug('%s disconnected (%s) — body created', name, reason or 'unknown')
    SleepBodies.Debug('Body synchronized (%s)', citizenid)

    PlayerCache[source] = nil
    OnlineByCitizen[citizenid] = nil
end

--- Cache client (position + apparence) — validé côté serveur
RegisterNetEvent('qbx_ressources:sleeping:server:cache', function(payload)
    local src = source
    if type(payload) ~= 'table' then return end

    local citizenid = getCitizenId(src)
    if not citizenid then return end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end

    local real = GetEntityCoords(ped)
    local px = tonumber(payload.x)
    local py = tonumber(payload.y)
    local pz = tonumber(payload.z)
    if not px or not py or not pz then return end

    local claimed = vec3(px, py, pz)
    if #(real - claimed) > 25.0 then
        -- Ignore spoof, keep server truth
        claimed = real
    end

    local heading = tonumber(payload.heading)
    if not heading then heading = GetEntityHeading(ped) end

    PlayerCache[src] = {
        coords = claimed,
        heading = heading + 0.0,
        appearance = type(payload.appearance) == 'table' and payload.appearance or nil,
        model = payload.model and tostring(payload.model) or tostring(GetEntityModel(ped)),
        at = os.time(),
    }
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    createBodyFromPlayer(src, reason)
end)

AddEventHandler('qbx_core:server:playerLoggedOut', function(source)
    -- Certains flux logout sans playerDropped immédiat
    if PlayerCache[source] or getCitizenId(source) then
        createBodyFromPlayer(source, 'logged_out')
    end
end)

local function onPlayerLoaded(player)
    if not player or not player.PlayerData then return end
    local src = player.PlayerData.source
    local citizenid = player.PlayerData.citizenid
    if not citizenid then return end

    OnlineByCitizen[citizenid] = src

    if Config.Sleeping.DeleteOnReconnect ~= false and Bodies[citizenid] then
        RemoveSleepingBody(citizenid)
        SleepBodies.Debug('Body removed on reconnect (%s)', citizenid)
    end
end

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    onPlayerLoaded(player)
end)

AddEventHandler('qbx_core:server:playerLoggedIn', function(source)
    local player = QBX:GetPlayer(source)
    onPlayerLoaded(player)
end)

-- Demande sync à la connexion client
lib.callback.register('qbx_ressources:sleeping:getBodies', function(source)
    local bucket = getBucket(source)
    local list = {}
    for _, body in pairs(Bodies) do
        if (body.bucket or 0) == bucket then
            list[#list + 1] = body
        end
    end
    return list
end)

lib.callback.register('qbx_ressources:sleeping:getBucket', function(source)
    return getBucket(source)
end)

lib.callback.register('qbx_ressources:sleeping:admin:list', function(source)
    if not isAdmin(source) then return nil end
    local list = {}
    for _, body in pairs(Bodies) do
        list[#list + 1] = body
    end
    table.sort(list, function(a, b)
        return SleepBodies.DisplayName(a) < SleepBodies.DisplayName(b)
    end)
    return list
end)

RegisterNetEvent('qbx_ressources:sleeping:server:adminRemove', function(citizenid)
    local src = source
    if not isAdmin(src) then return end
    citizenid = tostring(citizenid or '')
    if citizenid == '' then return end
    RemoveSleepingBody(citizenid)
end)

RegisterNetEvent('qbx_ressources:sleeping:server:adminRemoveAll', function()
    local src = source
    if not isAdmin(src) then return end
    local ids = {}
    for citizenid in pairs(Bodies) do
        ids[#ids + 1] = citizenid
    end
    for i = 1, #ids do
        RemoveSleepingBody(ids[i])
    end
    SleepBodies.Debug('Admin %s cleared all bodies (%d)', src, #ids)
end)

RegisterNetEvent('qbx_ressources:sleeping:server:adminTeleportBody', function(citizenid)
    local src = source
    if not isAdmin(src) then return end
    citizenid = tostring(citizenid or '')
    local body = Bodies[citizenid]
    if not body then return end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local bucket = getBucket(src)

    body.x, body.y, body.z = coords.x, coords.y, coords.z + (Config.Sleeping.ZOffset or 0.0)
    body.heading = heading + (Config.Sleeping.RotationOffset or 0.0)
    body.bucket = bucket
    Bodies[citizenid] = body
    upsertSql(body)

    TriggerClientEvent('qbx_ressources:sleeping:client:remove', -1, citizenid)
    TriggerClientEvent('qbx_ressources:sleeping:client:add', -1, body)
end)

--- Bootstrap SQL + restauration
local function loadBodiesFromDb()
    if Config.Sleeping.LoadBodiesOnResourceStart == false then return end

    local rows = MySQL.query.await('SELECT * FROM sleeping_bodies') or {}
    local loaded = 0

    for _, row in ipairs(rows) do
        local body = SleepBodies.NormalizeBody(row)
        if body then
            -- Ne pas restaurer si le joueur est déjà online
            if OnlineByCitizen[body.citizenid] then
                deleteSql(body.citizenid)
                SleepBodies.Debug('Skipped online citizenid %s', body.citizenid)
            else
                Bodies[body.citizenid] = body
                loaded = loaded + 1
            end
        end
    end

    SleepBodies.Debug('Loaded %d bodies from MySQL', loaded)
    TriggerClientEvent('qbx_ressources:sleeping:client:fullSync', -1, Bodies)
end

MySQL.ready(function()
    -- Schéma unifié déjà appliqué par server/bootstrap.lua
    -- (sleeping_bodies inclus dans sql/qbx_ressources.sql)

    -- Marquer les joueurs déjà connectés
    for _, id in ipairs(GetPlayers()) do
        local src = tonumber(id)
        local player = src and QBX:GetPlayer(src)
        if player and player.PlayerData and player.PlayerData.citizenid then
            OnlineByCitizen[player.PlayerData.citizenid] = src
        end
    end

    SetTimeout(1500, loadBodiesFromDb)
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    SleepBodies.Debug('Resource started')
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    TriggerClientEvent('qbx_ressources:sleeping:client:clear', -1)
end)

--- Commande admin
local function openAdminMenu(source)
    if source == 0 then
        local n = 0
        for _ in pairs(Bodies) do n = n + 1 end
        print(('[SleepingBodies] %d bodies in memory'):format(n))
        return
    end
    if not isAdmin(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Sleeping Bodies',
            description = 'Permission refusée',
            type = 'error',
        })
        return
    end
    TriggerClientEvent('qbx_ressources:sleeping:client:adminMenu', source)
end

if lib and lib.addCommand then
    lib.addCommand('sleepingbodies', {
        help = 'Menu admin — corps endormis',
    }, function(source)
        openAdminMenu(source)
    end)
else
    RegisterCommand('sleepingbodies', function(source)
        openAdminMenu(source)
    end, false)
end
