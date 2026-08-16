Client = Client or {}

---@param error string
---@return table
local function nuiErr(error)
    return { ok = false, error = error }
end

---@param data any
---@param message? string
---@return table
local function nuiOk(data, message)
    return { ok = true, data = data, message = message }
end

--- Normalize lib.callback results that already use { ok, data, error }.
---@param result any
---@return table
local function normalizeResult(result)
    if type(result) == 'table' and result.ok ~= nil then
        return result
    end
    return nuiOk(result)
end

---@param name string
---@param payload? table
---@return table
local function awaitCallback(name, payload)
    local ok, result = pcall(function()
        return lib.callback.await(name, false, payload)
    end)

    if not ok then
        return nuiErr(tostring(result) or 'callback_error')
    end

    return normalizeResult(result)
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
    cb(awaitCallback('qbx_shopcreator:getShop', {
        id = tonumber(data and (data.id or data.shopId)),
        shopId = tonumber(data and (data.id or data.shopId)),
    }))
end)

RegisterNUICallback('saveShop', function(data, cb)
    local result = awaitCallback('qbx_shopcreator:saveShop', { shop = data and data.shop or data })
    if result.ok and result.data and result.data.id then
        Client.ApplyShopUpdate(result.data.id, result.data, false)
    end
    cb(result)
end)

RegisterNUICallback('deleteShop', function(data, cb)
    cb(awaitCallback('qbx_shopcreator:deleteShop', {
        id = tonumber(data and (data.id or data.shopId)),
        shopId = tonumber(data and (data.id or data.shopId)),
    }))
end)

RegisterNUICallback('getInventoryItems', function(_, cb)
    cb(awaitCallback('qbx_shopcreator:getInventoryItems'))
end)

RegisterNUICallback('getAdmins', function(_, cb)
    cb(awaitCallback('qbx_shopcreator:getAdmins'))
end)

RegisterNUICallback('addAdmin', function(data, cb)
    cb(awaitCallback('qbx_shopcreator:addAdmin', {
        identifier = data and data.identifier,
        label = data and data.label,
    }))
end)

RegisterNUICallback('removeAdmin', function(data, cb)
    cb(awaitCallback('qbx_shopcreator:removeAdmin', {
        id = tonumber(data and data.id),
    }))
end)

RegisterNUICallback('getSettings', function(_, cb)
    cb(awaitCallback('qbx_shopcreator:getSettings'))
end)

RegisterNUICallback('saveSettings', function(data, cb)
    cb(awaitCallback('qbx_shopcreator:saveSettings', data or {}))
end)

RegisterNUICallback('getPlayerCoords', function(_, cb)
    cb(nuiOk(vec4ToTable(Client.GetPlayerVec4())))
end)

