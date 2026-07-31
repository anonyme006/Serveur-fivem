--[[
    esx_banque — Server
    Comptes personnels (ESX bank) + comptes entreprise (esx_addonaccount)
]]

local function ensureTables()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `banque_transactions` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `account_type` VARCHAR(32) NOT NULL DEFAULT 'personal',
            `account_id` VARCHAR(64) NOT NULL,
            `identifier` VARCHAR(64) NULL,
            `actor_name` VARCHAR(64) NULL,
            `type` VARCHAR(32) NOT NULL,
            `label` VARCHAR(128) NOT NULL,
            `amount` INT NOT NULL,
            `balance_after` INT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            INDEX `idx_account` (`account_type`, `account_id`),
            INDEX `idx_identifier` (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `banque_favorites` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `owner` VARCHAR(64) NOT NULL,
            `name` VARCHAR(64) NOT NULL,
            `account_number` VARCHAR(64) NOT NULL,
            `target_identifier` VARCHAR(64) NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            INDEX `idx_owner` (`owner`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `banque_account_numbers` (
            `identifier` VARCHAR(64) NOT NULL,
            `account_number` VARCHAR(64) NOT NULL,
            PRIMARY KEY (`identifier`),
            UNIQUE KEY `uk_account_number` (`account_number`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
end

CreateThread(function()
    Wait(500)
    ensureTables()
end)

local function getPlayerName(xPlayer)
    return xPlayer.getName and xPlayer.getName() or GetPlayerName(xPlayer.source) or 'Inconnu'
end

local function generateAccountNumber(identifier)
    local existing = MySQL.scalar.await(
        'SELECT account_number FROM banque_account_numbers WHERE identifier = ?',
        { identifier }
    )
    if existing then
        return existing
    end

    local number
    repeat
        local digits = ''
        for _ = 1, 10 do
            digits = digits .. tostring(math.random(0, 9))
        end
        number = (Config.AccountNumberPrefix or 'US7FL') .. digits
        local taken = MySQL.scalar.await(
            'SELECT 1 FROM banque_account_numbers WHERE account_number = ?',
            { number }
        )
        if not taken then break end
    until false

    MySQL.insert.await(
        'INSERT INTO banque_account_numbers (identifier, account_number) VALUES (?, ?)',
        { identifier, number }
    )
    return number
end

local function findIdentifierByAccountNumber(accountNumber)
    return MySQL.scalar.await(
        'SELECT identifier FROM banque_account_numbers WHERE account_number = ?',
        { accountNumber }
    )
end

local function logTransaction(accountType, accountId, identifier, actorName, txType, label, amount, balanceAfter)
    MySQL.insert.await([[
        INSERT INTO banque_transactions
            (account_type, account_id, identifier, actor_name, type, label, amount, balance_after)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        accountType, accountId, identifier, actorName, txType, label, amount, balanceAfter
    })
end

local function getHistory(accountType, accountId)
    return MySQL.query.await([[
        SELECT id, type, label, amount, balance_after, actor_name, created_at
        FROM banque_transactions
        WHERE account_type = ? AND account_id = ?
        ORDER BY created_at DESC
        LIMIT ?
    ]], { accountType, accountId, Config.MaxHistory or 50 }) or {}
end

local function getFavorites(identifier)
    return MySQL.query.await(
        'SELECT id, name, account_number, target_identifier FROM banque_favorites WHERE owner = ? ORDER BY name ASC',
        { identifier }
    ) or {}
end

local function getSocietyAccount(jobName)
    if not Config.UseSocietyAccount then return nil end
    if not jobName or Config.ExcludedJobs[jobName] then return nil end

    local accountName = Config.SocietyPrefix .. jobName

    -- addon_account_data: account_name, money, owner (pas de name/label)
    -- addon_account: name, label, shared
    local result = MySQL.single.await([[
        SELECT a.name, a.label, COALESCE(d.money, 0) AS money
        FROM addon_account a
        LEFT JOIN addon_account_data d
            ON d.account_name = a.name AND (d.owner IS NULL OR d.owner = '')
        WHERE a.name = ?
        LIMIT 1
    ]], { accountName })

    if not result then
        -- Compte société non déclaré dans addon_account
        local dataOnly = MySQL.single.await(
            'SELECT account_name, money FROM addon_account_data WHERE account_name = ? LIMIT 1',
            { accountName }
        )
        if dataOnly then
            return {
                name = accountName,
                label = jobName,
                money = tonumber(dataOnly.money) or 0,
                exists = true,
            }
        end

        return {
            name = accountName,
            label = jobName,
            money = 0,
            exists = false,
        }
    end

    return {
        name = accountName,
        label = result.label or jobName,
        money = tonumber(result.money) or 0,
        exists = true,
    }
end

local function setSocietyMoney(accountName, amount)
    local affected = MySQL.update.await(
        'UPDATE addon_account_data SET money = ? WHERE account_name = ? AND (owner IS NULL OR owner = \'\')',
        { amount, accountName }
    )
    if not affected or affected < 1 then
        MySQL.insert.await(
            'INSERT INTO addon_account_data (account_name, money, owner) VALUES (?, ?, NULL)',
            { accountName, amount }
        )
    end
end

local function addSocietyMoney(accountName, amount)
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
end

local function removeSocietyMoney(accountName, amount)
    MySQL.update.await(
        'UPDATE addon_account_data SET money = money - ? WHERE account_name = ? AND (owner IS NULL OR owner = \'\') AND money >= ?',
        { amount, accountName, amount }
    )
end

local function canManageBusiness(xPlayer, action)
    local grade = xPlayer.job and xPlayer.job.grade or 0
    if action == 'withdraw' then
        return grade >= (Config.BusinessWithdrawMinGrade or 0)
    end
    if action == 'transfer' then
        return grade >= (Config.BusinessTransferMinGrade or 0)
    end
    return true -- deposit
end

local function buildPlayerData(xPlayer)
    local identifier = xPlayer.identifier
    local accountNumber = generateAccountNumber(identifier)
    local bank = xPlayer.getAccount('bank')
    local cash = xPlayer.getAccount('money')
    local bankMoney = bank and bank.money or 0
    local cashMoney = cash and cash.money or 0

    local personal = {
        id = identifier,
        type = 'personal',
        name = getPlayerName(xPlayer),
        accountNumber = accountNumber,
        balance = bankMoney,
        cash = cashMoney,
    }

    local accounts = { personal }
    local business = nil

    if xPlayer.job and not Config.ExcludedJobs[xPlayer.job.name] then
        local society = getSocietyAccount(xPlayer.job.name)
        if society then
            business = {
                id = society.name,
                type = 'business',
                name = xPlayer.job.label or society.label,
                accountNumber = 'ENT-' .. string.upper(xPlayer.job.name),
                balance = society.money,
                job = xPlayer.job.name,
                grade = xPlayer.job.grade,
                gradeLabel = xPlayer.job.grade_label or tostring(xPlayer.job.grade),
                canWithdraw = canManageBusiness(xPlayer, 'withdraw'),
                canTransfer = canManageBusiness(xPlayer, 'transfer'),
                canDeposit = true,
                exists = society.exists,
            }
            accounts[#accounts + 1] = business
        end
    end

    local total = bankMoney + (business and business.balance or 0)

    return {
        playerName = getPlayerName(xPlayer),
        identifier = identifier,
        totalBalance = total,
        accounts = accounts,
        personal = personal,
        business = business,
        favorites = getFavorites(identifier),
        history = {
            personal = getHistory('personal', identifier),
            business = business and getHistory('business', business.id) or {},
        },
    }
end

local function parseAmount(value)
    local n = tonumber(value)
    if not n then return nil end
    n = math.floor(math.abs(n))
    if n < (Config.MinAmount or 1) then return nil end
    if Config.MaxAmount and n > Config.MaxAmount then return nil end
    return n
end

-- ─── Callbacks ───────────────────────────────────────────────

ESX.RegisterServerCallback('esx_banque:getData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb(nil)
        return
    end
    cb(buildPlayerData(xPlayer))
end)

ESX.RegisterServerCallback('esx_banque:getHistory', function(source, cb, payload)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb({ transactions = {} })
        return
    end

    payload = payload or {}
    local accountType = payload.accountType or 'personal'
    local accountId

    if accountType == 'business' then
        if not xPlayer.job or Config.ExcludedJobs[xPlayer.job.name] then
            cb({ transactions = {} })
            return
        end
        accountId = Config.SocietyPrefix .. xPlayer.job.name
    else
        accountId = xPlayer.identifier
    end

    cb({ transactions = getHistory(accountType, accountId) })
end)

ESX.RegisterServerCallback('esx_banque:deposit', function(source, cb, payload)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb({ ok = false, error = Translate('player_not_found') })
        return
    end

    local amount = parseAmount(payload and payload.amount)
    if not amount then
        cb({ ok = false, error = Translate('invalid_amount') })
        return
    end

    local cash = xPlayer.getAccount('money')
    if not cash or cash.money < amount then
        cb({ ok = false, error = Translate('not_enough_cash') })
        return
    end

    local accountType = (payload and payload.accountType) or 'personal'
    local actor = getPlayerName(xPlayer)

    if accountType == 'business' then
        if not xPlayer.job or Config.ExcludedJobs[xPlayer.job.name] then
            cb({ ok = false, error = Translate('no_permission') })
            return
        end

        local society = getSocietyAccount(xPlayer.job.name)
        if not society or not society.exists then
            cb({ ok = false, error = Translate('no_permission') })
            return
        end

        xPlayer.removeAccountMoney('money', amount, 'banque_deposit_business')
        addSocietyMoney(society.name, amount)
        local newBal = society.money + amount
        logTransaction('business', society.name, xPlayer.identifier, actor, 'deposit',
            ('Dépôt entreprise — %s'):format(actor), amount, newBal)

        cb({ ok = true, amount = amount, data = buildPlayerData(xPlayer) })
        return
    end

    xPlayer.removeAccountMoney('money', amount, 'banque_deposit')
    xPlayer.addAccountMoney('bank', amount, 'banque_deposit')
    local bank = xPlayer.getAccount('bank')
    logTransaction('personal', xPlayer.identifier, xPlayer.identifier, actor, 'deposit',
        'Dépôt', amount, bank and bank.money or 0)

    cb({ ok = true, amount = amount, data = buildPlayerData(xPlayer) })
end)

ESX.RegisterServerCallback('esx_banque:withdraw', function(source, cb, payload)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb({ ok = false, error = Translate('player_not_found') })
        return
    end

    local amount = parseAmount(payload and payload.amount)
    if not amount then
        cb({ ok = false, error = Translate('invalid_amount') })
        return
    end

    local accountType = (payload and payload.accountType) or 'personal'
    local actor = getPlayerName(xPlayer)

    if accountType == 'business' then
        if not canManageBusiness(xPlayer, 'withdraw') then
            cb({ ok = false, error = Translate('no_permission') })
            return
        end

        local society = getSocietyAccount(xPlayer.job.name)
        if not society or not society.exists or society.money < amount then
            cb({ ok = false, error = Translate('not_enough_bank') })
            return
        end

        removeSocietyMoney(society.name, amount)
        xPlayer.addAccountMoney('money', amount, 'banque_withdraw_business')
        local newBal = society.money - amount
        logTransaction('business', society.name, xPlayer.identifier, actor, 'withdraw',
            ('Retrait entreprise — %s'):format(actor), -amount, newBal)

        cb({ ok = true, amount = amount, data = buildPlayerData(xPlayer) })
        return
    end

    local bank = xPlayer.getAccount('bank')
    if not bank or bank.money < amount then
        cb({ ok = false, error = Translate('not_enough_bank') })
        return
    end

    xPlayer.removeAccountMoney('bank', amount, 'banque_withdraw')
    xPlayer.addAccountMoney('money', amount, 'banque_withdraw')
    bank = xPlayer.getAccount('bank')
    logTransaction('personal', xPlayer.identifier, xPlayer.identifier, actor, 'withdraw',
        'Retrait', -amount, bank and bank.money or 0)

    cb({ ok = true, amount = amount, data = buildPlayerData(xPlayer) })
end)

ESX.RegisterServerCallback('esx_banque:transfer', function(source, cb, payload)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb({ ok = false, error = Translate('player_not_found') })
        return
    end

    local amount = parseAmount(payload and payload.amount)
    if not amount then
        cb({ ok = false, error = Translate('invalid_amount') })
        return
    end

    local targetNumber = payload and payload.targetAccount
    local targetId = payload and payload.targetId
    local accountType = (payload and payload.accountType) or 'personal'
    local actor = getPlayerName(xPlayer)

    -- Resolve target player
    local targetIdentifier = targetId
    if (not targetIdentifier or targetIdentifier == '') and targetNumber and targetNumber ~= '' then
        targetIdentifier = findIdentifierByAccountNumber(targetNumber)
    end

    if not targetIdentifier then
        -- Try online player by server id
        local sid = tonumber(payload and payload.targetServerId)
        if sid then
            local xTarget = ESX.GetPlayerFromId(sid)
            if xTarget then
                targetIdentifier = xTarget.identifier
            end
        end
    end

    if not targetIdentifier then
        cb({ ok = false, error = Translate('player_not_found') })
        return
    end

    if accountType == 'personal' and targetIdentifier == xPlayer.identifier then
        cb({ ok = false, error = Translate('same_account') })
        return
    end

    local xTarget = ESX.GetPlayerFromIdentifier(targetIdentifier)
    local targetName = xTarget and getPlayerName(xTarget) or 'Joueur'

    if accountType == 'business' then
        if not canManageBusiness(xPlayer, 'transfer') then
            cb({ ok = false, error = Translate('no_permission') })
            return
        end

        local society = getSocietyAccount(xPlayer.job.name)
        if not society or not society.exists or society.money < amount then
            cb({ ok = false, error = Translate('not_enough_bank') })
            return
        end

        removeSocietyMoney(society.name, amount)

        if xTarget then
            xTarget.addAccountMoney('bank', amount, 'banque_transfer_business')
        else
            -- Offline: update users.accounts JSON bank
            local row = MySQL.single.await('SELECT accounts FROM users WHERE identifier = ?', { targetIdentifier })
            if not row then
                addSocietyMoney(society.name, amount) -- rollback
                cb({ ok = false, error = Translate('player_not_found') })
                return
            end
            local accounts = json.decode(row.accounts or '{}') or {}
            accounts.bank = (tonumber(accounts.bank) or 0) + amount
            MySQL.update.await('UPDATE users SET accounts = ? WHERE identifier = ?', {
                json.encode(accounts), targetIdentifier
            })
        end

        local newBal = society.money - amount
        logTransaction('business', society.name, xPlayer.identifier, actor, 'transfer',
            ('Virement vers %s — %s'):format(targetName, actor), -amount, newBal)
        logTransaction('personal', targetIdentifier, xPlayer.identifier, actor, 'transfer_in',
            ('Virement de %s (%s)'):format(xPlayer.job.label or 'Entreprise', actor), amount, nil)

        if xTarget then
            TriggerClientEvent('esx_banque:notify', xTarget.source,
                ('Vous avez reçu $%s de %s'):format(amount, xPlayer.job.label or actor), 'success')
        end

        cb({ ok = true, amount = amount, data = buildPlayerData(xPlayer) })
        return
    end

    -- Personal transfer
    local bank = xPlayer.getAccount('bank')
    if not bank or bank.money < amount then
        cb({ ok = false, error = Translate('not_enough_bank') })
        return
    end

    xPlayer.removeAccountMoney('bank', amount, 'banque_transfer')

    if xTarget then
        xTarget.addAccountMoney('bank', amount, 'banque_transfer')
        TriggerClientEvent('esx_banque:notify', xTarget.source,
            ('Vous avez reçu $%s de %s'):format(amount, actor), 'success')
    else
        local row = MySQL.single.await('SELECT accounts FROM users WHERE identifier = ?', { targetIdentifier })
        if not row then
            xPlayer.addAccountMoney('bank', amount, 'banque_transfer_rollback')
            cb({ ok = false, error = Translate('player_not_found') })
            return
        end
        local accounts = json.decode(row.accounts or '{}') or {}
        accounts.bank = (tonumber(accounts.bank) or 0) + amount
        MySQL.update.await('UPDATE users SET accounts = ? WHERE identifier = ?', {
            json.encode(accounts), targetIdentifier
        })
    end

    bank = xPlayer.getAccount('bank')
    logTransaction('personal', xPlayer.identifier, xPlayer.identifier, actor, 'transfer',
        ('Virement vers %s'):format(targetName), -amount, bank and bank.money or 0)
    logTransaction('personal', targetIdentifier, xPlayer.identifier, actor, 'transfer_in',
        ('Virement de %s'):format(actor), amount, nil)

    cb({ ok = true, amount = amount, data = buildPlayerData(xPlayer) })
end)

ESX.RegisterServerCallback('esx_banque:addFavorite', function(source, cb, payload)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb({ ok = false, error = Translate('player_not_found') })
        return
    end

    local name = payload and payload.name
    local accountNumber = payload and payload.accountNumber

    if not name or name == '' or not accountNumber or accountNumber == '' then
        cb({ ok = false, error = Translate('recipient_invalid') })
        return
    end

    name = tostring(name):sub(1, 64)
    accountNumber = tostring(accountNumber):sub(1, 64)

    local exists = MySQL.scalar.await(
        'SELECT 1 FROM banque_favorites WHERE owner = ? AND account_number = ?',
        { xPlayer.identifier, accountNumber }
    )
    if exists then
        cb({ ok = false, error = Translate('recipient_exists') })
        return
    end

    local targetIdentifier = findIdentifierByAccountNumber(accountNumber)

    MySQL.insert.await(
        'INSERT INTO banque_favorites (owner, name, account_number, target_identifier) VALUES (?, ?, ?, ?)',
        { xPlayer.identifier, name, accountNumber, targetIdentifier }
    )

    cb({ ok = true, favorites = getFavorites(xPlayer.identifier) })
end)

ESX.RegisterServerCallback('esx_banque:removeFavorite', function(source, cb, payload)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb({ ok = false })
        return
    end

    local id = tonumber(payload and payload.id)
    if not id then
        cb({ ok = false })
        return
    end

    MySQL.update.await(
        'DELETE FROM banque_favorites WHERE id = ? AND owner = ?',
        { id, xPlayer.identifier }
    )

    cb({ ok = true, favorites = getFavorites(xPlayer.identifier) })
end)

-- Export pour d'autres ressources (salaire, etc.)
exports('LogTransaction', function(accountType, accountId, identifier, actorName, txType, label, amount, balanceAfter)
    logTransaction(accountType, accountId, identifier, actorName, txType, label, amount, balanceAfter)
end)

exports('GetAccountNumber', function(identifier)
    return generateAccountNumber(identifier)
end)
