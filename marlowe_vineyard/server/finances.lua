MarloweFinances = MarloweFinances or {}

local function getSocietyBalance()
    local account = Config.SocietyAccount

    if GetResourceState('Renewed-Banking') == 'started' then
        local ok, balance = pcall(function()
            return exports['Renewed-Banking']:getAccountMoney(account)
        end)
        if ok and balance then return balance end
    end

    if GetResourceState('qb-banking') == 'started' then
        local ok, balance = pcall(function()
            return exports['qb-banking']:GetAccountBalance(account)
        end)
        if ok and balance then return balance end
    end

    if GetResourceState('qb-management') == 'started' then
        local ok, balance = pcall(function()
            return exports['qb-management']:GetAccount(account)
        end)
        if ok and balance then return balance end
    end

    local summary = MarloweDB.GetFinanceSummary()
    return summary.income - summary.expense
end

local function addSocietyMoney(amount, reason)
    local account = Config.SocietyAccount

    if GetResourceState('Renewed-Banking') == 'started' then
        local ok = pcall(function()
            exports['Renewed-Banking']:addAccountMoney(account, amount, reason)
        end)
        if ok then return true end
    end

    if GetResourceState('qb-banking') == 'started' then
        local ok = pcall(function()
            exports['qb-banking']:AddMoney(account, amount, reason)
        end)
        if ok then return true end
    end

    if GetResourceState('qb-management') == 'started' then
        local ok = pcall(function()
            exports['qb-management']:AddMoney(account, amount)
        end)
        if ok then return true end
    end

    return false
end

local function removeSocietyMoney(amount, reason)
    local account = Config.SocietyAccount

    if GetResourceState('Renewed-Banking') == 'started' then
        local ok = pcall(function()
            exports['Renewed-Banking']:removeAccountMoney(account, amount, reason)
        end)
        if ok then return true end
    end

    if GetResourceState('qb-banking') == 'started' then
        local ok = pcall(function()
            exports['qb-banking']:RemoveMoney(account, amount, reason)
        end)
        if ok then return true end
    end

    if GetResourceState('qb-management') == 'started' then
        local ok = pcall(function()
            exports['qb-management']:RemoveMoney(account, amount)
        end)
        if ok then return true end
    end

    return false
end

---@param amount number
---@param reason string
---@param citizenid? string
function MarloweFinances.AddRevenue(amount, reason, citizenid)
    MarloweDB.AddFinanceEntry({
        type = 'income',
        amount = amount,
        reason = reason,
        citizenid = citizenid,
    })
    addSocietyMoney(amount, reason)
end

---@param amount number
---@param reason string
---@param citizenid? string
function MarloweFinances.AddExpense(amount, reason, citizenid)
    MarloweDB.AddFinanceEntry({
        type = 'expense',
        amount = amount,
        reason = reason,
        citizenid = citizenid,
    })
    removeSocietyMoney(amount, reason)
end

lib.callback.register('marlowe:server:getSocietyData', function(source)
    local player, err = Marlowe.ValidatePlayer(source, Config.Permissions.Society, false)
    if not player then return nil, err end

    local summary = MarloweDB.GetFinanceSummary()
    return {
        balance = getSocietyBalance(),
        income = summary.income,
        expense = summary.expense,
        turnover = summary.turnover,
    }
end)

lib.callback.register('marlowe:server:getDomainStats', function(source)
    local player, err = Marlowe.ValidatePlayer(source, Config.Permissions.DomainManagement, false)
    if not player then return nil, err end

    local totals = MySQL.single.await([[
        SELECT
            COALESCE(SUM(grapes_harvested), 0) AS grapes_harvested,
            COALESCE(SUM(bottles_produced), 0) AS bottles_produced,
            COALESCE(SUM(deliveries_completed), 0) AS deliveries_completed,
            COALESCE(SUM(revenue_generated), 0) AS revenue_generated,
            COALESCE(SUM(hours_worked), 0) AS hours_worked
        FROM marlowe_stats
    ]]) or {}

    local summary = MarloweDB.GetFinanceSummary()
    totals.balance = getSocietyBalance()
    totals.income = summary.income
    totals.expense = summary.expense

    return totals
end)
