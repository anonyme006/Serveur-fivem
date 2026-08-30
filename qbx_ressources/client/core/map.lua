if Config.Modules and Config.Modules.core == false then return end

if not Config.Map.enabled then return end

local mapProp = nil
local mapActive = false

local function loadAnim(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local t = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < t do
        Wait(10)
    end
    return HasAnimDictLoaded(dict)
end

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if HasModelLoaded(hash) then return hash end
    RequestModel(hash)
    local t = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < t do
        Wait(10)
    end
    if not HasModelLoaded(hash) then return nil end
    return hash
end

local function clearMap()
    local ped = PlayerPedId()
    if mapProp and DoesEntityExist(mapProp) then
        DetachEntity(mapProp, true, true)
        DeleteEntity(mapProp)
    end
    mapProp = nil
    mapActive = false
    ClearPedSecondaryTask(ped)
end

local function holdMap()
    if mapActive then return end
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) or IsPedDeadOrDying(ped, true) then return end
    if IsPedArmed(ped, 7) then return end

    local cfg = Config.Map
    if not loadAnim(cfg.dict) then return end

    local hash = loadModel(cfg.prop)
    if not hash then return end

    local coords = GetEntityCoords(ped)
    mapProp = CreateObject(hash, coords.x, coords.y, coords.z + 0.2, true, true, false)
    AttachEntityToEntity(
        mapProp, ped, GetPedBoneIndex(ped, cfg.bone),
        cfg.pos.x, cfg.pos.y, cfg.pos.z,
        cfg.rot.x, cfg.rot.y, cfg.rot.z,
        true, true, false, true, 1, true
    )
    SetModelAsNoLongerNeeded(hash)

    TaskPlayAnim(ped, cfg.dict, cfg.anim, 8.0, -8.0, -1, 49, 0.0, false, false, false)
    mapActive = true
end

CreateThread(function()
    while true do
        Wait(200)
        local paused = IsPauseMenuActive()
        if paused and not mapActive then
            holdMap()
        elseif not paused and mapActive then
            clearMap()
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        clearMap()
    end
end)
