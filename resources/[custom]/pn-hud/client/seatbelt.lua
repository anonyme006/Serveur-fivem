local internalState = false

local function isExternalAvailable()
    return Config.Seatbelt.useExternal and GetResourceState('qbx_seatbelt') == 'started'
end

local function applyWindscreenParams(buckled)
    local mult = Config.Speed.unit == 'MPH' and 2.23694 or 3.6
    SetFlyThroughWindscreenParams(buckled and (160.0 / mult) or (20.0 / mult), 1.0, 17.0, 10.0)
end

local function toggleInternal()
    if isExternalAvailable() then return end

    internalState = not internalState
    LocalPlayer.state:set('seatbelt', internalState, true)
    applyWindscreenParams(internalState)
    TriggerEvent('seatbelt:client:ToggleSeatbelt')
end

local function initSeatbelt()
    if isExternalAvailable() then return end

    applyWindscreenParams(false)

    lib.addKeybind({
        name = 'pn_hud_seatbelt',
        description = 'Attacher / retirer la ceinture',
        defaultKey = Config.Seatbelt.key,
        onPressed = function()
            if not cache.vehicle or IsPauseMenuActive() then return end
            local class = GetVehicleClass(cache.vehicle)
            if class == 8 or class == 13 or class == 14 then return end
            toggleInternal()
        end,
    })

    lib.onCache('vehicle', function(vehicle)
        if not vehicle then
            internalState = false
            LocalPlayer.state:set('seatbelt', false, true)
            applyWindscreenParams(false)
        end
    end)
end

CreateThread(initSeatbelt)

---@return boolean
function IsSeatbeltBuckled()
    if not Config.Seatbelt.enabled then return true end
    return LocalPlayer.state.seatbelt == true
end

function UsesExternalSeatbelt()
    return isExternalAvailable()
end
