if Config.Modules and Config.Modules.core == false then return end

if not Config.Cover.enabled then return end

local covers = {} -- plate -> data
local coverProps = {} -- plate -> entity
local coveredVehicles = {} -- plate -> vehicle entity (hidden under cover)

local function loadModel(model)
    if model == nil or model == '' then return nil end
    local hash = type(model) == 'number' and model or joaat(model)
    if hash == 0 then return nil end
    RequestModel(hash)
    local t = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < t do Wait(10) end
    return HasModelLoaded(hash) and hash or nil
end

local function deleteCoverProp(plate)
    plate = Core.NormalizePlate(plate)
    local ent = coverProps[plate]
    if ent and DoesEntityExist(ent) then
        DeleteEntity(ent)
    end
    coverProps[plate] = nil

    local veh = coveredVehicles[plate]
    if veh and DoesEntityExist(veh) then
        DeleteEntity(veh)
    end
    coveredVehicles[plate] = nil
end

local function spawnCover(plate, data)
    plate = Core.NormalizePlate(plate)
    deleteCoverProp(plate)

    local c = data.coords
    if not c or not c.x then return end

    -- Véhicule gelé / verrouillé (état « bâché »)
    local props = data.props or {}
    local model = props.model
    if model then
        local mHash = type(model) == 'string' and joaat(model) or tonumber(model)
        if mHash and loadModel(mHash) then
            local veh = CreateVehicle(mHash, c.x, c.y, c.z, c.w or 0.0, false, false)
            SetEntityAsMissionEntity(veh, true, true)
            SetVehicleNumberPlateText(veh, plate)
            SetVehicleDoorsLocked(veh, 2)
            SetVehicleDoorsLockedForAllPlayers(veh, true)
            SetEntityInvincible(veh, true)
            FreezeEntityPosition(veh, true)
            SetVehicleEngineOn(veh, false, true, true)
            SetVehicleUndriveable(veh, true)
            SetVehicleDirtLevel(veh, 15.0)
            if props.engineHealth then SetVehicleEngineHealth(veh, props.engineHealth + 0.0) end
            if props.bodyHealth then SetVehicleBodyHealth(veh, props.bodyHealth + 0.0) end
            coveredVehicles[plate] = veh
            SetModelAsNoLongerNeeded(mHash)
        end
    end

    -- Prop bâche optionnel (configurable — ignore si le modèle n'existe pas)
    local propHash = loadModel(Config.Cover.prop)
    if propHash then
        local obj = CreateObject(
            propHash,
            c.x + (Config.Cover.offset.x or 0.0),
            c.y + (Config.Cover.offset.y or 0.0),
            c.z + (Config.Cover.offset.z or 0.05),
            false, false, false
        )
        SetEntityHeading(obj, c.w or c.heading or 0.0)
        FreezeEntityPosition(obj, true)
        SetEntityCollision(obj, false, false)
        SetModelAsNoLongerNeeded(propHash)
        coverProps[plate] = obj
    end
end

local function syncAll(data)
    covers = data or {}
    local keep = {}
    for plate, entry in pairs(covers) do
        plate = Core.NormalizePlate(plate)
        keep[plate] = true
        spawnCover(plate, entry)
    end
    for plate in pairs(coverProps) do
        if not keep[plate] then
            deleteCoverProp(plate)
        end
    end
end

RegisterNetEvent('qbx_ressources:cover:sync', function(data)
    syncAll(data)
end)

CreateThread(function()
    Wait(2000)
    local data = lib.callback.await('qbx_ressources:cover:getAll', false)
    if data then syncAll(data) end
end)

local function getTargetVehicle()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        return GetVehiclePedIsIn(ped, false)
    end
    local coords = GetEntityCoords(ped)
    return GetClosestVehicle(coords.x, coords.y, coords.z, Config.Cover.distance or 4.0, 0, 70)
end

local function putCover()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        return Core.Notify(Core.Locale('used_in_vehicle'), 'error')
    end

    local veh = getTargetVehicle()
    if veh == 0 or not DoesEntityExist(veh) then
        return Core.Notify(Core.Locale('key_no_vehicle'), 'error')
    end

    local plate = Core.NormalizePlate(GetVehicleNumberPlateText(veh))
    local coords = GetEntityCoords(veh)
    local heading = GetEntityHeading(veh)

    local props = {
        model = GetEntityModel(veh),
        engineHealth = GetVehicleEngineHealth(veh),
        bodyHealth = GetVehicleBodyHealth(veh),
        fuelLevel = Core.GetFuelLevel(veh),
        plate = plate,
    }

    local okProgress = true
    if lib.progressCircle then
        okProgress = lib.progressCircle({
            duration = Config.Cover.progress or 4000,
            label = Core.Locale('cover_progress_on'),
            position = 'bottom',
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, car = true, combat = true },
            anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
        })
    else
        Wait(Config.Cover.progress or 4000)
    end

    if not okProgress then return end

    local ok, msg = lib.callback.await('qbx_ressources:cover:put', false, plate, {
        x = coords.x, y = coords.y, z = coords.z, w = heading,
    }, props)

    if ok then
        SetEntityAsMissionEntity(veh, true, true)
        DeleteVehicle(veh)
        Core.Notify(Core.Locale(msg or 'cover_on'), 'success')
    else
        local text = msg or 'cover_busy'
        if text == 'used_invalid_price' then
            Core.Notify(Core.Locale(text), 'error')
        else
            Core.Notify(Core.Locale(text), 'error')
        end
    end
