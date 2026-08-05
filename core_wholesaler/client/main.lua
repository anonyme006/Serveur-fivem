--[[
    Client main — état local, helpers
]]

Client = {
    access = nil,
    cart = {},
    blips = {},
    peds = {},
    zones = {},
    activeDelivery = nil,
    activeExport = nil,
}

--- Rafraîchit les droits d'accès
function Client.RefreshAccess()
    Client.access = lib.callback.await('core_wholesaler:getAccess', false)
    return Client.access
end

--- Notification locale
---@param description string
---@param nType string|nil
function Client.Notify(description, nType)
    lib.notify({
        title = _('wholesaler'),
        description = description,
        type = nType or 'inform',
        duration = Config.Notify.duration,
        position = Config.Notify.position,
    })
end

--- Message d'erreur depuis clé locale
---@param err string|nil
function Client.NotifyErr(err)
    Client.Notify(_(err or 'error'), 'error')
end

--- Ajoute au panier
---@param item string
---@param label string
---@param price integer
---@param qty integer
---@param image string|nil
function Client.AddToCart(item, label, price, qty, image)
    qty = math.floor(tonumber(qty) or 0)
    if qty < 1 then return false end

    for _, line in ipairs(Client.cart) do
        if line.item == item then
            line.qty = line.qty + qty
            return true
        end
    end

    if #Client.cart >= Config.Orders.maxLines then
        Client.Notify(_('max_lines'), 'error')
        return false
    end

    Client.cart[#Client.cart + 1] = {
        item = item,
        label = label,
        price = price,
        qty = qty,
        image = image,
    }
    return true
end

function Client.ClearCart()
    Client.cart = {}
end

---@return integer
function Client.CartSubtotal()
    local s = 0
    for _, line in ipairs(Client.cart) do
        s = s + line.price * line.qty
    end
    return s
end

--- Spawn ped helper
---@param model string
---@param coords vector4
---@param scenario string|nil
---@return integer ped
function Client.SpawnPed(model, coords, scenario)
    local hash = joaat(model)
    lib.requestModel(hash)
    local ped = CreatePed(0, hash, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetPedFleeAttributes(ped, 0, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    if scenario then
        TaskStartScenarioInPlace(ped, scenario, 0, true)
    end
    SetModelAsNoLongerNeeded(hash)
    Client.peds[#Client.peds + 1] = ped
    return ped
end

--- Blip helper
---@param data table
---@return integer
function Client.CreateBlip(data)
    local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
    SetBlipSprite(blip, data.sprite or 1)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, data.scale or 0.8)
    SetBlipColour(blip, data.color or 1)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(data.label or 'Blip')
    EndTextCommandSetBlipName(blip)
    Client.blips[#Client.blips + 1] = blip
    return blip
end

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, ped in ipairs(Client.peds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    for _, blip in ipairs(Client.blips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
end)

-- Init accès au spawn
CreateThread(function()
    local timeout = GetGameTimer() + 60000
    while not LocalPlayer.state.isLoggedIn and GetGameTimer() < timeout do
        Wait(500)
    end
    Wait(1000)
    Client.RefreshAccess()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Client.RefreshAccess()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
    Client.RefreshAccess()
end)

RegisterNetEvent('qbx_core:client:playerLoggedOut', function()
    Client.access = nil
    Client.ClearCart()
end)
