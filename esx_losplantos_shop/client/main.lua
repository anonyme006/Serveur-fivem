local ShopOpen = false
local CurrentShop = nil
local SelectedIndex = 1
local NearbyShop = nil

local function Notify(msg)
    if ESX and ESX.ShowNotification then
        ESX.ShowNotification(msg)
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(msg)
        EndTextCommandThefeedPostTicker(false, true)
    end
end

local function GetItemImage(file)
    if not file or file == '' then
        file = 'default.svg'
    end
    return ('nui://%s/html/img/%s'):format(GetCurrentResourceName(), file)
end

local function BuildShopPayload(shop)
    local items = {}
    for _, item in ipairs(shop.items or {}) do
        items[#items + 1] = {
            name = item.name,
            label = item.label,
            price = item.price,
            type = item.type,
            image = GetItemImage(item.image),
        }
    end
    return {
        shopId = shop.id,
        label = shop.label or 'MAGASIN',
        items = items,
        selected = SelectedIndex,
    }
end

local function CloseShop()
    if not ShopOpen then return end
    ShopOpen = false
    CurrentShop = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function OpenShop(shop)
    if ShopOpen or not shop then return end
    if not ESX or not ESX.IsPlayerLoaded or not ESX.IsPlayerLoaded() then
        return
    end

    ShopOpen = true
    CurrentShop = shop
    SelectedIndex = 1
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({
        action = 'open',
        data = BuildShopPayload(shop),
    })
end

local function FindShopById(id)
    for _, shop in ipairs(Config.Shops) do
        if shop.id == id then
            return shop
        end
    end
    return nil
end

local function GetClosestShop()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closest, closestDist = nil, Config.InteractDistance + 0.01

    for _, shop in ipairs(Config.Shops) do
        for _, loc in ipairs(shop.locations or {}) do
            local dist = #(coords - loc)
            if dist < closestDist then
                closestDist = dist
                closest = shop
            end
        end
    end

    return closest, closestDist
end

RegisterCommand('losplantos_shop', function()
    if ShopOpen then
        CloseShop()
        return
    end
    local shop = GetClosestShop()
    if shop then
        OpenShop(shop)
    else
        Notify('Aucun magasin à proximité')
    end
end, false)

RegisterNUICallback('close', function(_, cb)
    CloseShop()
    cb('ok')
end)

RegisterNUICallback('select', function(data, cb)
    SelectedIndex = tonumber(data.index) or 1
    cb('ok')
end)

RegisterNUICallback('buy', function(data, cb)
    local shop = CurrentShop
    if not shop then
        shop = FindShopById(data.shopId)
    end
    if not shop then
        cb({ ok = false })
        return
    end

    local index = tonumber(data.index) or SelectedIndex
    local item = shop.items and shop.items[index]
    if not item then
        cb({ ok = false })
        return
    end

    TriggerServerEvent('esx_losplantos_shop:buy', shop.id, index)
    cb({ ok = true })
end)

RegisterNetEvent('esx_losplantos_shop:notify', function(msg)
    Notify(msg)
end)

RegisterNetEvent('esx_losplantos_shop:close', function()
    CloseShop()
end)

-- Blips
CreateThread(function()
    if not Config.ShowBlips then return end
    for _, shop in ipairs(Config.Shops) do
        if shop.blip then
            for _, loc in ipairs(shop.locations or {}) do
                local blip = AddBlipForCoord(loc.x, loc.y, loc.z)
                SetBlipSprite(blip, shop.blip.sprite or 52)
                SetBlipDisplay(blip, 4)
                SetBlipScale(blip, shop.blip.scale or 0.7)
                SetBlipColour(blip, shop.blip.color or 2)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentSubstringPlayerName(shop.blip.label or shop.label or 'Magasin')
                EndTextCommandSetBlipName(blip)
            end
        end
    end
end)

-- Markers + interaction
CreateThread(function()
    while true do
        local sleep = 750
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        NearbyShop = nil

        for _, shop in ipairs(Config.Shops) do
            for _, loc in ipairs(shop.locations or {}) do
                local dist = #(coords - loc)
                if dist < 25.0 then
                    sleep = 0
                    if Config.ShowMarker and dist < 12.0 then
                        local m = Config.Marker
                        DrawMarker(
                            m.type,
                            loc.x, loc.y, loc.z - 1.0,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            m.size.x, m.size.y, m.size.z,
                            m.color.r, m.color.g, m.color.b, m.color.a,
                            m.bobUpAndDown, m.faceCamera, 2, m.rotate, nil, nil, false
                        )
                    end
                    if dist <= Config.InteractDistance then
                        NearbyShop = shop
                    end
                end
            end
        end

        if NearbyShop and not ShopOpen then
            ESX.ShowHelpNotification('Appuyez sur ~INPUT_CONTEXT~ pour ouvrir le magasin')
            if IsControlJustReleased(0, Config.InteractKey) then
                OpenShop(NearbyShop)
            end
        end

        Wait(sleep)
    end
end)

-- Contrôles NUI
CreateThread(function()
    while true do
        if ShopOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)

            if IsDisabledControlJustPressed(0, 172) then
                SendNUIMessage({ action = 'key', key = 'up' })
            elseif IsDisabledControlJustPressed(0, 173) then
                SendNUIMessage({ action = 'key', key = 'down' })
            elseif IsDisabledControlJustPressed(0, 191) then
                SendNUIMessage({ action = 'key', key = 'enter' })
            elseif IsDisabledControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 200) then
                CloseShop()
            end
            Wait(0)
        else
            Wait(250)
        end
    end
end)

exports('OpenShop', function(shopId)
    local shop = FindShopById(shopId)
    if shop then OpenShop(shop) end
end)

exports('CloseShop', CloseShop)
exports('IsShopOpen', function()
    return ShopOpen
end)
