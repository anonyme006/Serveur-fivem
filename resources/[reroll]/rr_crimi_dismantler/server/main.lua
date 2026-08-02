RegisterNetEvent('rr_crimi_dismantler:server:scrap', function(netId)
    local src = source
    if not exports.rr_api:DistCheck(src, Config.Yard, Config.Radius + 5.0) then return end
    TriggerClientEvent('rr_crimi_dismantler:client:delete', -1, netId)
    local pay = math.random(Config.Reward.min, Config.Reward.max)
    exports.ox_inventory:AddItem(src, Config.RewardItem, pay)
    exports.rr_api:Notify(src, 'Casse', ('Vehicule detruit (+%s sale)'):format(pay), 'success')
end)
