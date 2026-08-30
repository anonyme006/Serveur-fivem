function Rex.OpenTablet(page)
    if Rex.IsTabletOpen then return end
    if not select(1, Rex.GetLocalJob()) then
        Rex.Notify('Tablette', 'Vous n\'êtes pas employé d\'un restaurant.', 'error')
        return
    end
    if not Rex.Can('tablet') then
        Rex.Notify('Tablette', 'Permission refusée.', 'error')
        return
    end

    local data = lib.callback.await('rex_diner:getTabletData', false)
    if not data or not data.ok then
        Rex.Notify('Tablette', data and data.error or 'Impossible d\'ouvrir la tablette.', 'error')
        return
    end

    Rex.IsTabletOpen = true
    Rex.OnDuty = data.player.onDuty
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', page = page or 'dashboard', data = data })
end

function Rex.CloseTablet()
    if not Rex.IsTabletOpen then return end
    Rex.IsTabletOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

function Rex.ToggleService()
    local result = lib.callback.await('rex_diner:toggleService', false)
    if not result or not result.ok then
        Rex.Notify('Service', type(result and result.data) == 'string' and result.data or 'Erreur.', 'error')
        return
    end
    Rex.OnDuty = result.data and result.data.onDuty or false
    if Rex.IsTabletOpen then
        SendNUIMessage({ action = 'serviceUpdate', onDuty = Rex.OnDuty })
    end
end

RegisterCommand(Config.TabletCommand or 'restaurant', function()
    if Rex.IsTabletOpen then Rex.CloseTablet() else Rex.OpenTablet('dashboard') end
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
    Rex.CloseTablet()
    return { ok = true }
end)

cb('refresh', function()
    return lib.callback.await('rex_diner:getTabletData', false) or { ok = false }
end)

cb('toggleService', function()
    local result = lib.callback.await('rex_diner:toggleService', false)
    if result and result.ok then Rex.OnDuty = result.data and result.data.onDuty or false end
    return result or { ok = false }
end)

cb('getStats', function() return lib.callback.await('rex_diner:getStats', false) or {} end)
cb('getStock', function() return lib.callback.await('rex_diner:getStock', false) or { ok = false } end)
cb('getOrders', function() return lib.callback.await('rex_diner:getOrders', false) or { ok = false } end)
cb('getSales', function(data) return lib.callback.await('rex_diner:getSales', false, data) or { ok = false } end)
cb('getEmployees', function() return lib.callback.await('rex_diner:getEmployees', false) or { ok = false } end)
cb('getInvoices', function() return lib.callback.await('rex_diner:getInvoices', false) or { ok = false } end)
cb('getNearbyPlayers', function() return lib.callback.await('rex_diner:getNearbyPlayers', false) or {} end)
cb('processSale', function(data) return lib.callback.await('rex_diner:processSale', false, data) or { ok = false } end)
cb('createInvoice', function(data) return lib.callback.await('rex_diner:createInvoice', false, data) or { ok = false } end)
cb('createOrder', function(data) return lib.callback.await('rex_diner:createOrder', false, data) or { ok = false } end)

cb('takeDelivery', function(data)
    local result = lib.callback.await('rex_diner:takeDelivery', false, data and data.deliveryId)
    if result and result.ok and result.data then Rex.StartDelivery(result.data) end
    return result or { ok = false }
end)

cb('hireEmployee', function(data) return lib.callback.await('rex_diner:hireEmployee', false, data) or { ok = false } end)
cb('fireEmployee', function(data) return lib.callback.await('rex_diner:fireEmployee', false, data and data.citizenid) or { ok = false } end)
cb('setEmployeeGrade', function(data) return lib.callback.await('rex_diner:setEmployeeGrade', false, data) or { ok = false } end)

cb('startCraft', function(data)
    local result = lib.callback.await('rex_diner:startCraft', false, data and data.recipeId)
    if result and result.ok and result.craft then
        CreateThread(function() Rex.RunCraft(result.craft) end)
    end
    return result or { ok = false }
end)

cb('getSettings', function() return lib.callback.await('rex_diner:getSettings', false) or { ok = false } end)
cb('saveSetting', function(data)
    return lib.callback.await('rex_diner:saveSetting', false, data and data.key, data and data.value) or { ok = false }
end)

cb('notify', function(data)
    if data and data.title then Rex.Notify(data.title, data.description or '', data.type or 'inform') end
    return { ok = true }
end)
