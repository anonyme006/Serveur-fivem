Client = Client or {}

---@return table
local function nuiOk(data, message)
    return { ok = true, data = data, message = message }
end

---@param error string
local function nuiErr(error)
    return { ok = false, error = error }
end

---@param name string
---@param data? table
---@return table
local function awaitCallback(name, ...)
    local ok, result = pcall(function()
        return lib.callback.await(name, false, ...)
    end)

    if not ok then
        return nuiErr(result or 'callback_error')
    end

    if type(result) == 'table' and result.ok == false then
        return result
    end

    return nuiOk(result)
end

---@param name string
---@param data? table
local function triggerServer(name, data)
    TriggerServerEvent(name, data or {})
    return nuiOk()
end

---@param vec vector4|table
---@return table
local function vec4ToTable(vec)
    return {
        x = vec.x,
        y = vec.y,
        z = vec.z,
        w = vec.w or vec.h or 0.0,
    }
end

RegisterNUICallback('getShops', function(_, cb)
    cb(awaitCallback('qbx_shopcreator:getShops'))
end)

RegisterNUICallback('getShop', function(data, cb)
    local shopId = tonumber(data.id or data.shopId)
    cb(awaitCallback('qbx_shopcreator:getShop', shopId))
end)

RegisterNUICallback('saveShop', function(data, cb)
    local result = awaitCallback('qbx_shopcreator:saveShop', data.shop)
    if result.ok and result.data and result.data.id then
        Client.ApplyShopUpdate(result.data.id, result.data, false)
    end
    cb(result)
end)

RegisterNUICallback('deleteShop', function(data, cb)
    local shopId = tonumber(data.id or data.shopId)
    cb(awaitCallback('qbx_shopcreator:deleteShop', shopId))
end)

RegisterNUICallback('getInventoryItems', function(_, cb)
    cb(awaitCallback('qbx_shopcreator:getInventoryItems'))
end)

RegisterNUICallback('getAdmins', function(_, cb)
    cb(awaitCallback('qbx_shopcreator:getAdmins'))
end)

RegisterNUICallback('addAdmin', function(data, cb)
    cb(awaitCallback('qbx_shopcreator:addAdmin', data.identifier, data.label))
end)

RegisterNUICallback('removeAdmin', function(data, cb)
    cb(awaitCallback('qbx_shopcreator:removeAdmin', tonumber(data.id)))
end)

RegisterNUICallback('getSettings', function(_, cb)
    cb(awaitCallback('qbx_shopcreator:getSettings'))
end)

RegisterNUICallback('saveSettings', function(data, cb)
    cb(awaitCallback('qbx_shopcreator:saveSettings', data))
end)

RegisterNUICallback('getPlayerCoords', function(_, cb)
    cb(nuiOk(vec4ToTable(Client.GetPlayerVec4())))
end)

RegisterNUICallback('pickPosition', function(data, cb)
    local label = data and data.label
    local coords = Client.RunPlacementMode(label)
    if not coords then
        cb(nuiErr('cancelled'))
        return
    end
    cb(nuiOk(vec4ToTable(coords)))
end)

RegisterNUICallback('useCurrentPosition', function(data, cb)
    local coords = Client.RunPlacementMode(data and data.type and ('Position: ' .. tostring(data.type)))
    if not coords then
        cb(nuiErr('cancelled'))
        return
    end
    cb(nuiOk(vec4ToTable(coords)))
end)

RegisterNUICallback('purchase', function(data, cb)
    local result = awaitCallback(
        'qbx_shopcreator:purchase',
        tonumber(data.shopId),
        data.cart,
        data.payment or data.account or 'cash'
    )

    if result.ok and data.shopId then
        local shop = Client.GetShop(tonumber(data.shopId))
        if shop then
            SendNUIMessage({ action = 'setShop', data = shop })
        end
    end

    cb(result)
end)

RegisterNUICallback('getManagementData', function(data, cb)
    cb(awaitCallback('qbx_shopcreator:getManagementData', tonumber(data.shopId)))
end)

RegisterNUICallback('updateShopStatus', function(data, cb)
    cb(awaitCallback(
        'qbx_shopcreator:updateShopStatus',
        tonumber(data.shopId),
        data.is_open,
        data.auto_hours
    ))
end)