end

local function removeCover()
    local ped = PlayerPedId()
    local pcoords = GetEntityCoords(ped)
    local nearest, nearestDist, nearestPlate = nil, Config.Cover.distance or 4.0, nil

    for plate, data in pairs(covers) do
        local c = data.coords
        if c then
            local dist = #(pcoords - vec3(c.x, c.y, c.z))
            if dist < nearestDist then
                nearestDist = dist
                nearest = data
                nearestPlate = Core.NormalizePlate(plate)
            end
        end
    end

    if not nearest then
        return Core.Notify(Core.Locale('cover_none'), 'error')
    end

    local okProgress = true
    if lib.progressCircle then
        okProgress = lib.progressCircle({
            duration = Config.Cover.progress or 4000,
            label = Core.Locale('cover_progress_off'),
            position = 'bottom',
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, car = true, combat = true },
            anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
        })
    end
    if not okProgress then return end

    local ok, msg, entry = lib.callback.await('qbx_ressources:cover:remove', false, nearestPlate)
    if not ok then
        return Core.Notify(Core.Locale(msg or 'cover_busy'), 'error')
    end

    deleteCoverProp(nearestPlate)
    Core.Notify(Core.Locale(msg or 'cover_off'), 'success')

    -- Respawn véhicule
    entry = entry or nearest
    local c = entry.coords
    local props = entry.props or {}
    local model = props.model
    if model and c then
        local mHash = type(model) == 'string' and joaat(model) or tonumber(model)
        if mHash and loadModel(mHash) then
            local veh = CreateVehicle(mHash, c.x, c.y, c.z, c.w or 0.0, true, false)
            SetVehicleNumberPlateText(veh, nearestPlate)
            SetVehicleOnGroundProperly(veh)
            if props.engineHealth then SetVehicleEngineHealth(veh, props.engineHealth + 0.0) end
            if props.bodyHealth then SetVehicleBodyHealth(veh, props.bodyHealth + 0.0) end
            if props.fuelLevel then SetVehicleFuelLevel(veh, props.fuelLevel + 0.0) end
            SetPedIntoVehicle(ped, veh, -1)
            SetModelAsNoLongerNeeded(mHash)
        end
    end
end

RegisterCommand(Config.Cover.command or 'bache', function()
    local ped = PlayerPedId()
    local pcoords = GetEntityCoords(ped)

    -- Si proche d'une bâche → retirer, sinon poser
    for plate, data in pairs(covers) do
        local c = data.coords
        if c and #(pcoords - vec3(c.x, c.y, c.z)) < (Config.Cover.distance or 4.0) then
            return removeCover()
        end
    end
    putCover()
end, false)

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local pcoords = GetEntityCoords(ped)
        for plate, data in pairs(covers) do
            local c = data.coords
            if c then
                local dist = #(pcoords - vec3(c.x, c.y, c.z))
                if dist < 12.0 then
                    sleep = 0
                    if dist < 8.0 then
                        DrawMarker(2, c.x, c.y, c.z + 1.4, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.2, 0.2, 0.2, 212, 163, 92, 160, false, true, 2, false, nil, nil, false)
                    end
                    if dist < (Config.Cover.distance or 4.0) then
                        BeginTextCommandDisplayHelp('STRING')
                        AddTextComponentSubstringPlayerName(('~y~Bâche~s~ %s — /bache pour retirer'):format(plate))
                        EndTextCommandDisplayHelp(0, false, true, -1)
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for plate in pairs(coverProps) do
        deleteCoverProp(plate)
    end
end)
