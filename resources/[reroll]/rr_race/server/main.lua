RegisterNetEvent('rr_race:server:finish', function()
    local src = source
    exports.rr_api:AddMoney(src, 'cash', Config.Reward, 'race')
    exports.rr_api:Notify(src, 'Course', ('Termine ! +$%s'):format(Config.Reward), 'success')
end)
