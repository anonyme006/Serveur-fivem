TaxiClient = TaxiClient or {}

---@return table|nil
function TaxiClient.GetPlayerData()
    return QBX and QBX.PlayerData or nil
end

---@return string|nil
function TaxiClient.GetJobName()
    local playerData = TaxiClient.GetPlayerData()
    return playerData and playerData.job and playerData.job.name or nil
end

---@return number
function TaxiClient.GetJobGrade()
    local playerData = TaxiClient.GetPlayerData()
    if not playerData or not playerData.job or not playerData.job.grade then
        return -1
    end

    return playerData.job.grade.level or 0
end

---@return boolean
function TaxiClient.IsTaxiEmployee()
    return TaxiClient.GetJobName() == Config.Company.job
end

---@param permission string|nil
---@return boolean
function TaxiClient.HasJobPermission(permission)
    if not TaxiClient.IsTaxiEmployee() then
        return false
    end

    if not permission then
        return true
    end

    return Taxi.GradeHasPermission(TaxiClient.GetJobGrade(), permission)
end

---@return boolean
function TaxiClient.IsLoggedIn()
    local playerData = TaxiClient.GetPlayerData()
    return playerData ~= nil and playerData.citizenid ~= nil
end

---@param notifyType string
---@param message string
function TaxiClient.Notify(notifyType, message)
    if Config.Notifications.provider == 'qbx_core' then
        exports.qbx_core:Notify(message, notifyType, Config.Notifications.duration)
        return
    end

    lib.notify({
        title = Config.Company.shortName,
        description = message,
        type = notifyType,
        duration = Config.Notifications.duration,
        position = Config.Notifications.position,
    })
end

---@param messageKey string
---@param notifyType string
---@param ... any
function TaxiClient.NotifyKey(messageKey, notifyType, ...)
    local template = Config.Notifications.messages[messageKey]
    if not template then return end

    local message = template
    if select('#', ...) > 0 then
        message = string.format(template, ...)
    end

    TaxiClient.Notify(notifyType, message)
end

---@param coords vector3|vector4|table
---@param blipConfig table
---@param label string|nil
---@return integer
function TaxiClient.CreateBlip(coords, blipConfig, label)
    local position = Taxi.ToVector3(coords)
    local blip = AddBlipForCoord(position.x, position.y, position.z)

    SetBlipSprite(blip, blipConfig.sprite or 1)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, blipConfig.scale or 0.8)
    SetBlipColour(blip, blipConfig.color or 0)
    SetBlipAsShortRange(blip, blipConfig.shortRange ~= false)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(label or blipConfig.label or Config.Company.shortName)
    EndTextCommandSetBlipName(blip)

    return blip
end

---@param blip integer|nil
function TaxiClient.RemoveBlip(blip)
    if blip and DoesBlipExist(blip) then
        RemoveBlip(blip)
    end
end

---@param resourceName string
---@param exportName string
---@return function|nil
function TaxiClient.GetExport(resourceName, exportName)
    if not Taxi.IsResourceStarted(resourceName) then
        return nil
    end

    local resourceExports = exports[resourceName]
    if not resourceExports or not resourceExports[exportName] then
        return nil
    end

    return function(...)
        return resourceExports[exportName](...)
    end
end

---@return table
function TaxiClient.GetState()
    return TaxiClient.State
end

TaxiClient.State = {
    ready = false,
    blips = {},
}
