local function GetPlayer(source)
    return ESX.GetPlayerFromId(source)
end

local function Notify(src, msg)
    TriggerClientEvent('esx_losplantos_shop:notify', src, msg)
end

local function FindShop(shopId)
    for _, shop in ipairs(Config.Shops) do
        if shop.id == shopId then
            return shop
        end
    end
    return nil
end

local function PlayerNearShop(src, shop)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    local coords = GetEntityCoords(ped)
    local maxDist = (Config.InteractDistance or 2.0) + 2.0

    for _, loc in ipairs(shop.locations or {}) do
        if #(coords - loc) <= maxDist then
            return true
        end
    end
    return false
end

RegisterNetEvent('esx_losplantos_shop:buy', function(shopId, index, count)
    local src = source
    local xPlayer = GetPlayer(src)
    if not xPlayer then return end

    local shop = FindShop(shopId)
    if not shop then return end

    if not PlayerNearShop(src, shop) then
        Notify(src, 'Vous êtes trop loin du magasin')
        return
    end

    index = tonumber(index)
    count = math.floor(tonumber(count) or 1)
    local maxQty = Config.MaxQuantity or 100

    if count < 1 then count = 1 end
    if count > maxQty then count = maxQty end

    local item = shop.items and shop.items[index]
    if not item then return end

    local unitPrice = math.floor(tonumber(item.price) or 0)
    if unitPrice < 0 then return end

    local total = unitPrice * count
    local account = Config.PayAccount or 'money'
    local money = xPlayer.getAccount(account)
    local balance = money and money.money or 0

    if balance < total then
        Notify(src, 'Vous n\'avez pas assez d\'argent')
        return
    end

    local itemType = item.type or 'item'
    local itemName = item.name

    if itemType == 'weapon' then
        -- Une seule arme à la fois
        if count > 1 then count = 1 end
        total = unitPrice

        if xPlayer.hasWeapon and xPlayer.hasWeapon(itemName) then
            Notify(src, 'Vous avez déjà cette arme')
            return
        end

        if balance < total then
            Notify(src, 'Vous n\'avez pas assez d\'argent')
            return
        end

        xPlayer.removeAccountMoney(account, total, 'shop-buy')
        xPlayer.addWeapon(itemName, 0)
        Notify(src, ('Vous avez acheté %s pour $%s'):format(item.label, total))
    else
        if xPlayer.canCarryItem and not xPlayer.canCarryItem(itemName, count) then
            Notify(src, 'Vous ne pouvez pas porter cet objet')
            return
        end

        xPlayer.removeAccountMoney(account, total, 'shop-buy')
        xPlayer.addInventoryItem(itemName, count)
        Notify(src, ('Vous avez acheté x%s %s pour $%s'):format(count, item.label, total))
    end
end)
