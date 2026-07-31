RegisterNetEvent('vibe_farm:server:pick', function(index)
    local src = source
    local z = Config.Pick[index]
    if not z or not exports.vibe_api:DistCheck(src, z.coords, z.radius + 5.0) then return end
    exports.ox_inventory:AddItem(src, z.item, z.amount)
end)

RegisterNetEvent('vibe_farm:server:sell', function()
    local src = source
    if not exports.vibe_api:DistCheck(src, Config.Sell.coords, 5.0) then return end
    local total = 0
    for item, price in pairs(Config.Sell.prices) do
        local count = exports.ox_inventory:GetItemCount(src, item) or 0
        if count > 0 and exports.ox_inventory:RemoveItem(src, item, count) then
            total = total + (count * price)
        end
    end
    if total > 0 then
        exports.vibe_api:AddMoney(src, 'cash', total, 'farm-sell')
        exports.vibe_api:Notify(src, 'Ferme', ('Vente: $%s'):format(total), 'success')
    else
        exports.vibe_api:Notify(src, 'Ferme', 'Rien à vendre.', 'error')
    end
end)
