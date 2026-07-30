local isDoingAction = false
local wasCancelled = false
local prop = nil
local propTwo = nil
local isAnim = false
local isProp = false
local isPropTwo = false

local function notify(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, true)
end

local function loadAnimDict(dict)
    if not dict or dict == '' then return false end
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() > timeout then return false end
        Wait(10)
    end
    return true
end

local function loadModel(model)
    if not model then return nil end
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelValid(hash) then return nil end
    if HasModelLoaded(hash) then return hash end
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) do
        if GetGameTimer() > timeout then return nil end
        Wait(10)
    end
    return hash
end

local function clearProps()
    if prop and DoesEntityExist(prop) then
        DeleteEntity(prop)
    end
    if propTwo and DoesEntityExist(propTwo) then
        DeleteEntity(propTwo)
    end
    prop = nil
    propTwo = nil
    isProp = false
    isPropTwo = false
end

local function clearAnim()
    if isAnim then
        ClearPedTasks(PlayerPedId())
        isAnim = false
    end
end

local function cleanupAction()
    clearAnim()
    clearProps()
    isDoingAction = false
end

local function sendTheme()
    SendNUIMessage({
        action = 'theme',
        fillColor = Config.FillColor,
        trackColor = Config.TrackColor,
        width = Config.Width,
        height = Config.Height,
        position = Config.Position,
    })
end

local function disableControls()
    DisableControlAction(0, 1, true)   -- LookLeftRight
    DisableControlAction(0, 2, true)   -- LookUpDown
    DisableControlAction(0, 24, true)  -- Attack
    DisableControlAction(0, 25, true)  -- Aim
    DisableControlAction(0, 21, true)  -- Sprint
    DisableControlAction(0, 22, true)  -- Jump
    DisableControlAction(0, 23, true)  -- Enter
    DisableControlAction(0, 75, true)  -- Exit vehicle
    DisableControlAction(0, 140, true) -- Melee
    DisableControlAction(0, 141, true) -- Melee
    DisableControlAction(0, 142, true) -- Melee
    DisablePlayerFiring(PlayerId(), true)
end

local function attachProp(ped, data)
    local hash = loadModel(data.model)
    if not hash then return nil end

    local coords = GetEntityCoords(ped)
    local obj = CreateObject(hash, coords.x, coords.y, coords.z + 0.2, true, true, true)
    local bone = data.bone or 60309
    local pos = data.coords or { x = 0.0, y = 0.0, z = 0.0 }
    local rot = data.rotation or { x = 0.0, y = 0.0, z = 0.0 }

    AttachEntityToEntity(
        obj, ped, GetPedBoneIndex(ped, bone),
        pos.x, pos.y, pos.z,
        rot.x, rot.y, rot.z,
        true, true, false, true, 1, true
    )
    SetModelAsNoLongerNeeded(hash)
    return obj
end

--- Lance une barre de progression.
--- @param action table
---   name / label  string
---   duration      number (ms)
---   canCancel     boolean?
---   useWhileDead  boolean?
---   disarm        boolean?
---   controlDisables table? (ignored — controls always lightly disabled)
---   animation     { animDict, anim, flags }?
---   prop / propTwo { model, bone, coords, rotation }?
--- @param finish? function(wasCancelled:boolean)
function Progress(action, finish)
    if isDoingAction then
        if finish then finish(true) end
        return false
    end

    local ped = PlayerPedId()
    if IsEntityDead(ped) and not action.useWhileDead then
        if finish then finish(true) end
        return false
    end

    local duration = tonumber(action.duration) or Config.DefaultDuration
    local label = action.label or action.name or ''
    local canCancel = action.canCancel
    if canCancel == nil then canCancel = Config.CanCancel end

    wasCancelled = false
    isDoingAction = true

    if action.disarm ~= false then
        SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    end

    if action.animation and action.animation.animDict and action.animation.anim then
        if loadAnimDict(action.animation.animDict) then
            TaskPlayAnim(
                ped,
                action.animation.animDict,
                action.animation.anim,
                3.0, 3.0, -1,
                action.animation.flags or 49,
                0, false, false, false
            )
            isAnim = true
        end
    end

    if action.prop and action.prop.model then
        prop = attachProp(ped, action.prop)
        isProp = prop ~= nil
    end

    if action.propTwo and action.propTwo.model then
        propTwo = attachProp(ped, action.propTwo)
        isPropTwo = propTwo ~= nil
    end

    SendNUIMessage({
        action = 'start',
        label = label,
        duration = duration,
        fillColor = Config.FillColor,
        trackColor = Config.TrackColor,
        width = Config.Width,
        height = Config.Height,
        position = Config.Position,
    })

    CreateThread(function()
        local endAt = GetGameTimer() + duration

        while isDoingAction do
            Wait(0)
            disableControls()

            if canCancel then
                for _, control in ipairs(Config.CancelControls) do
                    if IsControlJustPressed(0, control) or IsDisabledControlJustPressed(0, control) then
                        wasCancelled = true
                        isDoingAction = false
                        break
                    end
                end
            end

            if IsEntityDead(PlayerPedId()) and not action.useWhileDead then
                wasCancelled = true
                isDoingAction = false
            end

            if GetGameTimer() >= endAt then
                isDoingAction = false
            end
        end

        if wasCancelled then
            SendNUIMessage({ action = 'cancel' })
        else
            SendNUIMessage({ action = 'finish' })
        end

        cleanupAction()

        if finish then
            finish(wasCancelled)
        end
    end)

    return true
end

function ProgressWithStartEvent(action, start, finish)
    if start then start() end
    return Progress(action, finish)
end

function ProgressWithTickEvent(action, tick, finish)
    local ok = Progress(action, finish)
    if not ok or not tick then return ok end

    CreateThread(function()
        while isDoingAction do
            tick()
            Wait(0)
        end
    end)

    return ok
end

function ProgressWithStartAndTick(action, start, tick, finish)
    if start then start() end
    return ProgressWithTickEvent(action, tick, finish)
end

function isDoingSomething()
    return isDoingAction
end

function Cancel()
    if not isDoingAction then return end
    wasCancelled = true
    isDoingAction = false
end

exports('Progress', Progress)
exports('ProgressWithStartEvent', ProgressWithStartEvent)
exports('ProgressWithTickEvent', ProgressWithTickEvent)
exports('ProgressWithStartAndTick', ProgressWithStartAndTick)
exports('isDoingSomething', isDoingSomething)
exports('Cancel', Cancel)

-- Alias courants
exports('Start', Progress)
exports('IsActive', isDoingSomething)

RegisterNetEvent('esx_progressbar:client:progress', function(action, finish)
    Progress(action, finish)
end)

RegisterNetEvent('esx_progressbar:client:cancel', function()
    Cancel()
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    cleanupAction()
    SendNUIMessage({ action = 'cancel' })
end)

CreateThread(function()
    Wait(500)
    sendTheme()
end)

if Config.TestCommand and Config.TestCommand ~= '' then
    RegisterCommand(Config.TestCommand, function(_, args)
        local ms = tonumber(args[1]) or 5000
        Progress({
            name = 'test',
            label = args[2] or 'Progression…',
            duration = ms,
            canCancel = true,
            animation = {
                animDict = 'amb@world_human_clipboard@male@idle_a',
                anim = 'idle_c',
                flags = 49,
            },
        }, function(cancelled)
            if cancelled then
                notify('~r~Progression annulée')
            else
                notify('~g~Progression terminée')
            end
        end)
    end, false)
end
