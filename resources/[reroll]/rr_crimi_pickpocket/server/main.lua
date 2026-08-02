RegisterNetEvent('rr_crimi_pickpocket:server:steal', function(coords)
    local src = source
    local amount = math.random(Config.MinCash, Config.MaxCash)
    exports.rr_api:AddMoney(src, 'cash', amount, 'pickpocket')
    exports.rr_api:Notify(src, 'Pickpocket', ('+$%s'):format(amount), 'success')

    if math.random(1, 100) <= Config.AlertChance and GetResourceState('rr_dispatch') == 'started' then
        exports.rr_dispatch:Alert('10-31', 'Pickpocket signalé', coords)
    end
end)
