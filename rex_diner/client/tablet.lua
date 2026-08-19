function RexDiner.OpenTablet(page)
    if RexDiner.IsTabletOpen then return end

    local key = select(1, RexDiner.GetLocalJob())
    if not key then
        RexDiner.Notify('Tablette', 'Vous n\'êtes pas employé d\'un restaurant.', 'error')
        return
    end

    if not RexDiner.HasLocalPermission('tablet') then
        RexDiner.Notify('Tablette', 'Permission refusée.', 'error')
        return
    end

    local data = lib.callback.await('rex_diner:getTabletData', false)
    if not data or not data.ok then
        RexDiner.Notify('Tablette', data and data.error or 'Impossible d\'ouvrir la tablette.', 'error')
        return
    end

    RexDiner.IsTabletOpen = true
    RexDiner.OnDuty = data.player.onDuty
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        page = page or 'dashboard',
        data = data,
    })
end

function RexDiner.CloseTablet()
    if not RexDiner.IsTabletOpen then return end
    RexDiner.IsTabletOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

function RexDiner.ToggleService()
    local result = lib.callback.await('rex_diner:toggleService', false)
    if not result or not result.ok then
        local msg = 'Erreur service.'
        if type(result) == 'table' then
            msg = type(result.data) == 'string' and result.data or msg
        end
        RexDiner.Notify('Service', msg, 'error')
        return
    end
    RexDiner.OnDuty = result.data and result.data.onDuty or false
    if RexDiner.IsTabletOpen then
        SendNUIMessage({
            action = 'serviceUpdate',
            onDuty = RexDiner.OnDuty,
            service = result.data,
        })
    end
end

RegisterCommand(Config.TabletCommand or 'diner', function()
    if RexDiner.IsTabletOpen then
        RexDiner.CloseTablet()
    else
        RexDiner.OpenTablet('dashboard')
    end
end, false)

if Config.TabletKey and Config.TabletKey ~= '' then
    RegisterKeyMapping(Config.TabletCommand or 'diner', 'Ouvrir la tablette restaurant', 'keyboard', Config.TabletKey)
end

RegisterNUICallback('close', function(_, cb)
    RexDiner.CloseTablet()
    cb({ ok = true })
end)

RegisterNUICallback('refresh', function(_, cb)
    local data = lib.callback.await('rex_diner:getTabletData', false)
    cb(data or { ok = false })
end)

RegisterNUICallback('toggleService', function(_, cb)
    local result = lib.callback.await('rex_diner:toggleService', false)
    if result and result.ok then
        RexDiner.OnDuty = result.data and result.data.onDuty or false
    end
    cb(result or { ok = false })
end)

RegisterNUICallback('getStats', function(_, cb)
    cb(lib.callback.await('rex_diner:getStats', false) or {})
end)

RegisterNUICallback('getStock', function(_, cb)
    cb(lib.callback.await('rex_diner:getStock', false) or { ok = false })
end)

RegisterNUICallback('getOrders', function(_, cb)
    cb(lib.callback.await('rex_diner:getOrders', false) or { ok = false })
end)

RegisterNUICallback('getSales', function(data, cb)
    cb(lib.callback.await('rex_diner:getSales', false, data) or { ok = false })
end)

RegisterNUICallback('getEmployees', function(_, cb)
    cb(lib.callback.await('rex_diner:getEmployees', false) or { ok = false })
end)

RegisterNUICallback('getInvoices', function(_, cb)
    cb(lib.callback.await('rex_diner:getInvoices', false) or { ok = false })
end)

RegisterNUICallback('getNearbyPlayers', function(_, cb)
    cb(lib.callback.await('rex_diner:getNearbyPlayers', false) or {})
end)

RegisterNUICallback('processSale', function(data, cb)
    cb(lib.callback.await('rex_diner:processSale', false, data) or { ok = false })
end)

RegisterNUICallback('createInvoice', function(data, cb)
    cb(lib.callback.await('rex_diner:createInvoice', false, data) or { ok = false })
end)

RegisterNUICallback('createOrder', function(data, cb)
    cb(lib.callback.await('rex_diner:createOrder', false, data) or { ok = false })
end)

RegisterNUICallback('takeDelivery', function(data, cb)
    local result = lib.callback.await('rex_diner:takeDelivery', false, data and data.deliveryId)
    if result and result.ok and result.data then
        RexDiner.StartDelivery(result.data)
    end
    cb(result or { ok = false })
end)

RegisterNUICallback('hireEmployee', function(data, cb)
    cb(lib.callback.await('rex_diner:hireEmployee', false, data) or { ok = false })
end)

RegisterNUICallback('fireEmployee', function(data, cb)
    cb(lib.callback.await('rex_diner:fireEmployee', false, data and data.citizenid) or { ok = false })
end)

RegisterNUICallback('setEmployeeGrade', function(data, cb)
    cb(lib.callback.await('rex_diner:setEmployeeGrade', false, data) or { ok = false })
end)

RegisterNUICallback('startCraft', function(data, cb)
    local result = lib.callback.await('rex_diner:startCraft', false, data and data.recipeId)
    if result and result.ok and result.craft then
        CreateThread(function()
            RexDiner.RunCraft(result.craft)
        end)
    end
    cb(result or { ok = false })
end)

RegisterNUICallback('getSettings', function(_, cb)
    cb(lib.callback.await('rex_diner:getSettings', false) or { ok = false })
end)

RegisterNUICallback('saveSetting', function(data, cb)
    cb(lib.callback.await('rex_diner:saveSetting', false, data and data.key, data and data.value) or { ok = false })
end)

RegisterNUICallback('notify', function(data, cb)
    if data and data.title then
        RexDiner.Notify(data.title, data.description or '', data.type or 'inform')
    end
    cb({ ok = true })
end)
