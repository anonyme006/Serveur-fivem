RegisterNetEvent('vibe_crimi_whitening:server:wash', function(index, amount)
    local src = source
    local loc = Config.Locations[index]
    if not loc then return end
    amount = math.floor(tonumber(amount) or 0)
    if amount < Config.MinAmount or amount > Config.MaxAmount then return end
    if not exports.vibe_api:DistCheck(src, loc.coords, 5.0) then return end

    local count = exports.ox_inventory:GetItemCount(src, Config.BlackMoneyItem) or 0
    if count < amount then
        exports.vibe_api:Notify(src, 'Blanchiment', 'Pas assez d\'argent sale.', 'error')
        return
    end
    if exports.ox_inventory:RemoveItem(src, Config.BlackMoneyItem, amount) then
        local clean = math.floor(amount * (1.0 - (loc.fee or 0.3)))
        exports.vibe_api:AddMoney(src, 'cash', clean, 'whitening')
        exports.vibe_api:Notify(src, 'Blanchiment', ('Tu récupères $%s propres.'):format(clean), 'success')
    end
end)
