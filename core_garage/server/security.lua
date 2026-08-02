--[[--------------------------------------------------------------------------
    core_garage — sécurité anti-cheat
---------------------------------------------------------------------------]]

GarageSecurity = {
    --- plate → { source, netId, expires }
    outLocks = {},
    --- source → last action timestamp
    rateLimit = {},
}

local RATE_MS = 750

---@param source number
---@return boolean
function GarageSecurity.RateOk(source)
    local now = GetGameTimer()
    local last = GarageSecurity.rateLimit[source] or 0
    if now - last < RATE_MS then
        return false
    end
    GarageSecurity.rateLimit[source] = now
    return true
end

---@param plate string
---@param source number
---@param netId number|nil
function GarageSecurity.LockPlate(plate, source, netId)
    plate = GarageUtils.NormalizePlate(plate)
    GarageSecurity.outLocks[plate] = {
        source = source,
        netId = netId,
        at = os.time(),
    }
end

---@param plate string
function GarageSecurity.UnlockPlate(plate)
    plate = GarageUtils.NormalizePlate(plate)
    GarageSecurity.outLocks[plate] = nil
end

---@param plate string
---@return boolean
function GarageSecurity.IsLocked(plate)
    plate = GarageUtils.NormalizePlate(plate)
    return GarageSecurity.outLocks[plate] ~= nil
end

---@param source number
---@param coords vector3|table
---@param maxDist number|nil
---@return boolean
function GarageSecurity.IsNear(source, coords, maxDist)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false end
    local pcoords = GetEntityCoords(ped)
    local target = GarageUtils.ToVec3(coords)
    if not target then return false end
    return GarageUtils.Dist(pcoords, target) <= (maxDist or Config.General.maxDistance)
end

---@param source number
---@return boolean
function GarageSecurity.IsAdmin(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end

    if Config.Admin.acePermission and IsPlayerAceAllowed(source, Config.Admin.acePermission) then
        return true
    end

    local group = xPlayer.getGroup and xPlayer.getGroup() or 'user'
    for _, g in ipairs(Config.Admin.groups or {}) do
        if group == g then return true end
    end
    return false
end

---@param source number
---@param garage table
---@return boolean, string|nil
function GarageSecurity.CanAccessGarage(source, garage)
    if not garage then return false, 'error' end
    if not garage.enabled then return false, 'garage_disabled' end

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false, 'error' end

    if garage.job and garage.job ~= '' then
        local job = xPlayer.getJob()
        if not job or job.name ~= garage.job then
            return false, 'garage_job_required'
        end
        local grade = job.grade or 0
        if grade < (garage.min_grade or 0) then
            return false, 'garage_grade_required'
        end
    end

    if garage.gang and garage.gang ~= '' then
        local gang = xPlayer.get and xPlayer.get('gang') or nil
        local gangName = type(gang) == 'table' and gang.name or gang
        if gangName ~= garage.gang then
            return false, 'garage_gang_required'
        end
    end

    return true
end

---@param source number
---@param owner string
---@param company string|nil
---@return boolean
function GarageSecurity.IsOwnerOrCompany(source, owner, company)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    local identifier = xPlayer.getIdentifier()
    if owner == identifier then return true end

    if company and company ~= '' then
        local job = xPlayer.getJob()
        if job and job.name == company then
            return true
        end
    end
    return false
end

---@param source number
---@param netId number
---@param plate string
---@return boolean, number|nil entity
function GarageSecurity.ValidateNetVehicle(source, netId, plate)
    netId = tonumber(netId)
    if not netId then return false end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 or not DoesEntityExist(entity) then
        return false
    end

    local entPlate = GarageUtils.NormalizePlate(GetVehicleNumberPlateText(entity))
    if entPlate ~= GarageUtils.NormalizePlate(plate) then
        return false
    end

    local ownerBag = Entity(entity).state[Config.General.ownerStatebag]
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end

    -- Autorise si statebag owner match OU plaque connue en DB pour ce joueur
    if ownerBag and ownerBag ~= xPlayer.getIdentifier() then
        -- company vehicles: company statebag
        local companyBag = Entity(entity).state['garageCompany']
        local job = xPlayer.getJob()
        if not (companyBag and job and job.name == companyBag) then
            return false
        end
    end

    return true, entity
end

AddEventHandler('playerDropped', function()
    local src = source
    GarageSecurity.rateLimit[src] = nil
    for plate, lock in pairs(GarageSecurity.outLocks) do
        if lock.source == src then
            -- ne pas unlock : véhicule toujours sorti en monde
        end
    end
end)
