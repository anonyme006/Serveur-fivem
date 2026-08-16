Client = Client or {}
Client.blips = Client.blips or {}

local function L(key)
    local locale = Locales[Config.Locale] or Locales.fr or {}
    return locale[key] or key
end

---@param shop table|nil
local function removeBlipForShop(shopId)
    local handle = Client.blips[shopId]
    if handle and DoesBlipExist(handle) then
        RemoveBlip(handle)
    end
    Client.blips[shopId] = nil
end

---@param shop table
local function createBlipForShop(shop)
    local shopId = shop.id
    removeBlipForShop(shopId)

    if not shop.enabled or shop.enabled == 0 or shop.enabled == false then
        return
    end

    local blipCfg = shop.blip or {}
    local enabled = blipCfg.enabled
    if enabled == nil then
        enabled = Config.Blip.enabled
    end
    if enabled == false or enabled == 0 then
        return
    end

    local coords = Client.GetPrimaryCoords(shop)
    if not coords then return end

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, tonumber(blipCfg.sprite) or Config.Blip.sprite or 52)
    SetBlipColour(blip, tonumber(blipCfg.color) or Config.Blip.color or 2)
    SetBlipScale(blip, tonumber(blipCfg.scale) or Config.Blip.scale or 0.75)
    SetBlipAsShortRange(blip, true)
    SetBlipDisplay(blip, 4)

    local name = blipCfg.name or shop.name or 'Shop'
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(name)
    EndTextCommandSetBlipName(blip)

    Client.blips[shopId] = blip
end

function Client.RebuildBlip(shopId)
    local shop = Client.GetShop(shopId)
    if shop then
        createBlipForShop(shop)
    else
        removeBlipForShop(shopId)
    end
end

function Client.RebuildAllBlips()
    for shopId in pairs(Client.blips) do
        removeBlipForShop(shopId)
    end

    for _, shop in pairs(Client.shops) do
        createBlipForShop(shop)
    end
end

function Client.CleanupBlips()
    for shopId in pairs(Client.blips) do
        removeBlipForShop(shopId)
    end
end

AddEventHandler('qbx_shopcreator:internal:shopUpdated', function(shopId)
    Client.RebuildBlip(shopId)
end)

AddEventHandler('qbx_shopcreator:internal:shopRemoved', function(shopId)
    removeBlipForShop(shopId)
end)

AddEventHandler('qbx_shopcreator:internal:shopsSynced', function()
    Client.RebuildAllBlips()
end)

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(500)
    end
    Wait(1500)
    Client.RebuildAllBlips()
end)
