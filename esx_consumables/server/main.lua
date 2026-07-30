local function getDef(itemName)
    return Config.Items[itemName]
end

local function notify(src, msg)
    TriggerClientEvent('esx_consumables:client:notify', src, msg)
end

local function applyStatus(src, def)
    if GetResourceState('esx_status') ~= 'started' then
        return
    end

    local statusName = def.type == 'drink' and Config.Status.thirst or Config.Status.hunger
    local value = tonumber(def.status) or 0
    if value == 0 then return end

    TriggerClientEvent('esx_status:add', src, statusName, value)
end

local function tryRemoveItem(src, xPlayer, itemName)
    if GetResourceState('ox_inventory') == 'started' then
        local count = exports.ox_inventory:GetItemCount(src, itemName)
        if count and count > 0 then
            return exports.ox_inventory:RemoveItem(src, itemName, 1) and true or false
        end
        return false
    end

    local item = xPlayer.getInventoryItem(itemName)
    if not item or (item.count or 0) < 1 then
        return false
    end
    xPlayer.removeInventoryItem(itemName, 1)
    return true
end

CreateThread(function()
    while GetResourceState('es_extended') ~= 'started' do
        Wait(100)
    end
    Wait(500)

    for itemName, _ in pairs(Config.Items) do
        ESX.RegisterUsableItem(itemName, function(source)
            local xPlayer = ESX.GetPlayerFromId(source)
            if not xPlayer then return end

            local hasItem = false
            if GetResourceState('ox_inventory') == 'started' then
                local count = exports.ox_inventory:GetItemCount(source, itemName)
                hasItem = count and count > 0
            else
                local item = xPlayer.getInventoryItem(itemName)
                hasItem = item and (item.count or 0) > 0
            end

            if not hasItem then return end

            TriggerClientEvent('esx_consumables:client:use', source, itemName)
        end)
    end
end)

--- Appelé après progress réussie (ESX usable ou export ox)
RegisterNetEvent('esx_consumables:server:consumed', function(itemName, opts)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or type(itemName) ~= 'string' then return end

    local def = getDef(itemName)
    if not def then return end

    local skipRemove = type(opts) == 'table' and opts.skipRemove == true

    if not skipRemove then
        if not tryRemoveItem(src, xPlayer, itemName) then
            return
        end
    end

    applyStatus(src, def)
    notify(src, def.type == 'drink' and '~b~Vous êtes hydraté' or '~g~Vous êtes rassasié')
end)

RegisterNetEvent('esx_consumables:server:cancelled', function(_itemName)
    -- item non retiré
end)
