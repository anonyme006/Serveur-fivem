local resourceName = GetCurrentResourceName()

local function normalizeType(t)
    if not t or t == '' then return 'inform' end
    t = string.lower(tostring(t))
    if Config.TypeAliases[t] then
        return Config.TypeAliases[t]
    end
    if Config.Types[t] then
        return t
    end
    return 'inform'
end

local function typeColor(t)
    local def = Config.Types[t] or Config.Types.inform
    return def.color, def.icon
end

--- Affiche une notification (API ox_lib-compatible).
--- @param data table|string
--- @param description? string
--- @param nType? string
--- @param duration? number
function Notify(data, description, nType, duration)
    local payload

    if type(data) == 'table' then
        payload = data
    else
        -- exports style: Notify(title, description, type, duration)
        -- ou Alert(title, message, time, type)
        payload = {
            title = data,
            description = description,
            type = nType,
            duration = duration,
        }
    end

    if not payload.title and not payload.description then
        return
    end

    local notifyType = normalizeType(payload.type or payload.status)
    local color, icon = typeColor(notifyType)
    local dur = tonumber(payload.duration) or Config.DefaultDuration
    local showDuration = payload.showDuration
    if showDuration == nil then showDuration = Config.ShowDuration end

    local showIcons = Config.ShowIcons
    if payload.icon == false then
        showIcons = false
    elseif payload.icon ~= nil then
        showIcons = true
        icon = payload.icon
    end

    if payload.iconColor and type(payload.iconColor) == 'string' then
        color = payload.iconColor
    end

    SendNUIMessage({
        action = 'notify',
        id = payload.id,
        title = payload.title or '',
        description = payload.description or '',
        type = notifyType,
        color = color,
        icon = showIcons and icon or nil,
        duration = dur,
        showDuration = showDuration == true,
        position = Config.Position,
        vertical = Config.Vertical,
        maxVisible = Config.MaxVisible,
    })

    local sound = payload.sound or Config.Sound
    if sound and sound.name and sound.set then
        PlaySoundFrontend(-1, sound.name, sound.set, true)
    end
end

--- Alias okokNotify-like : Alert(title, message, time, type)
function Alert(title, message, time, nType)
    Notify({
        title = title,
        description = message,
        duration = time,
        type = nType,
    })
end

exports('Notify', Notify)
exports('Alert', Alert)

RegisterNetEvent('ox_notify:notify', function(data)
    Notify(data)
end)

RegisterNetEvent('ox_notify:Alert', function(title, message, time, nType)
    Alert(title, message, time, nType)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= resourceName then return end
    SendNUIMessage({ action = 'clear' })
end)

if Config.TestCommand and Config.TestCommand ~= '' then
    RegisterCommand(Config.TestCommand, function()
        Notify({
            title = 'Station pleine',
            description = 'Xero | Strawberry Avenue est à capacité maximale (3000L)',
            type = 'error',
            duration = 6000,
        })
        Wait(400)
        Notify({
            title = 'Station pleine',
            description = 'Xero | Great Ocean est à capacité maximale (3000L)',
            type = 'error',
            duration = 6000,
        })
        Wait(400)
        Notify({
            title = 'Livraison terminée',
            description = 'Plus de barils ou arrêt manuel',
            type = 'success',
            duration = 6000,
        })
    end, false)
end
