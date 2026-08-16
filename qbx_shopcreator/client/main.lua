Client = Client or {}

local function L(key)
    local locale = Locales[Config.Locale] or Locales.fr or {}
    return locale[key] or key
end

---@return table
local function nuiOk(data, message)
    return { ok = true, data = data, message = message }
end

---@param error string
local function nuiErr(error)
    return { ok = false, error = error }
end

---@param mode string
---@param payload table|nil
function Client.OpenNui(mode, payload)
    payload = payload or {}
    Client.nuiOpen = true
    Client.nuiMode = mode
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'setVisible',
        data = {
            visible = true,
            mode = mode,
            shopId = payload.shopId,
            shop = payload.shop,
            management = payload.management,
            jobs = payload.jobs,
        },
    })
end

function Client.CloseNui()
    Client.nuiOpen = false
    Client.nuiMode = nil
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'setVisible',
        data = { visible = false },
    })
end

---@return vector4
function Client.GetPlayerVec4()
    local ped = cache.ped or PlayerPedId()
    local coords = GetEntityCoords(ped)
    return vec4(coords.x, coords.y, coords.z, GetEntityHeading(ped))
end

---@param label? string
---@return vector4|nil
function Client.RunPlacementMode(label)
    if Client.placementActive then
        Client.Notify(L('invalid_data'), 'error')
        return nil
    end

    Client.placementActive = true
    local hadFocus = Client.nuiOpen

    if hadFocus then
        SetNuiFocus(false, false)
    end

    Client.Notify(label or '[E] Confirmer la position · [BACK] Annuler', 'inform')

    local confirmed = nil

    while Client.placementActive do
        Wait(0)

        lib.showTextUI(label or '[E] Confirmer la position · [BACK] Annuler', {
            position = 'top-center',
        })

        if IsControlJustReleased(0, 38) then
            confirmed = Client.GetPlayerVec4()
            break
        end

        if IsControlJustReleased(0, 177) or IsControlJustReleased(0, 200) then
            break
        end
    end

    lib.hideTextUI()
    Client.placementActive = false

    if hadFocus then
        SetNuiFocus(true, true)
    end

    return confirmed
end

---@param shopId number
---@param mode? string
function Client.OpenStorefront(shopId, mode)
    shopId = tonumber(shopId)
    if not shopId then return end

    local cached = Client.GetShop(shopId)
    if cached and not Client.IsShopOpenLocal(cached) then
        Client.Notify(L('shop_closed'), 'error')
        return
    end

    local ok, result = pcall(function()
        return lib.callback.await('qbx_shopcreator:getShop', false, { shopId = shopId, id = shopId })
    end)

    local shop = cached
    if ok and type(result) == 'table' then
        if result.ok and result.data then
            shop = result.data
        elseif result.id then
            shop = result
        end
    end

    if not shop then
        Client.Notify(L('invalid_data'), 'error')
        return
    end

    Client.ApplyShopUpdate(shopId, shop, false)

    if not Client.IsShopOpenLocal(shop) then
        Client.Notify(L('shop_closed'), 'error')
        return
    end

    Client.OpenNui(mode or 'storefront', { shopId = shopId, shop = shop })
end

---@param shopId number
function Client.OpenManagement(shopId)
    shopId = tonumber(shopId)
    if not shopId then return end

    local ok, result = pcall(function()
        return lib.callback.await('qbx_shopcreator:getManagementData', false, { shopId = shopId })
    end)

    local management = nil
    if ok and type(result) == 'table' then
        if result.ok and result.data then
            management = result.data
        elseif result.shop then
            management = result
        end
    end

    if not management or not management.shop then
        Client.Notify(L('no_permission'), 'error')
        return
    end

    Client.ApplyShopUpdate(shopId, management.shop, false)
    Client.OpenNui('management', {
        shopId = shopId,
        shop = management.shop,
        management = management,
    })
end

---@param jobs? table
function Client.OpenDeliveries(jobs)
    if not jobs then
        local ok, result = pcall(function()
            return lib.callback.await('qbx_shopcreator:getDeliveryJobs', false)
        end)
        if ok and type(result) == 'table' then
            if result.ok and result.data then
                jobs = result.data
            elseif result[1] or next(result) == nil then
                jobs = result
            end
        end
    end

    Client.OpenNui('deliveries', { jobs = jobs or {} })
end

RegisterCommand(Config.AdminCommand, function()
    local ok, result = pcall(function()
        return lib.callback.await('qbx_shopcreator:isAdmin', false)
    end)

    local allowed = false
    if ok then
        if type(result) == 'table' then
            allowed = result.ok == true and (result.data == true or result.isAdmin == true)
        else
            allowed = result == true
        end
    end

    if not allowed then
        Client.Notify(L('no_permission'), 'error')
        return
    end

    Client.OpenNui('admin', {})
end, false)

RegisterNUICallback('close', function(_, cb)
    Client.CloseNui()
    cb(nuiOk())
end)

local function positionPayload()
    local coords = Client.GetPlayerVec4()
    return { x = coords.x, y = coords.y, z = coords.z, w = coords.w }
end

lib.callback.register('qbx_shopcreator:getCurrentPosition', positionPayload)
lib.callback.register('qbx_shopcreator:client:getPlayerPosition', positionPayload)

RegisterNetEvent('qbx_shopcreator:client:openStorefront', function(shopId)
    Client.OpenStorefront(shopId, 'storefront')
end)

RegisterNetEvent('qbx_shopcreator:client:openManagement', function(shopId)
    Client.OpenManagement(shopId)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= ShopCreator.Resource then return end
    Client.CloseNui()
    lib.hideTextUI()
    if Client.CleanupBlips then Client.CleanupBlips() end
    if Client.CleanupTargets then Client.CleanupTargets() end
    if Client.CleanupNpcs then Client.CleanupNpcs() end
    if Client.CleanupBusinessVehicle then Client.CleanupBusinessVehicle() end
    if Client.StopDelivery then Client.StopDelivery(true) end
end)

exports('OpenNui', Client.OpenNui)
exports('CloseNui', Client.CloseNui)
exports('OpenStorefront', Client.OpenStorefront)
exports('OpenManagement', Client.OpenManagement)