RegisterNUICallback('depositFunds', function(data, cb)
    cb(awaitCallback('qbx_shopcreator:depositFunds', tonumber(data.shopId), tonumber(data.amount)))
end)

RegisterNUICallback('withdrawFunds', function(data, cb)
    cb(awaitCallback('qbx_shopcreator:withdrawFunds', tonumber(data.shopId), tonumber(data.amount)))
end)

RegisterNUICallback('createStockOrder', function(data, cb)
    cb(awaitCallback(
        'qbx_shopcreator:createStockOrder',
        tonumber(data.shopId),
        data.items,
        data.method
    ))
end)

RegisterNUICallback('hireEmployee', function(data, cb)
    cb(awaitCallback(
        'qbx_shopcreator:hireEmployee',
        tonumber(data.shopId),
        data.citizenid,
        data.name
    ))
end)

RegisterNUICallback('fireEmployee', function(data, cb)
    cb(awaitCallback('qbx_shopcreator:fireEmployee', tonumber(data.shopId), tonumber(data.employeeId)))
end)

RegisterNUICallback('updateEmployeePermissions', function(data, cb)
    cb(awaitCallback(
        'qbx_shopcreator:updateEmployeePermissions',
        tonumber(data.shopId),
        tonumber(data.employeeId),
        data.permissions
    ))
end)

RegisterNUICallback('saveCategories', function(data, cb)
    cb(awaitCallback('qbx_shopcreator:saveCategories', tonumber(data.shopId), data.categories))
end)

RegisterNUICallback('saveProducts', function(data, cb)
    cb(awaitCallback('qbx_shopcreator:saveProducts', tonumber(data.shopId), data.products))
end)

RegisterNUICallback('buyShop', function(data, cb)
    local result = awaitCallback('qbx_shopcreator:buyShop', tonumber(data.shopId))
    if result.ok and result.data then
        Client.ApplyShopUpdate(result.data.id, result.data, false)
    end
    cb(result)
end)

RegisterNUICallback('sellShop', function(data, cb)
    local result = awaitCallback('qbx_shopcreator:sellShop', tonumber(data.shopId))
    if result.ok and result.data then
        Client.ApplyShopUpdate(result.data.id, result.data, false)
    end
    cb(result)
end)

RegisterNUICallback('listDeliveryJobs', function(_, cb)
    cb(awaitCallback('qbx_shopcreator:listDeliveryJobs'))
end)

RegisterNUICallback('getDeliveryJobs', function(_, cb)
    cb(awaitCallback('qbx_shopcreator:listDeliveryJobs'))
end)

RegisterNUICallback('acceptDelivery', function(data, cb)
    local jobId = tonumber(data.jobId or data.id)
    local result = awaitCallback('qbx_shopcreator:acceptDelivery', jobId)

    if result.ok then
        local mission = result.data or result.mission
        if mission then
            Client.StartDelivery(mission)
        end
    end

    cb(result)
end)

RegisterNUICallback('completeDelivery', function(data, cb)
    cb(awaitCallback(
        'qbx_shopcreator:completeDelivery',
        tonumber(data.jobId or data.id),
        data.phase
    ))
end)

RegisterNUICallback('openStorage', function(data, cb)
    Client.CloseNui()
    local shopId = tonumber(data.shopId)
    if shopId then
        exports.ox_inventory:openInventory('stash', Client.StashId(shopId))
    end
    cb(nuiOk())
end)

RegisterNUICallback('spawnBusinessVehicle', function(data, cb)
    TriggerEvent('qbx_shopcreator:client:garage:open', tonumber(data.shopId), data.model)
    cb(nuiOk(nil, Locales[Config.Locale] and Locales[Config.Locale].vehicle_spawned or 'vehicle_spawned'))
end)

RegisterNUICallback('storeBusinessVehicle', function(data, cb)
    TriggerEvent('qbx_shopcreator:client:garage:return', tonumber(data.shopId))
    cb(nuiOk())
end)

RegisterNUICallback('requestPosition', function(data, cb)
    local coords = Client.RunPlacementMode(data and data.label)
    if not coords then
        cb(nuiErr('cancelled'))
        return
    end
    cb(nuiOk(vec4ToTable(coords)))
end)
