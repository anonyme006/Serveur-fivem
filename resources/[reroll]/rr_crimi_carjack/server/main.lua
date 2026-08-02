lib.callback.register('rr_crimi_carjack:server:hasItem', function(source)
    if not Config.HotwireItem then return true end
    return (exports.ox_inventory:GetItemCount(source, Config.HotwireItem) or 0) > 0
end)

RegisterNetEvent('rr_crimi_carjack:server:done', function(coords)
    local src = source
    if Config.HotwireItem then
        exports.ox_inventory:RemoveItem(src, Config.HotwireItem, 1)
    end
    exports.rr_api:Notify(src, 'Carjack', 'Véhicule démarré.', 'success')
    if math.random(1, 100) <= Config.AlertChance and GetResourceState('rr_dispatch') == 'started' then
        exports.rr_dispatch:Alert('10-35', 'Vol de véhicule', coords)
    end
end)
