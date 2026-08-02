RegisterNetEvent('rr_sellfish:server:sell', function()
    local src = source
    if not exports.rr_api:DistCheck(src, Config.Ped.coords, 5.0) then return end
    local total = 0
    for item, price in pairs(Config.Prices) do
        local count = exports.ox_inventory:GetItemCount(src, item) or 0
        if count > 0 and exports.ox_inventory:RemoveItem(src, item, count) then
            total = total + count * price
        end
    end
    if total > 0 then
        exports.rr_api:AddMoney(src, 'cash', total, 'sellfish')
        exports.rr_api:Notify(src, 'Poissonnerie', ('+$%s'):format(total), 'success')
    else
        exports.rr_api:Notify(src, 'Poissonnerie', 'Tu n\'as pas de poisson.', 'error')
    end
end)