RegisterNUICallback('pickPosition', function(data, cb)
    local coords = Client.RunPlacementMode(data and data.label)
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

RegisterNUICallback('requestPosition', function(data, cb)
    local coords = Client.RunPlacementMode(data and data.label)
    if not coords then
        cb(nuiErr('cancelled'))
        return
    end
    cb(nuiOk(vec4ToTable(coords)))
end)

RegisterNUICallback('purchase', function(data, cb)
    local result = awaitCallback('qbx_shopcreator:purchase', {
        shopId = tonumber(data and data.shopId),
        cart = data and data.cart,
        paymentMethod = data and (data.payment or data.account or data.paymentMethod or 'cash'),
    })

    if result.ok and data and data.shopId then
        local shop = Client.GetShop(tonumber(data.shopId))
        if shop then
            SendNUIMessage({ action = 'setShop', data = shop })
        end
    end

    cb(result)
end)

RegisterNUICallback('getManagementData', function(data, cb)
    cb(awaitCallback('qbx_shopcreator:getManagementData', {
        shopId = tonumber(data and data.shopId),
    }))
end)

RegisterNUICallback('updateShopStatus', function(data, cb)
    cb(awaitCallback('qbx_shopcreator:updateShopStatus', {
        shopId = tonumber(data and data.shopId),
        is_open = data and data.is_open,
        auto_hours = data and data.auto_hours,
    }))
end)

RegisterNUICallback('depositFunds', function(data, cb)
    cb(awaitCallback('qbx_shopcreator:depositFunds', {
        shopId = tonumber(data and data.shopId),
        amount = tonumber(data and data.amount),
    }))
end)

RegisterNUICallback('withdrawFunds', function(data, cb)
    cb(awaitCallback('qbx_shopcreator:withdrawFunds', {
        shopId = tonumber(data and data.shopId),
        amount = tonumber(data and data.amount),
    }))
end)

RegisterNUICallback('createStockOrder', function(data, cb)
    cb(awaitCallback('qbx_shopcreator:createStockOrder', {
        shopId = tonumber(data and data.shopId),
        items = data and data.items,
        method = data and data.method,
    }))
end)

RegisterNUICallback('hireEmployee', function(data, cb)
    cb(awaitCallback('qbx_shopcreator:hireEmployee', {
        shopId = tonumber(data and data.shopId),
        citizenid = data and data.citizenid,
        name = data and data.name,
    }))
end)

RegisterNUICallback('fireEmployee', function(data, cb)
    cb(awaitCallback('qbx_shopcreator:fireEmployee', {
        shopId = tonumber(data and data.shopId),
        employeeId = tonumber(data and data.employeeId),
        id = tonumber(data and data.employeeId),
    }))
end)

RegisterNUICallback('updateEmployeePermissions', function(data, cb)
    cb(awaitCallback('qbx_shopcreator:updateEmployeePermissions', {
        shopId = tonumber(data and data.shopId),
        employeeId = tonumber(data and data.employeeId),
        id = tonumber(data and data.employeeId),
        permissions = data and data.permissions,
    }))
end)

RegisterNUICallback('saveCategories', function(data, cb)
    cb(awaitCallback('qbx_shopcreator:saveCategories', {
        shopId = tonumber(data and data.shopId),
        categories = data and data.categories,
    }))
end)

RegisterNUICallback('saveProducts', function(data, cb)
    cb(awaitCallback('qbx_shopcreator:saveProducts', {
        shopId = tonumber(data and data.shopId),
        products = data and data.products,
    }))
end)

RegisterNUICallback('buyShop', function(data, cb)
    local result = awaitCallback('qbx_shopcreator:buyShop', {
        shopId = tonumber(data and data.shopId),
    })
    if result.ok and result.data and result.data.id then
        Client.ApplyShopUpdate(result.data.id, result.data, false)
    end
    cb(result)
end)

RegisterNUICallback('sellShop', function(data, cb)
    local result = awaitCallback('qbx_shopcreator:sellShop', {
        shopId = tonumber(data and data.shopId),
    })
    if result.ok and result.data and result.data.id then
        Client.ApplyShopUpdate(result.data.id, result.data, false)
    end
    cb(result)
end)

RegisterNUICallback('listDeliveryJobs', function(_, cb)
    cb(awaitCallback('qbx_shopcreator:getDeliveryJobs'))
end)

RegisterNUICallback('getDeliveryJobs', function(_, cb)
    cb(awaitCallback('qbx_shopcreator:getDeliveryJobs'))
end)

RegisterNUICallback('acceptDelivery', function(data, cb)
    local result = awaitCallback('qbx_shopcreator:acceptDelivery', {
        jobId = tonumber(data and (data.jobId or data.id)),
        id = tonumber(data and (data.jobId or data.id)),
    })

    if result.ok then
        local mission = result.data
        if mission then
            Client.StartDelivery(mission)
        end
    end

    cb(result)
end)

RegisterNUICallback('completeDelivery', function(data, cb)
    cb(awaitCallback('qbx_shopcreator:completeDelivery', {
        jobId = tonumber(data and (data.jobId or data.id)),
        id = tonumber(data and (data.jobId or data.id)),
        phase = data and data.phase,
    }))
end)

RegisterNUICallback('openStorage', function(data, cb)
    Client.CloseNui()
    local shopId = tonumber(data and data.shopId)
    if shopId then
        exports.ox_inventory:openInventory('stash', Client.StashId(shopId))
    end
    cb(nuiOk())
end)

RegisterNUICallback('spawnBusinessVehicle', function(data, cb)
    local result = awaitCallback('qbx_shopcreator:takeVehicle', {
        shopId = tonumber(data and data.shopId),
        vehicleId = tonumber(data and (data.vehicleId or data.id)),
        id = tonumber(data and (data.vehicleId or data.id)),
        model = data and data.model,
    })
    cb(result)
end)

RegisterNUICallback('storeBusinessVehicle', function(data, cb)
    local ped = cache.ped or PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    local netId = vehicle ~= 0 and VehToNet(vehicle) or (data and data.netId)
    cb(awaitCallback('qbx_shopcreator:storeVehicle', {
        shopId = tonumber(data and data.shopId),
        netId = netId,
    }))
end)
