--[[--------------------------------------------------------------------------
    Client bootstrap — cache PlayerData Qbox (PHASE 1)
---------------------------------------------------------------------------]]

PoliceClient = PoliceClient or {}

local playerLoaded = false

---@return table|nil
local function rawPlayerData()
    -- qbx_core modules/playerdata.lua expose QBX.PlayerData
    if QBX and QBX.PlayerData and QBX.PlayerData.citizenid then
        return QBX.PlayerData
    end
    return nil
end

---@return table|nil
function PoliceClient.GetPlayerData()
    return rawPlayerData()
end

---@return table
function PoliceClient.GetSnapshot()
    return Police.BuildClientSnapshot(rawPlayerData())
end

---@return boolean
function PoliceClient.IsLoaded()
    return playerLoaded and rawPlayerData() ~= nil
end

---@return boolean
function PoliceClient.IsLeo()
    local data = rawPlayerData()
    return data and Police.IsLeoJob(data.job and data.job.name) or false
end

---@return boolean
function PoliceClient.IsOnDuty()
    local data = rawPlayerData()
    return data and data.job and data.job.onduty == true and Police.IsLeoJob(data.job.name) or false
end

---@param message string
---@param nType string|nil
---@param duration number|nil
function PoliceClient.Notify(message, nType, duration)
    if Config.UseOxLib and lib and lib.notify then
        lib.notify({
            title = Police.Locale('notify_title'),
            description = message,
            type = nType or 'inform',
            duration = duration or Config.Notify.duration,
            position = Config.Notify.position,
        })
        return
    end
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
end

local function markLoaded()
    playerLoaded = true
    Police.Debug('Player loaded', json.encode(PoliceClient.GetSnapshot()))
    TriggerEvent('qbx_policejob:client:playerReady', PoliceClient.GetSnapshot())
end

local function markUnloaded()
    playerLoaded = false
    TriggerEvent('qbx_policejob:client:playerUnloaded')
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', markLoaded)
RegisterNetEvent('qbx_core:client:playerLoaded', markLoaded)
RegisterNetEvent('QBCore:Client:OnPlayerUnload', markUnloaded)
RegisterNetEvent('qbx_core:client:playerUnloaded', markUnloaded)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    TriggerEvent('qbx_policejob:client:jobUpdated', job)
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(onDuty)
    TriggerEvent('qbx_policejob:client:dutyUpdated', onDuty == true)
end)

--- Callback utilitaire pour le serveur (snapshot non fiable — info UI seulement)
lib.callback.register('qbx_policejob:client:getSnapshot', function()
    return PoliceClient.GetSnapshot()
end)

CreateThread(function()
    -- Si le joueur est déjà chargé au restart de la ressource
    Wait(500)
    if rawPlayerData() then
        markLoaded()
    end
    if Config.Debug then
        PoliceClient.Notify(Police.Locale('debug_loaded'), 'inform')
    end
    Police.Debug('Client PHASE 1 ready')
end)

exports('GetSnapshot', PoliceClient.GetSnapshot)
exports('IsLeo', PoliceClient.IsLeo)
exports('IsOnDuty', PoliceClient.IsOnDuty)
exports('IsLoaded', PoliceClient.IsLoaded)
