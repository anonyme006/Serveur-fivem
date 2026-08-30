TaxiServer = TaxiServer or {}

---@param source number
---@return table|nil
function TaxiServer.GetPlayer(source)
    if not source or source <= 0 then return nil end
    return exports.qbx_core:GetPlayer(source)
end

---@param source number
---@return string|nil
function TaxiServer.GetCitizenId(source)
    local player = TaxiServer.GetPlayer(source)
    return player and player.PlayerData.citizenid or nil
end

---@param source number
---@return string
function TaxiServer.GetPlayerName(source)
    local player = TaxiServer.GetPlayer(source)
    if not player or not player.PlayerData.charinfo then
        return 'Inconnu'
    end

    local charinfo = player.PlayerData.charinfo
    return ('%s %s'):format(charinfo.firstname or '', charinfo.lastname or '')
end

---@param source number
---@return string|nil
function TaxiServer.GetJobName(source)
    local player = TaxiServer.GetPlayer(source)
    return player and player.PlayerData.job and player.PlayerData.job.name or nil
end

---@param source number
---@return number
function TaxiServer.GetJobGrade(source)
    local player = TaxiServer.GetPlayer(source)
    if not player or not player.PlayerData.job or not player.PlayerData.job.grade then
        return -1
    end

    return player.PlayerData.job.grade.level or 0
end

---@param source number
---@return boolean
function TaxiServer.IsTaxiEmployee(source)
    return TaxiServer.GetJobName(source) == Config.Company.job
end

---@param source number
---@param minimumGrade number|nil
---@return boolean
function TaxiServer.HasTaxiGrade(source, minimumGrade)
    if not TaxiServer.IsTaxiEmployee(source) then
        return false
    end

    if minimumGrade == nil then
        return true
    end

    return TaxiServer.GetJobGrade(source) >= minimumGrade
end

---@param source number
---@param permission string|nil
---@return boolean
function TaxiServer.HasJobPermission(source, permission)
    if not TaxiServer.IsTaxiEmployee(source) then
        return false
    end

    if not permission then
        return true
    end

    return Taxi.GradeHasPermission(TaxiServer.GetJobGrade(source), permission)
end

---@param source number
---@return boolean
function TaxiServer.IsOnDuty(source)
    local player = TaxiServer.GetPlayer(source)
    if not player or not player.PlayerData.job then
        return false
    end

    return player.PlayerData.job.onduty == true
end

---@param source number
---@param notifyType string
---@param message string
function TaxiServer.Notify(source, notifyType, message)
    if Config.Notifications.provider == 'qbx_core' then
        exports.qbx_core:Notify(source, message, notifyType, Config.Notifications.duration)
        return
    end

    TriggerClientEvent('ox_lib:notify', source, {
        title = Config.Company.shortName,
        description = message,
        type = notifyType,
        duration = Config.Notifications.duration,
        position = Config.Notifications.position,
    })
end

---@param source number
---@param messageKey string
---@param notifyType string
---@param ... any
function TaxiServer.NotifyKey(source, messageKey, notifyType, ...)
    local template = Config.Notifications.messages[messageKey]
    if not template then return end

    local message = template
    if select('#', ...) > 0 then
        message = string.format(template, ...)
    end

    TaxiServer.Notify(source, notifyType, message)
end

---@param source number
---@param action string
---@return boolean
function TaxiServer.CanPerformAction(source, action)
    if not TaxiServer.IsTaxiEmployee(source) then
        TaxiServer.NotifyKey(source, 'notTaxiJob', 'error')
        return false
    end

    if Config.Duty.requireDutyFor[action] and not TaxiServer.IsOnDuty(source) then
        TaxiServer.NotifyKey(source, 'notOnDuty', 'error')
        return false
    end

    return true
end

---@return integer
---@return integer[]
function TaxiServer.GetOnDutyTaxiDrivers()
    return exports.qbx_core:GetDutyCountJob(Config.Company.job)
end

local function validateDependencies()
    local missing = {}

    if not Taxi.IsResourceStarted('ox_lib') then
        missing[#missing + 1] = 'ox_lib'
    end

    if not Taxi.IsResourceStarted('qbx_core') then
        missing[#missing + 1] = 'qbx_core'
    end

    if not Taxi.IsResourceStarted('oxmysql') then
        missing[#missing + 1] = 'oxmysql'
    end

    if #missing > 0 then
        lib.print.error(('[qbx-taxi] Dépendances manquantes : %s'):format(table.concat(missing, ', ')))
        return false
    end

    if Config.Duty.useGlobalDuty and not Taxi.IsResourceStarted(Config.Duty.resource) then
        lib.print.warn('[qbx-taxi] qbx-duty n\'est pas démarré — l\'intégration duty sera disponible à l\'étape 3.')
    end

    return true
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= Taxi.GetResourceName() then return end

    if not validateDependencies() then
        return
    end

    Taxi.Debug('Serveur initialisé (%s)', Config.Company.name)
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    if not player or not player.PlayerData then return end

    Taxi.Debug('Joueur connecté : %s (%s)', player.PlayerData.name, player.PlayerData.job.name)
end)

exports('IsTaxiEmployee', TaxiServer.IsTaxiEmployee)
exports('HasJobPermission', TaxiServer.HasJobPermission)
exports('GetOnDutyTaxiDrivers', TaxiServer.GetOnDutyTaxiDrivers)
exports('GetPublicConfig', Taxi.GetPublicConfig)
