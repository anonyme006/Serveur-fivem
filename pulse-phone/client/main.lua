--[[
    Pulse Phone — Client bootstrap
]]

Pulse = Pulse or {}
Pulse.Client = Pulse.Client or {}

local openCooldown = Pulse.Utils.CreateCooldown(Config.Cooldowns.openPhone)

local function hasPhoneItem()
    if not Config.RequireItem then return true end
    local count = exports.ox_inventory:Search('count', Config.PhoneItem)
    return (count or 0) > 0
end

---@param visible boolean
local function setNuiFocus(visible)
    SetNuiFocus(visible, visible)
    SetNuiFocusKeepInput(false)
end

function Pulse.Client.IsOpen()
    return Pulse.Client.open == true
end

function Pulse.Client.OpenPhone()
    if Pulse.Client.open then return end
    if not openCooldown() then return end
    if not hasPhoneItem() then
        lib.notify({ title = 'Pulse', description = L('no_phone_item'), type = 'error' })
        return
    end

    Pulse.Client.open = true
    setNuiFocus(true)

    local profile = lib.callback.await('pulse-phone:server:getBootstrap', false) or {}
    SendNUIMessage({
        action = 'phone:open',
        data = {
            profile = profile,
            config = {
                theme = profile.theme or Config.DefaultTheme,
                wallpaper = profile.wallpaper or Config.DefaultWallpaper,
                colors = Config.Colors,
                apps = Config.Apps,
                locale = Config.Locale,
                position = Config.PhonePosition,
                animations = Config.Animations,
                sounds = Config.Sounds,
            },
        },
    })
    Pulse.Utils.Debug('Phone opened')
end

function Pulse.Client.ClosePhone()
    if not Pulse.Client.open then return end
    Pulse.Client.open = false
    setNuiFocus(false)
    SendNUIMessage({ action = 'phone:close' })
    Pulse.Utils.Debug('Phone closed')
end

function Pulse.Client.TogglePhone()
    if Pulse.Client.open then
        Pulse.Client.ClosePhone()
    else
        Pulse.Client.OpenPhone()
    end
end

RegisterCommand(Config.OpenCommand, function()
    Pulse.Client.TogglePhone()
end, false)

lib.addKeybind({
    name = 'pulse_phone_open',
    description = L('phone_open'),
    defaultKey = Config.OpenKey,
    onPressed = function()
        Pulse.Client.TogglePhone()
    end,
})

RegisterNUICallback('phone:ready', function(_, cb)
    cb({ ok = true })
end)

RegisterNUICallback('phone:close', function(_, cb)
    Pulse.Client.ClosePhone()
    cb({ ok = true })
end)

RegisterNUICallback('phone:setPosition', function(data, cb)
    if type(data) == 'table' and data.x and data.y then
        Config.PhonePosition.x = Pulse.Utils.Clamp(data.x, 0.15, 0.95)
        Config.PhonePosition.y = Pulse.Utils.Clamp(data.y, 0.2, 0.9)
    end
    cb({ ok = true })
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if Pulse.Client.open then
        setNuiFocus(false)
    end
end)

CreateThread(function()
    Wait(500)
    SendNUIMessage({ action = 'phone:init', data = { resource = GetCurrentResourceName() } })
end)
