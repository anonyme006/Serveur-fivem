lib.callback.register('vibe_panelv2:server:allowed', function(source)
    return IsPlayerAceAllowed(source, Config.Ace)
end)

RegisterNetEvent('vibe_panelv2:server:giveCash', function(amount)
    local src = source
    if not IsPlayerAceAllowed(src, Config.Ace) then return end
    amount = math.floor(tonumber(amount) or 0)
    if amount < 1 then return end
    exports.vibe_api:AddMoney(src, 'cash', amount, 'admin-panel')
end)

RegisterNetEvent('vibe_panelv2:server:announce', function(msg)
    local src = source
    if not IsPlayerAceAllowed(src, Config.Ace) then return end
    TriggerClientEvent('ox_lib:notify', -1, {
        title = 'Annonce',
        description = tostring(msg or ''):sub(1, 200),
        type = 'inform',
        duration = 10000,
    })
end)
