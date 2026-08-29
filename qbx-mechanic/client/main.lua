local isReady = false
local playerLoaded = false

---@return boolean
local function dependenciesReady()
    if GetResourceState('ox_lib') ~= 'started' then
        Utils.Debug('ox_lib not started')
        return false
    end

    if GetResourceState('ox_target') ~= 'started' then
        Utils.Debug('ox_target not started')
        return false
    end

    if GetResourceState('qbx_core') ~= 'started' then
        Utils.Debug('qbx_core not started')
        return false
    end

    return true
end

local function registerCommands()
    if not Config.Commands then return end

    if Config.Commands.mechanic and Config.Commands.mechanic.enabled then
        RegisterCommand(Config.Commands.mechanic.name, function()
            if not Framework.IsMechanic() then
                Utils.Notify(nil, 'Vous devez être mécanicien.', 'error')
                return
            end
            TriggerEvent('qbx-mechanic:client:openMenu')
        end, false)
    end

    if Config.Commands.diagnostic and Config.Commands.diagnostic.enabled then
        RegisterCommand(Config.Commands.diagnostic.name, function()
            if not Framework.IsMechanic() then
                Utils.Notify(nil, 'Vous devez être mécanicien.', 'error')
                return
            end
            TriggerEvent('qbx-mechanic:client:runDiagnostic')
        end, false)
    end

    if Config.Commands.repair and Config.Commands.repair.enabled then
        RegisterCommand(Config.Commands.repair.name, function()
            if not Framework.IsMechanic() then
                Utils.Notify(nil, 'Vous devez être mécanicien.', 'error')
                return
            end
            TriggerEvent('qbx-mechanic:client:openRepairMenu')
        end, false)
    end
end

local function onPlayerLoaded()
    playerLoaded = true
    Utils.Debug('Player loaded — grade:', Framework.GetGrade())
    TriggerEvent('qbx-mechanic:client:playerReady')
end

local function bootstrap()
    if not dependenciesReady() then
        Utils.Debug('Dependencies missing — retry in 2s')
        SetTimeout(2000, bootstrap)
        return
    end

    registerCommands()
    isReady = true

    Utils.Debug('Client bootstrap complete')

    if QBX and QBX.PlayerData and QBX.PlayerData.citizenid then
        onPlayerLoaded()
    end
end

--- Événements Qbox
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', onPlayerLoaded)
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    playerLoaded = false
    TriggerEvent('qbx-mechanic:client:playerUnload')
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    Utils.Debug('Job updated:', job and job.name, job and job.grade and job.grade.level)
    TriggerEvent('qbx-mechanic:client:jobUpdated', job)
end)

--- Callback interne — étapes suivantes brancheront ici
RegisterNetEvent('qbx-mechanic:client:openMenu', function()
    Utils.Notify(nil, 'Menu mécanicien — implémentation étape 6 (NUI).', 'inform')
end)

RegisterNetEvent('qbx-mechanic:client:runDiagnostic', function()
    Utils.Notify(nil, 'Diagnostic — implémentation étape 4.', 'inform')
end)

RegisterNetEvent('qbx-mechanic:client:openRepairMenu', function()
    Utils.Notify(nil, 'Réparations — implémentation étape 5.', 'inform')
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    bootstrap()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
end)

--- Export client — vérification UX (serveur = source de vérité)
exports('IsMechanic', function(minGrade)
    return Framework.IsMechanic(nil, minGrade)
end)

exports('IsReady', function()
    return isReady and playerLoaded
end)

CreateThread(bootstrap)
