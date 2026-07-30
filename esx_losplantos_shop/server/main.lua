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

RegisterNetEvent('esx_losplantos_shop:buy', function(shopId, index)
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
    local item = shop.items and shop.items[index]
    if not item then return end

    local price = math.floor(tonumber(item.price) or 0)
    if price < 0 then return end

    local account = Config.PayAccount or 'money'
    local money = xPlayer.getAccount(account)
    local balance = money and money.money or 0

    if balance < price then
        Notify(src, 'Vous n\'avez pas assez d\'argent')
        return
    end

    local itemType = item.type or 'item'
    local itemName = item.name

    if itemType == 'weapon' then
        if xPlayer.hasWeapon and xPlayer.hasWeapon(itemName) then
            Notify(src, 'Vous avez déjà cette arme')
            return
        end

        xPlayer.removeAccountMoney(account, price, 'shop-buy')
        xPlayer.addWeapon(itemName, 0)
        Notify(src, ('Vous avez acheté %s pour $%s'):format(item.label, price))
    else
        if xPlayer.canCarryItem and not xPlayer.canCarryItem(itemName, 1) then
            Notify(src, 'Vous ne pouvez pas porter cet objet')
            return
        end

        xPlayer.removeAccountMoney(account, price, 'shop-buy')
        xPlayer.addInventoryItem(itemName, 1)
        Notify(src, ('Vous avez acheté %s pour $%s'):format(item.label, price))
    end
end)
