--[[--------------------------------------------------------------------------
    core_garage — client principal
---------------------------------------------------------------------------]]

CoreGarage = {
    garages = {},       -- [name] = data
    blips = {},
    zones = {},
    currentGarage = nil,
    mileageCache = {},  -- plate → mileage
    locale = {},
    ui = Config.UI,
    imageUrl = Config.General.vehicleImageUrl,
}

local function notify(msg, nType)
    lib.notify({
        title = _('garage'),
        description = msg,
        type = nType or 'inform',
        position = Config.Notify.position,
        duration = Config.Notify.duration,
    })
end

CoreGarage.Notify = notify

function CoreGarage.GetGarage(name)
    return CoreGarage.garages[name]
end

--- Accès local (job/gang) — validation serveur reste obligatoire
function CoreGarage.CanAccess(garage)
    if not garage or not garage.enabled then return false end
    local playerData = ESX.GetPlayerData()
    if not playerData then return false end

    if garage.job and garage.job ~= '' then
        local job = playerData.job
        if not job or job.name ~= garage.job then return false end
        if (job.grade or 0) < (garage.minGrade or garage.min_grade or 0) then return false end
    end

    if garage.gang and garage.gang ~= '' then
        local gang = playerData.gang
        local name = type(gang) == 'table' and gang.name or gang
        if name ~= garage.gang then return false end
    end

    return true
end

RegisterNetEvent('core_garage:client:setGarages', function(list)
    CoreGarage.Rebuild(list or {})
end)

CreateThread(function()
    local pack = lib.callback.await('core_garage:getLocalePack', false)
    if pack then
        CoreGarage.locale = pack.strings or {}
        CoreGarage.ui = pack.ui or Config.UI
        CoreGarage.imageUrl = pack.imageUrl or Config.General.vehicleImageUrl
    end

    local list = lib.callback.await('core_garage:getGarages', false)
    if list then
        CoreGarage.Rebuild(list)
    end
end)

--- Clés véhicule
RegisterNetEvent('core_garage:client:giveKeys', function(plate, vehicle)
    plate = GarageUtils.NormalizePlate(plate)
    if Config.General.keysExport then
        pcall(function()
            exports[Config.General.keysExport]:GiveKey(plate)
        end)
    end
    -- Hook générique pour scripts clés tiers
    TriggerEvent('vehiclekeys:client:SetOwner', plate)
    TriggerEvent('esx_core:giveVehicleKeys', plate, vehicle)
end)

--- Libelle modèle
function CoreGarage.GetModelLabel(model)
    if type(model) == 'string' then
        local hash = joaat(model)
        local display = GetDisplayNameFromVehicleModel(hash)
        local label = GetLabelText(display)
        if label and label ~= 'NULL' then return label end
        return display or model
    elseif type(model) == 'number' then
        local display = GetDisplayNameFromVehicleModel(model)
        local label = GetLabelText(display)
        if label and label ~= 'NULL' then return label end
        return display or tostring(model)
    end
    return 'Vehicle'
end

function CoreGarage.GetModelName(model)
    if type(model) == 'string' then return model:lower() end
    if type(model) == 'number' then
        local display = GetDisplayNameFromVehicleModel(model)
        if display and display ~= '' then return display:lower() end
    end
    return 'unknown'
end
