if Config.Modules and Config.Modules.sleeping == false then return end

--[[
    qbx_ressources — CLIENT
    Spawn local des corps (sync serveur), animation, noms, ox_target, admin
]]

---@type table<string, number> citizenid -> ped
local LocalPeds = {}

---@type table<string, table> citizenid -> body data
local BodyData = {}

---@type table<string, number> citizenid -> ox_target zone id / entity
local TargetIds = {}

local myBucket = 0

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

local function loadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do
        Wait(10)
    end
    return HasAnimDictLoaded(dict)
end

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) and not IsModelValid(hash) then
        hash = `mp_m_freemode_01`
    end
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(10)
    end
    if not HasModelLoaded(hash) then return nil end
    return hash
end

---@param ped number
function PlaySleepingAnimation(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end

    if Config.Sleeping.UseScenario and Config.Sleeping.Scenario then
        TaskStartScenarioInPlace(ped, Config.Sleeping.Scenario, 0, true)
        return
    end

    local primary = Config.Sleeping.SleepAnimation or {}
    local fallback = Config.Sleeping.SleepAnimationFallback or {}

    local function play(cfg)
        if not cfg.dict or not cfg.anim then return false end
        if not loadAnimDict(cfg.dict) then return false end
        TaskPlayAnim(ped, cfg.dict, cfg.anim, 8.0, -8.0, -1, cfg.flag or 1, 0.0, false, false, false)
        return true
    end

    if not play(primary) then
        play(fallback)
    end
end

---@param ped number
---@param appearance table|nil
function ApplyPlayerAppearance(ped, appearance)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end
    if type(appearance) ~= 'table' then return end

    local system = detectAppearanceSystem()

    if system == 'illenium-appearance' then
        pcall(function()
            exports['illenium-appearance']:setPedAppearance(ped, appearance)
        end)
        return
    end

    if system == 'fivem-appearance' then
        pcall(function()
            exports['fivem-appearance']:setPedAppearance(ped, appearance)
        end)
        return
    end

    if system == 'qb-clothing' then
        -- qb-clothing typiquement orienté joueur ; tentative best-effort
        pcall(function()
            TriggerEvent('qb-clothing:client:loadPlayerClothing', appearance, ped)
        end)
        return
    end
end

local function hardenPed(ped)
    SetEntityAsMissionEntity(ped, true, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true)
    SetPedCombatAttributes(ped, 17, true)
    SetPedSeeingRange(ped, 0.0)
    SetPedHearingRange(ped, 0.0)
    SetPedAlertness(ped, 0)
    SetPedKeepTask(ped, true)
    SetEntityCanBeDamaged(ped, false)
    SetPedCanBeTargetted(ped, false)
    SetPedDiesWhenInjured(ped, false)
    SetEntityProofs(ped, true, true, true, true, true, true, true, true)
    SetPedConfigFlag(ped, 208, true) -- disable panic
    SetPedConfigFlag(ped, 229, true)
end

local function removeTarget(citizenid)
    if not TargetIds[citizenid] then return end
    if isResourceStarted('ox_target') then
        pcall(function()
            exports.ox_target:removeLocalEntity(TargetIds[citizenid])
        end)
    end
    TargetIds[citizenid] = nil
end

local function addTarget(citizenid, ped, body)
    if not Config.Sleeping.UseOxTarget or not isResourceStarted('ox_target') then return end
    if not ped or ped == 0 then return end

    removeTarget(citizenid)

    local options = {
        {
            name = 'qbx_sleep_inspect_' .. citizenid,
            icon = 'fa-solid fa-moon',
            label = 'Voir le corps',
            onSelect = function()
                lib.notify({
                    title = 'Corps endormi',
                    description = ('%s\nCitizenID : %s\nBucket : %s'):format(
                        SleepBodies.DisplayName(body),
                        citizenid,
                        tostring(body.bucket or 0)
                    ),
                    type = 'inform',
                })
            end,
        },
        {
            name = 'qbx_sleep_id_' .. citizenid,
            icon = 'fa-solid fa-id-card',
            label = 'Identifier',
            onSelect = function()
                lib.notify({
                    title = SleepBodies.DisplayName(body),
                    description = 'Joueur déconnecté',
                    type = 'inform',
                })
            end,
        },
        {
            name = 'qbx_sleep_admin_del_' .. citizenid,
            icon = 'fa-solid fa-trash',
            label = 'Supprimer (admin)',
            groups = Config.Sleeping.AdminGroups,
            onSelect = function()
                TriggerServerEvent('qbx_ressources:sleeping:server:adminRemove', citizenid)
            end,
        },
        {
            name = 'qbx_sleep_admin_tp_' .. citizenid,
            icon = 'fa-solid fa-location-arrow',
            label = 'Téléporter le corps ici (admin)',
            groups = Config.Sleeping.AdminGroups,
            onSelect = function()
                TriggerServerEvent('qbx_ressources:sleeping:server:adminTeleportBody', citizenid)
            end,
        },
    }

    exports.ox_target:addLocalEntity(ped, options)
    TargetIds[citizenid] = ped
end

local function deleteBodyPed(citizenid)
    removeTarget(citizenid)
    local ped = LocalPeds[citizenid]
    if ped and DoesEntityExist(ped) then
        FreezeEntityPosition(ped, false)
        DeleteEntity(ped)
    end
    LocalPeds[citizenid] = nil
    BodyData[citizenid] = nil
end

local function createBodyPed(body)
    if type(body) ~= 'table' or not body.citizenid then return end

    local citizenid = body.citizenid
    local bucket = tonumber(body.bucket) or 0
    if bucket ~= myBucket then
        deleteBodyPed(citizenid)
        BodyData[citizenid] = body -- garder data si on change de bucket plus tard
        return
    end

    -- Évite doublon
    if LocalPeds[citizenid] and DoesEntityExist(LocalPeds[citizenid]) then
        deleteBodyPed(citizenid)
    end

    BodyData[citizenid] = body

    local modelHash = loadModel(body.model or `mp_m_freemode_01`)
    if not modelHash then return end

    local ped = CreatePed(
        0,
        modelHash,
        body.x + 0.0,
        body.y + 0.0,
        body.z + (Config.Sleeping.ZOffset or 0.0),
        (body.heading or 0.0) + (Config.Sleeping.RotationOffset or 0.0),
        false, -- local entity (stable pour corps persistants)
        true
    )

    SetModelAsNoLongerNeeded(modelHash)

    if not ped or ped == 0 then return end

    SetEntityCoordsNoOffset(ped, body.x, body.y, body.z + (Config.Sleeping.ZOffset or 0.0), false, false, false)
    SetEntityHeading(ped, (body.heading or 0.0) + (Config.Sleeping.RotationOffset or 0.0))

    local found, groundZ = GetGroundZFor_3dCoord(body.x + 0.0, body.y + 0.0, body.z + 2.0, false)
    if found then
        SetEntityCoordsNoOffset(ped, body.x, body.y, groundZ + (Config.Sleeping.ZOffset or 0.0), false, false, false)
    end

    hardenPed(ped)
    ApplyPlayerAppearance(ped, body.appearance)
    Wait(50)
    PlaySleepingAnimation(ped)

    LocalPeds[citizenid] = ped
    addTarget(citizenid, ped, body)
    SleepBodies.Debug('Client ped created for %s', citizenid)
end

local function clearAllPeds()
    for citizenid in pairs(LocalPeds) do
        deleteBodyPed(citizenid)
    end
    BodyData = {}
end

local function refreshBucketVisibility()
    myBucket = lib.callback.await('qbx_ressources:sleeping:getBucket', false) or 0
    local list = lib.callback.await('qbx_ressources:sleeping:getBodies', false) or {}
    local keep = {}
    for i = 1, #list do
        local body = list[i]
        keep[body.citizenid] = true
        createBodyPed(body)
    end
    for citizenid in pairs(LocalPeds) do
        if not keep[citizenid] then
            deleteBodyPed(citizenid)
        end
    end
end

RegisterNetEvent('qbx_ressources:sleeping:client:add', function(body)
    body = SleepBodies.NormalizeBody(body)
    if not body then return end
    myBucket = lib.callback.await('qbx_ressources:sleeping:getBucket', false) or myBucket
    if (body.bucket or 0) ~= myBucket then
        BodyData[body.citizenid] = body
        deleteBodyPed(body.citizenid)
        return
    end
    createBodyPed(body)
end)

RegisterNetEvent('qbx_ressources:sleeping:client:remove', function(citizenid)
    citizenid = tostring(citizenid or '')
    deleteBodyPed(citizenid)
end)

RegisterNetEvent('qbx_ressources:sleeping:client:clear', function()
    clearAllPeds()
end)

RegisterNetEvent('qbx_ressources:sleeping:client:fullSync', function(map)
    clearAllPeds()
    if type(map) ~= 'table' then return end
    refreshBucketVisibility()
end)

-- Cache périodique position + apparence (serveur valide)
CreateThread(function()
    while true do
        Wait(Config.Sleeping.ClientCacheInterval or 15000)
        local ped = PlayerPedId()
        if ped ~= 0 and not IsEntityDead(ped) then
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            local appearance
            local system = detectAppearanceSystem()

            if system == 'illenium-appearance' then
                local ok, data = pcall(function()
                    return exports['illenium-appearance']:getPedAppearance(ped)
                end)
                if ok then appearance = data end
            elseif system == 'fivem-appearance' then
                local ok, data = pcall(function()
                    return exports['fivem-appearance']:getPedAppearance(ped)
                end)
                if ok then appearance = data end
            end

            TriggerServerEvent('qbx_ressources:sleeping:server:cache', {
                x = coords.x, y = coords.y, z = coords.z,
                heading = heading,
                model = GetEntityModel(ped),
                appearance = appearance,
            })
        end
    end
end)

-- Sync initiale + maintien animation / noms (attente dynamique)
CreateThread(function()
    Wait(2500)
    refreshBucketVisibility()

    while true do
        local sleep = 1000
        local playerCoords = GetEntityCoords(PlayerPedId())
        local nearAny = false
        local nameDist = Config.Sleeping.NameDistance or 10.0

        for citizenid, ped in pairs(LocalPeds) do
            if not DoesEntityExist(ped) then
                -- ped détruit par le moteur → recreate
                local data = BodyData[citizenid]
                LocalPeds[citizenid] = nil
                if data then createBodyPed(data) end
            else
                local pcoords = GetEntityCoords(ped)
                local dist = #(playerCoords - pcoords)

                if dist < 40.0 then
                    nearAny = true
                    -- Relancer anim si coupée
                    if not IsEntityPlayingAnim(ped, (Config.Sleeping.SleepAnimation and Config.Sleeping.SleepAnimation.dict) or '', (Config.Sleeping.SleepAnimation and Config.Sleeping.SleepAnimation.anim) or '', 3)
                        and not IsEntityPlayingAnim(ped, (Config.Sleeping.SleepAnimationFallback and Config.Sleeping.SleepAnimationFallback.dict) or '', (Config.Sleeping.SleepAnimationFallback and Config.Sleeping.SleepAnimationFallback.anim) or '', 3)
                    then
                        PlaySleepingAnimation(ped)
                    end
                end

                if Config.Sleeping.ShowName and dist <= nameDist then
                    sleep = 0
                    local body = BodyData[citizenid] or {}
                    local text = ('💤 %s\nDéconnecté'):format(SleepBodies.DisplayName(body))
                    local onScreen, sx, sy = World3dToScreen2d(pcoords.x, pcoords.y, pcoords.z + 0.85)
                    if onScreen then
                        local c = Config.Sleeping.NameColor or { r = 180, g = 210, b = 255, a = 220 }
                        SetTextScale(0.32, 0.32)
                        SetTextFont(4)
                        SetTextProportional(true)
                        SetTextColour(c.r, c.g, c.b, c.a)
                        SetTextCentre(true)
                        SetTextOutline()
                        BeginTextCommandDisplayText('STRING')
                        AddTextComponentSubstringPlayerName(text)
                        EndTextCommandDisplayText(sx, sy)
                    end
                end
            end
        end

        if nearAny and sleep ~= 0 then
            sleep = 250
        end

        Wait(sleep)
    end
end)

-- Refresh quand le joueur change potentiellement de bucket (polling léger)
CreateThread(function()
    while true do
        Wait(5000)
        local bucket = lib.callback.await('qbx_ressources:sleeping:getBucket', false)
        if type(bucket) == 'number' and bucket ~= myBucket then
            myBucket = bucket
            refreshBucketVisibility()
        end
    end
end)

--- Menu admin ox_lib
RegisterNetEvent('qbx_ressources:sleeping:client:adminMenu', function()
    local list = lib.callback.await('qbx_ressources:sleeping:admin:list', false)
    if list == nil then
        lib.notify({ title = 'Sleeping Bodies', description = 'Permission refusée', type = 'error' })
        return
    end

    local options = {
        {
            title = ('Corps actifs : %s'):format(#list),
            icon = 'moon',
            disabled = true,
        },
        {
            title = 'Supprimer tous les corps',
            icon = 'trash',
            iconColor = '#e74c3c',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = 'Confirmation',
                    content = ('Supprimer les %s corps ?'):format(#list),
                    centered = true,
                    cancel = true,
                })
                if confirm == 'confirm' then
                    TriggerServerEvent('qbx_ressources:sleeping:server:adminRemoveAll')
                end
            end,
        },
        {
            title = 'Rechercher un citizenid',
            icon = 'magnifying-glass',
            onSelect = function()
                local input = lib.inputDialog('Recherche', {
                    { type = 'input', label = 'CitizenID', required = true },
                })
                if not input or not input[1] then return end
                local cid = tostring(input[1])
                local found
                for i = 1, #list do
                    if list[i].citizenid == cid then found = list[i] break end
                end
                if not found then
                    lib.notify({ title = 'Introuvable', type = 'error' })
                    return
                end
                lib.registerContext({
                    id = 'qbx_sleep_admin_one',
                    title = SleepBodies.DisplayName(found),
                    menu = 'qbx_sleep_admin',
                    options = {
                        {
                            title = 'Informations',
                            description = ('%s | bucket %s | %.1f %.1f %.1f'):format(
                                found.citizenid, found.bucket, found.x, found.y, found.z
                            ),
                            icon = 'circle-info',
                        },
                        {
                            title = 'Se téléporter au corps',
                            icon = 'location-dot',
                            onSelect = function()
                                SetEntityCoords(PlayerPedId(), found.x, found.y, found.z, false, false, false, false)
                            end,
                        },
                        {
                            title = 'Téléporter le corps ici',
                            icon = 'location-arrow',
                            onSelect = function()
                                TriggerServerEvent('qbx_ressources:sleeping:server:adminTeleportBody', found.citizenid)
                            end,
                        },
                        {
                            title = 'Supprimer',
                            icon = 'trash',
                            onSelect = function()
                                TriggerServerEvent('qbx_ressources:sleeping:server:adminRemove', found.citizenid)
                            end,
                        },
                    },
                })
                lib.showContext('qbx_sleep_admin_one')
            end,
        },
    }

    for i = 1, #list do
        local body = list[i]
        options[#options + 1] = {
            title = SleepBodies.DisplayName(body),
            description = ('%s — bucket %s'):format(body.citizenid, body.bucket or 0),
            icon = 'user',
            onSelect = function()
                lib.registerContext({
                    id = 'qbx_sleep_admin_detail',
                    title = SleepBodies.DisplayName(body),
                    menu = 'qbx_sleep_admin',
                    options = {
                        {
                            title = 'Informations',
                            description = ('Coords: %.2f, %.2f, %.2f | h: %.1f'):format(body.x, body.y, body.z, body.heading),
                            icon = 'circle-info',
                        },
                        {
                            title = 'Se téléporter au corps',
                            icon = 'location-dot',
                            onSelect = function()
                                SetEntityCoords(PlayerPedId(), body.x, body.y, body.z, false, false, false, false)
                            end,
                        },
                        {
                            title = 'Téléporter le corps ici',
                            icon = 'location-arrow',
                            onSelect = function()
                                TriggerServerEvent('qbx_ressources:sleeping:server:adminTeleportBody', body.citizenid)
                            end,
                        },
                        {
                            title = 'Supprimer',
                            icon = 'trash',
                            onSelect = function()
                                TriggerServerEvent('qbx_ressources:sleeping:server:adminRemove', body.citizenid)
                            end,
                        },
                    },
                })
                lib.showContext('qbx_sleep_admin_detail')
            end,
        }
    end

    lib.registerContext({
        id = 'qbx_sleep_admin',
        title = 'Sleeping Bodies',
        options = options,
    })
    lib.showContext('qbx_sleep_admin')
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        clearAllPeds()
    end
end)

-- Exports client
exports('ApplyPlayerAppearance', ApplyPlayerAppearance)
exports('PlaySleepingAnimation', PlaySleepingAnimation)
