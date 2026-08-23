MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `rp_business_accounts` (
          `name` VARCHAR(50) NOT NULL,
          `balance` BIGINT NOT NULL DEFAULT 0,
          `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          PRIMARY KEY (`name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `rp_business_transactions` (
          `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
          `business` VARCHAR(50) NOT NULL,
          `citizenid` VARCHAR(50) DEFAULT NULL,
          `type` VARCHAR(32) NOT NULL,
          `amount` INT NOT NULL,
          `reason` VARCHAR(180) DEFAULT NULL,
          `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`),
          KEY `idx_biz_tx_business` (`business`),
          KEY `idx_biz_tx_created` (`created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `rp_business_announcements` (
          `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
          `business` VARCHAR(50) NOT NULL,
          `citizenid` VARCHAR(50) NOT NULL,
          `message` VARCHAR(280) NOT NULL,
          `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`),
          KEY `idx_biz_ann_business` (`business`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    for name in pairs(Config.Businesses) do
        MySQL.insert.await(
            'INSERT IGNORE INTO rp_business_accounts (name, balance) VALUES (?, 0)',
            { name }
        )
    end
end)

RegisterNetEvent('rp_business:server:deposit', function(businessName, amount)
    local src = source
    if not exports.rp_core:RateLimit(src, 'biz_deposit', 1500) then return end
    local ok, player, ctx = Business.GetBossContext(src, businessName)
    if not ok then return end
    amount = math.floor(tonumber(amount) or 0)
    if amount < 1 or amount > 1000000 then return end
    if not exports.rp_core:RemoveMoney(src, 'cash', amount, 'business_deposit') then
        exports.rp_core:Notify(src, L('insufficient'), 'error')
        return
    end
    Business.AddMoney(businessName, amount)
    Business.LogTransaction(businessName, amount, player.PlayerData.citizenid, 'deposit', 'Dépôt employé')
    exports.rp_core:Notify(src, L('deposited'), 'success')
end)

RegisterNetEvent('rp_business:server:withdraw', function(businessName, amount)
    local src = source
    if not exports.rp_core:RateLimit(src, 'biz_withdraw', 1500) then return end
    local ok, player, ctx = Business.GetBossContext(src, businessName)
    if not ok or not ctx.isBoss then
        exports.rp_core:Notify(src, L('no_boss'), 'error')
        return
    end
    amount = math.floor(tonumber(amount) or 0)
    if amount < 1 then return end
    if not Business.RemoveMoney(businessName, amount) then
        exports.rp_core:Notify(src, L('insufficient'), 'error')
        return
    end
    exports.rp_core:AddMoney(src, 'cash', amount, 'business_withdraw')
    Business.LogTransaction(businessName, amount, player.PlayerData.citizenid, 'withdraw', 'Retrait patron')
    exports.rp_core:Notify(src, L('withdrawn'), 'success')
    if GetResourceState('rp_logs') == 'started' then
        exports.rp_logs:Log('business', src, 'Retrait entreprise', { business = businessName, amount = amount })
    end
end)

RegisterNetEvent('rp_business:server:announce', function(businessName, message)
    local src = source
    if not exports.rp_core:RateLimit(src, 'biz_announce', 5000) then return end
    local ok, player, ctx = Business.GetBossContext(src, businessName)
    if not ok or not ctx.isBoss or not ctx.def.announce then
        exports.rp_core:Notify(src, L('no_boss'), 'error')
        return
    end
    if type(message) ~= 'string' or #message < 3 or #message > 280 then return end
    MySQL.insert.await(
        'INSERT INTO rp_business_announcements (business, citizenid, message) VALUES (?, ?, ?)',
        { businessName, player.PlayerData.citizenid, message }
    )
    TriggerClientEvent('rp_business:client:announce', -1, ctx.def.label, message)
    exports.rp_core:Notify(src, L('announced'), 'success')
end)

RegisterNetEvent('rp_business:server:setEmployee', function(businessName, targetId, action, grade)
    local src = source
    if not exports.rp_core:RateLimit(src, 'biz_employee', 2000) then return end
    local ok, player, ctx = Business.GetBossContext(src, businessName)
    if not ok or not ctx.isBoss then
        exports.rp_core:Notify(src, L('no_boss'), 'error')
        return
    end
    targetId = tonumber(targetId)
    local target = targetId and exports.rp_core:GetPlayer(targetId)
    if not target then return end

    if action == 'hire' then
        exports.qbx_core:SetJob(target.PlayerData.citizenid, businessName, tonumber(grade) or 0)
        exports.rp_core:Notify(src, L('hired'), 'success')
        exports.rp_core:Notify(targetId, 'Vous avez été recruté : ' .. ctx.def.label, 'success')
    elseif action == 'fire' then
        if target.PlayerData.job.name ~= businessName then return end
        exports.qbx_core:SetJob(target.PlayerData.citizenid, 'unemployed', 0)
        exports.rp_core:Notify(src, L('fired'), 'success')
    elseif action == 'promote' or action == 'demote' then
        if target.PlayerData.job.name ~= businessName then return end
        local newGrade = tonumber(grade)
        if not newGrade or newGrade < 0 or newGrade >= (ctx.def.bossGrade or 99) then return end
        exports.qbx_core:SetJob(target.PlayerData.citizenid, businessName, newGrade)
        exports.rp_core:Notify(src, action == 'promote' and L('promoted') or L('demoted'), 'success')
    end
end)

lib.callback.register('rp_business:getInfo', function(source, businessName)
    local ok, player, ctx = Business.GetBossContext(source, businessName)
    if not ok then return nil end
    local txs = MySQL.query.await(
        'SELECT type, amount, reason, created_at FROM rp_business_transactions WHERE business = ? ORDER BY id DESC LIMIT 30',
        { businessName }
    ) or {}
    return {
        label = ctx.def.label,
        balance = Business.GetBalance(businessName),
        isBoss = ctx.isBoss,
        grade = ctx.grade,
        transactions = txs,
    }
end)

-- Stashes ox_inventory
CreateThread(function()
    Wait(2000)
    if GetResourceState('ox_inventory') ~= 'started' then return end
    for _, def in pairs(Config.Businesses) do
        if def.stash then
            exports.ox_inventory:RegisterStash(def.stash.id, def.label .. ' — Coffre', def.stash.slots, def.stash.weight)
        end
    end
end)

print('[rp_business] ready')
