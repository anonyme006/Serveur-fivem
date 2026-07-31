RegisterNetEvent('vibe_crimi_deal:server:sell', function(item, coords)
    local src = source
    local data = Config.Items[item]
    if not data then return end
    if (exports.ox_inventory:GetItemCount(src, item) or 0) < 1 then
        exports.vibe_api:Notify(src, 'Deal', 'Tu n as pas cet item.', 'error')
        return
    end
    if math.random(1, 100) > data.chance then
        exports.vibe_api:Notify(src, 'Deal', 'Le PNJ refuse.', 'error')
        if math.random(1, 100) <= Config.AlertChance and GetResourceState('vibe_dispatch') == 'started' then
            exports.vibe_dispatch:Alert('10-31', 'Deal refuse / altercation', coords)
        end
        return
    end
    exports.ox_inventory:RemoveItem(src, item, 1)
    exports.vibe_api:AddMoney(src, 'cash', data.price, 'deal')
    exports.vibe_api:Notify(src, 'Deal', ('+%s$'):format(data.price), 'success')
end)
