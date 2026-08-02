RegisterNetEvent('rr_crimi_methkitchen:server:cook', function()
    local src = source
    local c = Config.Cook
    if not exports.rr_api:DistCheck(src, c.coords, 5.0) then return end
    for _, need in ipairs(c.need) do
        if (exports.ox_inventory:GetItemCount(src, need.item) or 0) < need.count then
            exports.rr_api:Notify(src, 'Meth', ('Il manque %s'):format(need.item), 'error')
            return
        end
    end
    for _, need in ipairs(c.need) do
        exports.ox_inventory:RemoveItem(src, need.item, need.count)
    end
    exports.ox_inventory:AddItem(src, c.reward.item, c.reward.count)
    exports.rr_api:Notify(src, 'Meth', 'Cuisson terminee.', 'success')
    if GetResourceState('rr_dispatch') == 'started' and math.random(1, 100) <= 25 then
        exports.rr_dispatch:Alert('10-80', 'Odeur chimique suspecte', { x = c.coords.x, y = c.coords.y, z = c.coords.z })
    end
end)

RegisterNetEvent('rr_crimi_methkitchen:server:sell', function()
    local src = source
    local s = Config.Sell
    if not exports.rr_api:DistCheck(src, s.coords, 5.0) then return end
    if (exports.ox_inventory:GetItemCount(src, s.item) or 0) < 1 then
        exports.rr_api:Notify(src, 'Meth', 'Rien a vendre.', 'error')
        return
    end
    exports.ox_inventory:RemoveItem(src, s.item, 1)
    exports.rr_api:AddMoney(src, 'cash', s.price, 'meth-sell')
    if math.random(1, 100) <= s.alertChance and GetResourceState('rr_dispatch') == 'started' then
        exports.rr_dispatch:Alert('10-31', 'Deal de meth', { x = s.coords.x, y = s.coords.y, z = s.coords.z })
    end
end)
