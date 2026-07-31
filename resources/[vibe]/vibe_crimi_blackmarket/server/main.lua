local function find(item)
    for _, it in ipairs(Config.Items) do
        if it.item == item then return it end
    end
end

RegisterNetEvent('vibe_crimi_blackmarket:server:buy', function(item)
    local src = source
    local it = find(item)
    if not it or it.sell then return end
    if not exports.vibe_api:DistCheck(src, Config.Ped.coords, 5.0) then return end
    if not exports.vibe_api:RemoveMoney(src, 'cash', it.price, 'blackmarket') then
        exports.vibe_api:Notify(src, 'Marché noir', 'Pas assez de cash.', 'error')
        return
    end
    if not exports.ox_inventory:AddItem(src, it.item, 1) then
        exports.vibe_api:AddMoney(src, 'cash', it.price, 'blackmarket-refund')
        exports.vibe_api:Notify(src, 'Marché noir', 'Inventaire plein.', 'error')
    end
end)

RegisterNetEvent('vibe_crimi_blackmarket:server:sell', function(item)
    local src = source
    local it = find(item)
    if not it or not it.sell then return end
    if not exports.vibe_api:DistCheck(src, Config.Ped.coords, 5.0) then return end
    local count = exports.ox_inventory:GetItemCount(src, it.item)
    if count < 1 then
        exports.vibe_api:Notify(src, 'Marché noir', 'Rien à vendre.', 'error')
        return
    end
    if exports.ox_inventory:RemoveItem(src, it.item, 1) then
        exports.vibe_api:AddMoney(src, 'cash', it.sellPrice, 'blackmarket-sell')
    end
end)
