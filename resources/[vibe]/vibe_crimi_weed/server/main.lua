RegisterNetEvent('vibe_crimi_weed:server:pick', function(index)
    local src = source
    local zone = Config.PickZones[index]
    if not zone then return end

    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    if #(coords - zone.coords) > (zone.radius + 5.0) then return end

    local ok = exports.ox_inventory:AddItem(src, zone.item, zone.amount)
    if not ok then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Weed', description = 'Inventaire plein.', type = 'error' })
    end
end)

RegisterNetEvent('vibe_crimi_weed:server:process', function()
    local src = source
    local p = Config.Process
    local ped = GetPlayerPed(src)
    if #(GetEntityCoords(ped) - p.coords) > (p.radius + 5.0) then return end

    local count = exports.ox_inventory:GetItemCount(src, p.fromItem)
    if count < p.fromAmount then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Weed',
            description = ('Il te faut %sx %s'):format(p.fromAmount, p.fromItem),
            type = 'error',
        })
        return
    end

    if exports.ox_inventory:RemoveItem(src, p.fromItem, p.fromAmount) then
        exports.ox_inventory:AddItem(src, p.toItem, p.toAmount)
    end
end)
