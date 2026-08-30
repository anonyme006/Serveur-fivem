if Config.Modules and Config.Modules.core == false then return end

if not Config.Wallet.enabled then return end

lib.callback.register('qbx_ressources:wallet:get', function(source)
    local player = Core.GetPlayer(source)
    if not player then return nil end

    local accounts = {}
    for _, name in ipairs(Config.Wallet.accounts or { 'cash', 'bank' }) do
        local acc = Core.NormalizeAccount(name)
        accounts[name] = Core.GetMoney(source, acc)
        if name == 'cash' then accounts.money = accounts[name] end
    end

    return {
        accounts = accounts,
        name = Core.GetPlayerName(source),
    }
end)
