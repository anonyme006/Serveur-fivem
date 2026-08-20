KX = KX or {}

function KX.OpenMechanicMenu(defaultCategory)
    if not KX.CanWork() then
        KX.Notify('Vous devez être mécanicien.', 'error')
        return
    end

    local menu = lib.callback.await('kx_mechanic:server:getMenuData', false)
    if not menu then
        KX.Notify('Impossible d\'ouvrir le menu.', 'error')
        return
    end

    local vehicle = KX.CurrentVehicle or KX.GetClosestVehicle()
    local vehicleInfo = nil
    if vehicle then
        local plate = KX.GetVehiclePlate(vehicle)
        local data = lib.callback.await('kx_mechanic:server:getVehicleData', false, plate, KX.GetNativeSnapshot(vehicle))
        vehicleInfo = {
            plate = plate,
            model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)),
            data = data,
            native = KX.GetNativeSnapshot(vehicle),
        }
    end

    KX.SetNui(true, {
        view = 'menu',
        menu = menu,
        vehicle = vehicleInfo,
        defaultCategory = defaultCategory or 'repair',
        shopName = Config.JobLabel,
    })
end

RegisterNUICallback('close', function(_, cb)
    KX.SetNui(false)
    cb({ ok = true })
end)

RegisterNUICallback('runService', function(data, cb)
    CreateThread(function()
        if data and data.serviceId then
            KX.RunService(data.serviceId, data.options or {})
        end
    end)
    cb({ ok = true })
end)

RegisterNUICallback('diagnose', function(_, cb)
    CreateThread(function()
        KX.StartDiagnose(KX.CurrentVehicle or KX.GetClosestVehicle())
    end)
    cb({ ok = true })
end)

RegisterNUICallback('openStash', function(_, cb)
    KX.SetNui(false)
    Wait(100)
    exports.ox_inventory:openInventory('stash', Config.Locations.stash.id)
    cb({ ok = true })
end)

RegisterNUICallback('getNearbyPlayers', function(_, cb)
    local players = lib.callback.await('kx_mechanic:server:getNearbyPlayers', false) or {}
    cb({ ok = true, players = players })
end)

RegisterNUICallback('createInvoice', function(data, cb)
    local result = lib.callback.await('kx_mechanic:server:createInvoice', false, data)
    cb(result or { ok = false, message = 'Erreur' })
end)

RegisterNUICallback('getOrders', function(_, cb)
    local result = lib.callback.await('kx_mechanic:server:getOrders', false)
    cb(result or { ok = false })
end)

RegisterNUICallback('createOrder', function(data, cb)
    local result = lib.callback.await('kx_mechanic:server:createOrder', false, data and data.product, data and data.quantity)
    cb(result or { ok = false })
end)

RegisterNUICallback('getEmployees', function(_, cb)
    local result = lib.callback.await('kx_mechanic:server:getEmployees', false)
    cb(result or { ok = false })
end)

RegisterNUICallback('hireEmployee', function(data, cb)
    local result = lib.callback.await('kx_mechanic:server:hireEmployee', false, data and data.targetId)
    cb(result or { ok = false })
end)

RegisterNUICallback('fireEmployee', function(data, cb)
    local result = lib.callback.await('kx_mechanic:server:fireEmployee', false, data and data.citizenid)
    cb(result or { ok = false })
end)

RegisterNUICallback('setEmployeeGrade', function(data, cb)
    local result = lib.callback.await('kx_mechanic:server:setEmployeeGrade', false, data and data.citizenid, data and data.grade)
    cb(result or { ok = false })
end)

RegisterNUICallback('getDashboard', function(_, cb)
    local result = lib.callback.await('kx_mechanic:server:getDashboard', false)
    cb(result or { ok = false })
end)

RegisterNUICallback('getHistory', function(data, cb)
    local result = lib.callback.await('kx_mechanic:server:getHistory', false, data and data.plate)
    cb(result or { ok = false })
end)

RegisterNUICallback('getStockLog', function(_, cb)
    local result = lib.callback.await('kx_mechanic:server:getStockLog', false)
    cb(result or { ok = false })
end)

RegisterNUICallback('notify', function(data, cb)
    if data and data.message then
        KX.Notify(data.message, data.type or 'inform')
    end
    cb({ ok = true })
end)