function Rest.OpenTablet(page)
    if Rest.IsTabletOpen then return end
    if not select(1, Rest.GetLocalJob()) then
        Rest.Notify('Tablette', 'Vous n\'êtes pas employé d\'un restaurant.', 'error')
        return
    end
    if not Rest.Can('tablet') then
        Rest.Notify('Tablette', 'Permission refusée.', 'error')
        return
    end

    local data = lib.callback.await('qbox_restaurants:getTabletData', false)
    if not data or not data.ok then
        Rest.Notify('Tablette', data and data.error or 'Impossible d\'ouvrir la tablette.', 'error')
        return
    end

    Rest.IsTabletOpen = true
    Rest.OnDuty = data.player.onDuty
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', page = page or 'dashboard', data = data })
end

function Rest.CloseTablet()
    if not Rest.IsTabletOpen then return end
    Rest.IsTabletOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

function Rest.ToggleService()
    local result = lib.callback.await('qbox_restaurants:toggleService', false)
    if not result or not result.ok then
        Rest.Notify('Service', type(result and result.data) == 'string' and result.data or 'Erreur.', 'error')
        return
    end
    Rest.OnDuty = result.data and result.data.onDuty or false
    if Rest.IsTabletOpen then
        SendNUIMessage({ action = 'serviceUpdate', onDuty = Rest.OnDuty })
    end
end

RegisterCommand(Config.TabletCommand or 'restaurant', function()
    if Rest.IsTabletOpen then Rest.CloseTablet() else Rest.OpenTablet('dashboard') end
end, false)

if Config.TabletKey and Config.TabletKey ~= '' then
    RegisterKeyMapping(Config.TabletCommand or 'restaurant', 'Ouvrir tablette restaurant', 'keyboard', Config.TabletKey)
end

local function cb(name, handler)
    RegisterNUICallback(name, function(data, respond)
        respond(handler(data) or { ok = false })
    end)
end

cb('close', function()
    Rest.CloseTablet()
    return { ok = true }
end)

cb('refresh', function()
    return lib.callback.await('qbox_restaurants:getTabletData', false) or { ok = false }
end)

cb('toggleService', function()
    local result = lib.callback.await('qbox_restaurants:toggleService', false)
    if result and result.ok then Rest.OnDuty = result.data and result.data.onDuty or false end
    return result or { ok = false }
end)

cb('getStats', function() return lib.callback.await('qbox_restaurants:getStats', false) or {} end)
cb('getStock', function() return lib.callback.await('qbox_restaurants:getStock', false) or { ok = false } end)
cb('getOrders', function() return lib.callback.await('qbox_restaurants:getOrders', false) or { ok = false } end)
cb('getSales', function(data) return lib.callback.await('qbox_restaurants:getSales', false, data) or { ok = false } end)
cb('getEmployees', function() return lib.callback.await('qbox_restaurants:getEmployees', false) or { ok = false } end)
cb('getInvoices', function() return lib.callback.await('qbox_restaurants:getInvoices', false) or { ok = false } end)
cb('getNearbyPlayers', function() return lib.callback.await('qbox_restaurants:getNearbyPlayers', false) or {} end)
cb('processSale', function(data) return lib.callback.await('qbox_restaurants:processSale', false, data) or { ok = false } end)
cb('createInvoice', function(data) return lib.callback.await('qbox_restaurants:createInvoice', false, data) or { ok = false } end)
cb('createOrder', function(data) return lib.callback.await('qbox_restaurants:createOrder', false, data) or { ok = false } end)

cb('takeDelivery', function(data)
    local result = lib.callback.await('qbox_restaurants:takeDelivery', false, data and data.deliveryId)
    if result and result.ok and result.data then Rest.StartDelivery(result.data) end
    return result or { ok = false }
end)

cb('hireEmployee', function(data) return lib.callback.await('qbox_restaurants:hireEmployee', false, data) or { ok = false } end)
cb('fireEmployee', function(data) return lib.callback.await('qbox_restaurants:fireEmployee', false, data and data.citizenid) or { ok = false } end)
cb('setEmployeeGrade', function(data) return lib.callback.await('qbox_restaurants:setEmployeeGrade', false, data) or { ok = false } end)

cb('startCraft', function(data)
    local result = lib.callback.await('qbox_restaurants:startCraft', false, data and data.recipeId)
    if result and result.ok and result.craft then
        CreateThread(function() Rest.RunCraft(result.craft) end)
    end
    return result or { ok = false }
end)

cb('getSettings', function() return lib.callback.await('qbox_restaurants:getSettings', false) or { ok = false } end)
cb('saveSetting', function(data)
    return lib.callback.await('qbox_restaurants:saveSetting', false, data and data.key, data and data.value) or { ok = false }
end)

cb('notify', function(data)
    if data and data.title then Rest.Notify(data.title, data.description or '', data.type or 'inform') end
    return { ok = true }
end)
