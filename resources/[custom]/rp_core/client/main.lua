local resourceName = GetCurrentResourceName()

local function checkDependencies()
    local missing = {}
    for i = 1, #Config.RequiredResources do
        local res = Config.RequiredResources[i]
        if GetResourceState(res) ~= 'started' then
            missing[#missing + 1] = res
            print(_('missing_dep', resourceName, res, resourceName, res))
        end
    end
    return #missing == 0
end

CreateThread(function()
    Wait(500)
    if not checkDependencies() then
        print(('[rp_core] ERROR: dépendances manquantes — fonctionnalités limitées.'))
    else
        print('[rp_core] OK — bridge Qbox actif (locale=' .. Config.Locale .. ')')
    end
end)

--- Notification unifiée (client)
---@param message string
---@param nType? string success|error|inform|warning
---@param duration? number
function Notify(message, nType, duration)
    nType = nType or 'inform'
    duration = duration or Config.NotifyDefaults.duration
    if Config.Notify == 'ox_lib' and lib and lib.notify then
        lib.notify({
            title = 'Notification',
            description = message,
            type = nType == 'info' and 'inform' or nType,
            duration = duration,
            position = Config.NotifyDefaults.position,
        })
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, true)
    end
end

exports('Notify', Notify)

RegisterNetEvent('rp_core:client:notify', function(message, nType, duration)
    Notify(message, nType, duration)
end)

--- Player loaded sync
local PlayerLoaded = false

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerLoaded = true
    TriggerEvent('rp_core:client:playerLoaded')
end)

RegisterNetEvent('qbx_core:client:playerLoggedOut', function()
    PlayerLoaded = false
    TriggerEvent('rp_core:client:playerUnloaded')
end)

exports('IsPlayerLoaded', function()
    return PlayerLoaded
end)

---@return table|nil
local function getPlayerData()
    return exports.qbx_core:GetPlayerData()
end

exports('GetPlayerData', getPlayerData)
