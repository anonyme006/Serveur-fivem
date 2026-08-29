ClientUtils = {}

---@return number|nil vehicle
---@return number distance
function ClientUtils.GetClosestVehicle(maxDistance)
    local ped = cache and cache.ped or PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicle = lib.getClosestVehicle(coords, maxDistance or Config.MaxActionDistance, false)
    if not vehicle or vehicle == 0 then
        return nil, maxDistance or Config.MaxActionDistance
    end
    local distance = #(coords - GetEntityCoords(vehicle))
    return vehicle, distance
end

---@param vehicle number
---@return string
function ClientUtils.GetVehicleDisplayName(vehicle)
    if not vehicle or vehicle == 0 then return 'Inconnu' end
    local model = GetEntityModel(vehicle)
    local label = GetLabelText(GetDisplayNameFromVehicleModel(model))
    if label == 'NULL' or label == '' then
        label = GetDisplayNameFromVehicleModel(model)
    end
    return label
end

---@param vehicle number
---@return string
function ClientUtils.GetVehiclePlate(vehicle)
    if not vehicle or vehicle == 0 then return 'N/A' end
    return Utils.NormalizePlate(GetVehicleNumberPlateText(vehicle)) or 'N/A'
end

---@param mechanicId string|nil
---@return string|nil
function ClientUtils.GetPlayerMechanicId(mechanicId)
    if mechanicId then return mechanicId end
    return LocalPlayer.state.mechanicShop
end

---@return boolean
function ClientUtils.CanUseMechanicActions()
    return Framework.IsMechanic()
end

return ClientUtils
