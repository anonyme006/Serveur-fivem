--[[
    Payment helpers — core_wholesaler
    Modes : society (compte entreprise), bank, cash
]]

Payment = {}

--- Récupère le joueur Qbox
---@param source number
---@return table|nil
function Payment.GetPlayer(source)
    return exports.qbx_core:GetPlayer(source)
end

--- Nom affiché du joueur
---@param player table
---@return string
function Payment.GetName(player)
    local ci = player.PlayerData.charinfo
    return (ci.firstname or '') .. ' ' .. (ci.lastname or '')
end

--- Retire de l'argent selon le mode
---@param source number
---@param amount integer
---@param method string 'society'|'bank'|'cash'
---@return boolean success, string|nil reason
function Payment.Charge(source, amount, method)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false, 'invalid' end

    local player = Payment.GetPlayer(source)
    if not player then return false, 'no_player' end

    local methods = Config.Payment.methods
    if method == 'cash' and methods.cash then
        local cash = player.PlayerData.money.cash or 0
        if cash < amount then return false, 'funds' end
        player.Functions.RemoveMoney('cash', amount, 'wholesaler-purchase')
        Payment.CreditWholesaler(amount)
        return true

    elseif method == 'bank' and methods.bank then
        local bank = player.PlayerData.money.bank or 0
        if bank < amount then return false, 'funds' end
        player.Functions.RemoveMoney('bank', amount, 'wholesaler-purchase')
        Payment.CreditWholesaler(amount)
        return true

    elseif method == 'society' and methods.society then
        local job = player.PlayerData.job.name
        local ok = Payment.RemoveSociety(job, amount)
        if not ok then return false, 'funds' end
        Payment.CreditWholesaler(amount)
        return true
    end

    return false, 'method'
end

--- Crédite le compte du grossiste
---@param amount integer
function Payment.CreditWholesaler(amount)
    local account = Config.Payment.wholesalerAccount
    Payment.AddSociety(account, amount)
end

--- Retire du compte société
---@param account string
---@param amount integer
---@return boolean
function Payment.RemoveSociety(account, amount)
    local banking = Config.Payment.banking

    if banking == 'renewed' then
        local bal = exports['Renewed-Banking']:getAccountMoney(account)
        if not bal or bal < amount then return false end
        return exports['Renewed-Banking']:removeAccountMoney(account, amount)

    elseif banking == 'qb-banking' then
        local bal = exports['qb-banking']:GetAccountBalance(account)
        if not bal or bal < amount then return false end
        return exports['qb-banking']:RemoveMoney(account, amount, 'wholesaler-purchase')

    elseif banking == 'qbx_management' then
        -- Fallback : compte society via management
        local ok, bal = pcall(function()
            return exports.qbx_management:GetAccount(account)
        end)
        if not ok or not bal or bal < amount then return false end
        return exports.qbx_management:RemoveMoney(account, amount)
    end

    -- Fallback silencieux (dev) : toujours OK
    Wholesaler.Debug('Payment.RemoveSociety fallback for', account, amount)
    return true
end

--- Ajoute au compte société
---@param account string
---@param amount integer
---@return boolean
function Payment.AddSociety(account, amount)
    local banking = Config.Payment.banking

    if banking == 'renewed' then
        return exports['Renewed-Banking']:addAccountMoney(account, amount)

    elseif banking == 'qb-banking' then
        return exports['qb-banking']:AddMoney(account, amount, 'wholesaler-sale')

    elseif banking == 'qbx_management' then
        local ok = pcall(function()
            exports.qbx_management:AddMoney(account, amount)
        end)
        return ok
    end

    Wholesaler.Debug('Payment.AddSociety fallback for', account, amount)
    return true
end

--- Paie un joueur (récompense livraison / export)
---@param source number
---@param amount integer
---@param reason string
function Payment.PayPlayer(source, amount, reason)
    local player = Payment.GetPlayer(source)
    if not player then return false end
    player.Functions.AddMoney('bank', math.floor(amount), reason or 'wholesaler-reward')
    return true
end
