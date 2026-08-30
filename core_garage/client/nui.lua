--[[--------------------------------------------------------------------------
    core_garage — bridge NUI
---------------------------------------------------------------------------]]

local nuiOpen = false

local function enrichVehicles(vehicles)
    local out = {}
    for i, v in ipairs(vehicles or {}) do
        local label = v.nickname
        if not label or label == '' then
            label = CoreGarage.GetModelLabel(v.model)
        end
        local modelName = CoreGarage.GetModelName(v.model)
        out[i] = {
            id = v.id,
            plate = v.plate,
            name = label,
            modelName = modelName,
            image = (CoreGarage.imageUrl or Config.General.vehicleImageUrl):format(modelName),
            category = v.category or 'other',
            categoryLabel = GarageUtils.CategoryLabel(v.category),
            engine = v.engine,
            body = v.body,
            fuel = v.fuel,
            mileage = v.mileage,
            mileageLabel = v.mileageLabel or GarageUtils.FormatMileage(v.mileage),
            insured = v.insured,
            status = v.status,
            impoundFee = v.impoundFee,
            lastOut = v.lastOut,
            lastIn = v.lastIn,
        }
    end
    return out
end

function CoreGarage.OpenNui(data)
    if nuiOpen then return end
    nuiOpen = true
    SetNuiFocus(true, true)

    local garage = data.garage or {}
    SendNUIMessage({
        action = 'open',
        payload = {
            garage = {
                name = garage.name,
                label = garage.label,
                type = garage.type,
                impoundPrice = garage.impoundPrice,
            },
            vehicles = enrichVehicles(data.vehicles),
            locale = CoreGarage.locale,
            ui = CoreGarage.ui or Config.UI,
            categories = Config.Categories,
            isImpound = garage.type == 'impound',
        },
    })
end

function CoreGarage.CloseNui()
    if not nuiOpen then return end
    nuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterNUICallback('close', function(_, cb)
    CoreGarage.CloseNui()
    cb({ ok = true })
end)

RegisterNUICallback('takeOut', function(data, cb)
    cb({ ok = true })
    local plate = data and data.plate
    local isImpound = data and data.impound
    if not plate then return end
    CreateThread(function()
        CoreGarage.TakeOutVehicle(plate, isImpound == true)
    end)
end)

RegisterNUICallback('notify', function(data, cb)
    if data and data.message then
        CoreGarage.Notify(data.message, data.type or 'inform')
    end
    cb({ ok = true })
end)
