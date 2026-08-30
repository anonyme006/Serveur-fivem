MarloweGarage = MarloweGarage or {}

local spawnedVehicle = nil

local function notify(message, nType)
    lib.notify({
        title = Config.Label,
        description = message,
        type = nType or 'inform',
    })
end

local function canUseGarage()
    return QBX.PlayerData
        and QBX.PlayerData.job.name == Config.Job
        and QBX.PlayerData.job.grade.level >= Config.Garage.MinGrade
end

local function spawnVehicle(model)
    if not canUseGarage() then
        notify(Config.Notifications.NoGrade, 'error')
        return
    end

    if spawnedVehicle and DoesEntityExist(spawnedVehicle) then
        notify('Rangez d\'abord le véhicule actuel.', 'error')
        return
    end

    lib.requestModel(model)
    local spawn = Config.Garage.Spawn
    local vehicle = CreateVehicle(model, spawn.x, spawn.y, spawn.z, spawn.w, true, false)

    if vehicle <= 0 then
        notify('Impossible de sortir le véhicule.', 'error')
        return
    end

    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleNumberPlateText(vehicle, 'MARLOWE')
    TaskWarpPedIntoVehicle(cache.ped, vehicle, -1)
    TriggerEvent('vehiclekeys:client:SetOwner', GetVehicleNumberPlateText(vehicle))

    spawnedVehicle = vehicle
    notify('Véhicule sorti du garage.', 'success')
end

function MarloweGarage.OpenSpawnMenu()
    if not canUseGarage() then
        notify(Config.Notifications.NoGrade, 'error')
        return
    end

    local vehicleMenu = MenuV:CreateMenu(
        'Sortir un véhicule',
        'Véhicules disponibles',
        'bottomright',
        Config.Colors.Red,
        Config.Colors.Green,
        Config.Colors.Blue,
        Config.Menu.Size,
        false,
        'menuv',
        'marlowe_vineyard',
        Config.Menu.Theme
    )

    local playerGrade = QBX.PlayerData.job.grade.level

    for i = 1, #Config.Garage.Vehicles do
        local entry = Config.Garage.Vehicles[i]
        local disabled = playerGrade < entry.grade

        vehicleMenu:AddButton({
            icon = '🚐',
            label = entry.label,
            description = disabled and 'Grade insuffisant' or ('Modèle: %s'):format(entry.model),
            disabled = disabled,
        }):On('select', function()
            spawnVehicle(joaat(entry.model))
            MenuV:CloseMenu(vehicleMenu)
        end)
    end

    MenuV:OpenMenu(vehicleMenu)
end

function MarloweGarage.StoreVehicle()
    if not canUseGarage() then
        notify(Config.Notifications.NoGrade, 'error')
        return
    end

    local ped = cache.ped
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle <= 0 then
        vehicle = spawnedVehicle
    end

    if not vehicle or vehicle <= 0 or not DoesEntityExist(vehicle) then
        notify('Aucun véhicule à ranger.', 'error')
        return
    end

    local garageCoords = Config.Vineyard.GaragePoint.coords
    local vehCoords = GetEntityCoords(vehicle)
    if #(vehCoords - garageCoords) > Config.Garage.StoreRadius then
        notify('Approchez-vous du garage.', 'error')
        return
    end

    SetEntityAsMissionEntity(vehicle, true, true)
    DeleteVehicle(vehicle)

    if spawnedVehicle == vehicle then
        spawnedVehicle = nil
    end

    notify('Véhicule rangé.', 'success')
end

CreateThread(function()
    exports.ox_target:addSphereZone({
        coords = Config.Vineyard.GaragePoint.coords,
        radius = Config.Vineyard.GaragePoint.radius,
        debug = false,
        options = {
            {
                name = 'marlowe_garage',
                icon = 'fa-solid fa-warehouse',
                label = 'Ouvrir le garage',
                canInteract = function()
                    return canUseGarage()
                end,
                onSelect = function()
                    MarloweMenu.OpenGarage()
                end,
                distance = 2.5,
            },
        },
    })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if spawnedVehicle and DoesEntityExist(spawnedVehicle) then
        DeleteVehicle(spawnedVehicle)
    end
end)
