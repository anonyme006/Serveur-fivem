if not Config.Wallet.enabled then return end

lib.callback.register('esx_core:wallet:get', function(source)
    local xPlayer = Core.GetPlayer(source)
    if not xPlayer then return nil end

    local accounts = {}
    for _, name in ipairs(Config.Wallet.accounts or { 'money', 'bank' }) do
        local acc = xPlayer.getAccount and xPlayer.getAccount(name)
        accounts[name] = acc and acc.money or 0
    end

    if accounts.money == nil and xPlayer.getMoney then
        accounts.money = xPlayer.getMoney()
    end

    return {
        accounts = accounts,
        name = xPlayer.getName and xPlayer.getName() or GetPlayerName(source),
    }
end)
