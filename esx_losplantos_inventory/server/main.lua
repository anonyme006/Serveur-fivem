local function GetPlayer(source)
    return ESX.GetPlayerFromId(source)
end

local function GetRPName(xPlayer)
    if not xPlayer then return nil end
    if xPlayer.getName then
        return xPlayer.getName()
    end
    local first = xPlayer.get and xPlayer.get('firstName')
    local last = xPlayer.get and xPlayer.get('lastName')
    if first and last then
        return (first .. ' ' .. last)
    end
    return GetPlayerName(xPlayer.source)
end

-- Noms RP pour la liste "joueurs à proximité"
ESX.RegisterServerCallback('esx_losplantos_inventory:getPlayerNames', function(source, cb, ids)
    local names = {}
    if type(ids) ~= 'table' then
        cb(names)
        return
    end
    for _, id in ipairs(ids) do
        local xTarget = GetPlayer(tonumber(id))
        if xTarget then
            names[tostring(id)] = GetRPName(xTarget)
        end
    end
    cb(names)
end)

local function Notify(src, msg)
    TriggerClientEvent('esx_losplantos_inventory:notify', src, msg)
end

local function Refresh(src)
    TriggerClientEvent('esx_losplantos_inventory:refresh', src)
end

local function IsNear(src, targetId, maxDist)
    local ped = GetPlayerPed(src)
    local tPed = GetPlayerPed(targetId)
    if ped == 0 or tPed == 0 then return false end

    local a = GetEntityCoords(ped)
    local b = GetEntityCoords(tPed)
    local dist = #(a - b)
    return dist <= (maxDist or Config.GiveDistance or 3.0)
end

local function GetCount(xPlayer, itemName, isAccount)
    if isAccount then
        local account = xPlayer.getAccount(itemName)
        return account and account.money or 0
    end
    local item = xPlayer.getInventoryItem(itemName)
    return item and (item.count or 0) or 0
end

local function GetLabel(xPlayer, itemName, isAccount)
    if isAccount then
        local account = xPlayer.getAccount(itemName)
        return (account and account.label) or Config.ItemLabels[itemName] or itemName
    end
    local item = xPlayer.getInventoryItem(itemName)
    return (item and item.label) or Config.ItemLabels[itemName] or itemName
end

RegisterNetEvent('esx_losplantos_inventory:useItem', function(itemName)
    local src = source
    local xPlayer = GetPlayer(src)
    if not xPlayer or type(itemName) ~= 'string' then return end

    if Config.Accounts[itemName] then
        Notify(src, 'Cet objet ne peut pas être utilisé')
        return
    end

    local item = xPlayer.getInventoryItem(itemName)
    if not item or (item.count or 0) <= 0 then
        Notify(src, 'Vous n\'avez pas cet objet')
        return
    end

    -- ESX Legacy : utilise l'item enregistré (esx_basicneeds, etc.)
    if ESX.UseItem then
        ESX.UseItem(src, itemName)
    else
        TriggerEvent('esx:useItem', src, itemName)
    end

    Refresh(src)
end)

RegisterNetEvent('esx_losplantos_inventory:giveItem', function(targetId, itemName, count, isAccount)
    local src = source
    local xPlayer = GetPlayer(src)
    local xTarget = GetPlayer(targetId)

    count = math.floor(tonumber(count) or 0)
    isAccount = isAccount == true

    if not xPlayer or not xTarget or type(itemName) ~= 'string' or count < 1 then return end
    if src == targetId then return end

    if not IsNear(src, targetId, Config.GiveDistance) then
        Notify(src, 'Le joueur est trop loin')
        return
    end

    local have = GetCount(xPlayer, itemName, isAccount)
    if have < count then
        Notify(src, 'Quantité insuffisante')
        return
    end

    local label = GetLabel(xPlayer, itemName, isAccount)

    if isAccount then
        if not Config.Accounts[itemName] then return end
        xPlayer.removeAccountMoney(itemName, count, 'inventory-give')
        xTarget.addAccountMoney(itemName, count, 'inventory-receive')
    else
        local item = xPlayer.getInventoryItem(itemName)
        if item and item.canRemove == false then
            Notify(src, 'Cet objet ne peut pas être donné')
            return
        end

        if xTarget.canCarryItem and not xTarget.canCarryItem(itemName, count) then
            Notify(src, 'Le joueur ne peut pas porter cet objet')
            return
        end

        xPlayer.removeInventoryItem(itemName, count)
        xTarget.addInventoryItem(itemName, count)
    end

    Notify(src, ('Vous avez donné x%s %s'):format(count, label))
    Notify(targetId, ('Vous avez reçu x%s %s'):format(count, label))

    Refresh(src)
    Refresh(targetId)
end)

RegisterNetEvent('esx_losplantos_inventory:dropItem', function(itemName, count, isAccount)
    local src = source
    local xPlayer = GetPlayer(src)
    count = math.floor(tonumber(count) or 0)
    isAccount = isAccount == true

    if not xPlayer or type(itemName) ~= 'string' or count < 1 then return end

    local have = GetCount(xPlayer, itemName, isAccount)
    if have < count then
        Notify(src, 'Quantité insuffisante')
        return
    end

    local label = GetLabel(xPlayer, itemName, isAccount)

    if isAccount then
        if not Config.Accounts[itemName] then return end
        xPlayer.removeAccountMoney(itemName, count, 'inventory-drop')
    else
        local item = xPlayer.getInventoryItem(itemName)
        if item and item.canRemove == false then
            Notify(src, 'Cet objet ne peut pas être jeté')
            return
        end
        xPlayer.removeInventoryItem(itemName, count)
    end

    -- Prop au sol optionnel si esx_addoninventory / ox_inventory non utilisés
    -- Ici on retire simplement l'item (jet classique ESX)
    Notify(src, ('Vous avez jeté x%s %s'):format(count, label))
    Refresh(src)
end)
