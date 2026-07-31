RegisterNetEvent('vibe_crimi_weed:server:pick', function(index)
    local src = source
    local zone = Config.PickZones[index]
    if not zone then return end
    if not exports.vibe_api:DistCheck(src, zone.coords, zone.radius + 5.0) then return end
    local ok = exports.ox_inventory:AddItem(src, zone.item, zone.amount)
    if not ok then
        exports.vibe_api:Notify(src, 'Weed', 'Inventaire plein.', 'error')
    end
end)

RegisterNetEvent('vibe_crimi_weed:server:process', function()
    local src = source
    local p = Config.Process
    if not exports.vibe_api:DistCheck(src, p.coords, p.radius + 5.0) then return end
    local count = exports.ox_inventory:GetItemCount(src, p.fromItem)
    if count < p.fromAmount then
        exports.vibe_api:Notify(src, 'Weed', ('Il te faut %sx %s'):format(p.fromAmount, p.fromItem), 'error')
        return
    end
    if exports.ox_inventory:RemoveItem(src, p.fromItem, p.fromAmount) then
        exports.ox_inventory:AddItem(src, p.toItem, p.toAmount)
    end
end)

RegisterNetEvent('vibe_crimi_weed:server:sell', function()
    local src = source
    local s = Config.Sell
    if not exports.vibe_api:DistCheck(src, s.coords, 5.0) then return end
    local count = exports.ox_inventory:GetItemCount(src, s.item) or 0
    if count < 1 then
        exports.vibe_api:Notify(src, 'Weed', 'Rien a vendre.', 'error')
        return
    end
    if exports.ox_inventory:RemoveItem(src, s.item, 1) then
        exports.vibe_api:AddMoney(src, 'cash', s.price, 'weed-sell')
        exports.vibe_api:Notify(src, 'Weed', ('+%s$'):format(s.price), 'success')
        if math.random(1, 100) <= (s.alertChance or 0) and GetResourceState('vibe_dispatch') == 'started' then
            exports.vibe_dispatch:Alert('10-31', 'Deal de drogue signale', { x = s.coords.x, y = s.coords.y, z = s.coords.z })
        end
    end
end)
