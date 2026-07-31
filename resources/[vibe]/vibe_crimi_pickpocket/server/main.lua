RegisterNetEvent('vibe_crimi_pickpocket:server:steal', function(coords)
    local src = source
    local amount = math.random(Config.MinCash, Config.MaxCash)
    exports.vibe_api:AddMoney(src, 'cash', amount, 'pickpocket')
    exports.vibe_api:Notify(src, 'Pickpocket', ('+$%s'):format(amount), 'success')

    if math.random(1, 100) <= Config.AlertChance and GetResourceState('vibe_dispatch') == 'started' then
        exports.vibe_dispatch:Alert('10-31', 'Pickpocket signalé', coords)
    end
end)
