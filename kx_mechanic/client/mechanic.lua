KX = KX or {}

local function loadAnim(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    return HasAnimDictLoaded(dict)
end

local function playServiceAnimation(vehicle, animation)
    local ped = PlayerPedId()
    animation = animation or Config.Animations.default

    if animation.openHood and vehicle and vehicle ~= 0 then
        SetVehicleDoorOpen(vehicle, 4, false, false)
    end

    if loadAnim(animation.dict) then
        TaskPlayAnim(ped, animation.dict, animation.clip, 3.0, 3.0, -1, animation.flag or 1, 0.0, false, false, false)
    end
end

local function stopServiceAnimation(vehicle, animation)
    ClearPedTasks(PlayerPedId())
    if animation and animation.openHood and vehicle and vehicle ~= 0 then
        SetVehicleDoorShut(vehicle, 4, false)
    end
end

local function askWheel()
    local input = lib.inputDialog('Sélection du pneu', {
        {
            type = 'select',
            label = 'Roue',
            options = {
                { value = 'fl', label = 'Avant gauche' },
                { value = 'fr', label = 'Avant droit' },
                { value = 'rl', label = 'Arrière gauche' },
                { value = 'rr', label = 'Arrière droit' },
                { value = 'all', label = 'Toutes les roues' },
            },
            required = true,
            default = 'fl',
        },
    })
    if not input then return nil end
    return input[1]
end

local function askPaint()
    local options = {}
    for i = 1, #Config.PaintColors do
        options[#options + 1] = {
            value = Config.PaintColors[i].id,
            label = Config.PaintColors[i].label,
        }
    end
    local input = lib.inputDialog('Couleur', {
        { type = 'select', label = 'Teinte', options = options, required = true },
    })
    if not input then return nil end
    return input[1]
end

local function askWheels()
    local options = {}
    for i = 1, #Config.WheelOptions do
        options[#options + 1] = {
            value = Config.WheelOptions[i].id,
            label = Config.WheelOptions[i].label,
        }
    end
    local input = lib.inputDialog('Jantes', {
        { type = 'select', label = 'Type', options = options, required = true },
    })
    if not input then return nil end
    return input[1]
end

function KX.StartDiagnose(vehicle)
    if KX.Busy then return end
    vehicle = vehicle or KX.CurrentVehicle or KX.GetClosestVehicle()
    if not vehicle then
        KX.Notify('Aucun véhicule à proximité.', 'error')
        return
    end

    if not KX.HasPerm('diagnose') then
        KX.Notify('Vous devez être mécanicien.', 'error')
        return
    end

    KX.Busy = true
    KX.CurrentVehicle = vehicle
    local plate = KX.GetVehiclePlate(vehicle)
    local animation = Config.Animations.diagnose
    playServiceAnimation(vehicle, animation)

    local success = lib.progressCircle({
        duration = Config.RepairTimes.diagnose,
        label = 'Diagnostic en cours...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
    })

    stopServiceAnimation(vehicle, animation)
    KX.Busy = false

    if not success then
        KX.Notify('Diagnostic annulé.', 'error')
        return
    end

    local result = lib.callback.await('kx_mechanic:server:diagnose', false, plate, KX.GetNativeSnapshot(vehicle))
    if not result or not result.ok then
        KX.Notify(result and result.message or 'Échec du diagnostic.', 'error')
        return
    end

    KX.Notify(result.message, 'success')

    local menu = lib.callback.await('kx_mechanic:server:getMenuData', false)
    KX.SetNui(true, {
        view = 'diagnostic',
        report = result.report,
        menu = menu,
        vehicle = {
            plate = plate,
            model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)),
            data = nil,
            native = KX.GetNativeSnapshot(vehicle),
        },
        shopName = Config.JobLabel,
    })
end

function KX.RunService(serviceId, options)
    if KX.Busy then return end
    options = options or {}

    local vehicle = KX.CurrentVehicle or KX.GetClosestVehicle()
    if not vehicle then
        KX.Notify('Aucun véhicule à proximité.', 'error')
        return
    end

    if serviceId == 'repair_tire' or serviceId == 'replace_tire' then
        if not options.wheel then
            options.wheel = askWheel()
            if not options.wheel then return end
        end
    elseif serviceId == 'paint_primary' or serviceId == 'paint_secondary' then
        if options.color == nil then
            options.color = askPaint()
            if options.color == nil then return end
        end
    elseif serviceId == 'wheels' then
        if options.wheelType == nil then
            options.wheelType = askWheels()
            if options.wheelType == nil then return end
        end
    end

    local plate = KX.GetVehiclePlate(vehicle)
    local start = lib.callback.await('kx_mechanic:server:startService', false, {
        serviceId = serviceId,
        plate = plate,
    })

    if not start or not start.ok then
        KX.Notify(start and start.message or 'Impossible de démarrer l\'intervention.', 'error')
        return
    end

    KX.Busy = true
    KX.CurrentVehicle = vehicle
    playServiceAnimation(vehicle, start.animation)

    local success = lib.progressCircle({
        duration = start.duration,
        label = start.label,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
    })

    stopServiceAnimation(vehicle, start.animation)

    if not success then
        lib.callback.await('kx_mechanic:server:cancelService', false)
        KX.Busy = false
        KX.Notify('Intervention annulée.', 'error')
        return
    end

    local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    local result = lib.callback.await('kx_mechanic:server:completeService', false, {
        completed = true,
        serviceId = serviceId,
        plate = plate,
        model = model,
        options = options,
        native = KX.GetNativeSnapshot(vehicle),
    })

    KX.Busy = false

    if not result or not result.ok then
        KX.Notify(result and result.message or 'Échec de l\'intervention.', 'error')
        return
    end

    KX.RepairNative(vehicle, serviceId, options)
    if result.vehicle then
        KX.ApplyVehicleData(vehicle, result.vehicle)
    end

    KX.Notify(result.message or 'Véhicule réparé avec succès.', 'success')
    SendNUIMessage({
        action = 'serviceCompleted',
        data = result,
    })
end

RegisterNetEvent('kx_mechanic:client:receiveInvoice', function(invoice)
    local lines = {}
    for i = 1, #invoice.items do
        lines[#lines + 1] = ('%s — %s'):format(invoice.items[i].label, Utils.FormatMoney(invoice.items[i].price))
    end

    local accept = lib.alertDialog({
        header = ('Facture %s'):format(invoice.number),
        content = ('Mécanicien : %s\n\n%s\n\nTotal : %s'):format(
            invoice.mechanic,
            table.concat(lines, '\n'),
            Utils.FormatMoney(invoice.total)
        ),
        centered = true,
        cancel = true,
        labels = { confirm = 'Payer', cancel = 'Refuser' },
    })

    local result = lib.callback.await('kx_mechanic:server:respondInvoice', false, invoice.id, accept == 'confirm')
    KX.Notify(result and result.message or 'Erreur facture.', result and result.ok and 'success' or 'error')
end)