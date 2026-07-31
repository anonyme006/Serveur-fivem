Gruppe6Society = {}

function Gruppe6Society.GetAccountName()
    return Config.SocietyPrefix .. Config.Job
end

function Gruppe6Society.AddMoney(amount)
    local accountName = Gruppe6Society.GetAccountName()

    local affected = MySQL.update.await(
        'UPDATE addon_account_data SET money = money + ? WHERE account_name = ? AND (owner IS NULL OR owner = \'\')',
        { amount, accountName }
    )

    if not affected or affected < 1 then
        MySQL.insert.await(
            'INSERT INTO addon_account_data (account_name, money, owner) VALUES (?, ?, NULL)',
            { accountName, amount }
        )
    end

    return true
end
