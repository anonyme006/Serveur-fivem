local function GetPlayer(source)
    return ESX.GetPlayerFromId(source)
end

RegisterNetEvent('esx_losplantos_inventory:useItem', function(itemName)
    local src = source
    local xPlayer = GetPlayer(src)
    if not xPlayer or type(itemName) ~= 'string' then return end

    local item = xPlayer.getInventoryItem(itemName)
    if not item or (item.count or 0) <= 0 then return end

    -- ESX Legacy / esx_basicneeds / usable items
    ESX.UseItem(src, itemName)
    TriggerClientEvent('esx_losplantos_inventory:refresh', src)
end)

RegisterNetEvent('esx_losplantos_inventory:giveItem', function(targetId, itemName, count)
    local src = source
    local xPlayer = GetPlayer(src)
    local xTarget = GetPlayer(targetId)

    count = tonumber(count) or 1
    if not xPlayer or not xTarget or type(itemName) ~= 'string' or count < 1 then return end

    local item = xPlayer.getInventoryItem(itemName)
    if not item or (item.count or 0) < count then
        xPlayer.showNotification('Quantité insuffisante')
        return
    end

    if xTarget.canCarryItem and not xTarget.canCarryItem(itemName, count) then
        xPlayer.showNotification('Le joueur ne peut pas porter cet objet')
        return
    end

    xPlayer.removeInventoryItem(itemName, count)
    xTarget.addInventoryItem(itemName, count)

    xPlayer.showNotification(('Vous avez donné x%s %s'):format(count, item.label or itemName))
    xTarget.showNotification(('Vous avez reçu x%s %s'):format(count, item.label or itemName))

    TriggerClientEvent('esx_losplantos_inventory:refresh', src)
    TriggerClientEvent('esx_losplantos_inventory:refresh', targetId)
end)

RegisterNetEvent('esx_losplantos_inventory:dropItem', function(itemName, count)
    local src = source
    local xPlayer = GetPlayer(src)
    count = tonumber(count) or 1

    if not xPlayer or type(itemName) ~= 'string' or count < 1 then return end

    local item = xPlayer.getInventoryItem(itemName)
    if not item or (item.count or 0) < count then
        xPlayer.showNotification('Quantité insuffisante')
        return
    end

    xPlayer.removeInventoryItem(itemName, count)
    xPlayer.showNotification(('Vous avez jeté x%s %s'):format(count, item.label or itemName))
    TriggerClientEvent('esx_losplantos_inventory:refresh', src)
end)
