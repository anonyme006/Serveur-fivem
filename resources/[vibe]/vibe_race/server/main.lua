RegisterNetEvent('vibe_race:server:finish', function()
    local src = source
    exports.vibe_api:AddMoney(src, 'cash', Config.Reward, 'race')
    exports.vibe_api:Notify(src, 'Course', ('Termine ! +$%s'):format(Config.Reward), 'success')
end)
