local function generateInvoiceId()
    return ('INV-%s-%04d'):format(os.date('%y%m%d'), math.random(0, 9999))
end

local function canBill(source)
    if exports.rp_core:HasAce(source, 'admin') then return true, 'admin' end
    local player = exports.rp_core:GetPlayer(source)
    if not player then return false end
    local job = player.PlayerData.job
    if not job or not job.onduty then return false end
    local min = Config.AllowedJobs[job.name]
    if min == nil then return false end
    if (job.grade and job.grade.level or 0) < min then return false end
    return true, job.name
end

---@param fromSource number
---@param toSource number
---@param amount number
---@param reason string
---@param society? string
---@return boolean, string|nil
local function CreateInvoice(fromSource, toSource, amount, reason, society)
    amount = exports.rp_core and (function()
        -- sanitize via shared util if available
        local n = tonumber(amount)
        if not n or n < 1 or n > Config.MaxAmount then return nil end
        return math.floor(n)
    end)()
    if not amount or type(reason) ~= 'string' or #reason < 2 or #reason > 180 then
        return false, L('invalid')
    end

    local sender = exports.rp_core:GetPlayer(fromSource)
    local target = exports.rp_core:GetPlayer(toSource)
    if not sender or not target then return false, L('invalid') end

    local pedA, pedB = GetPlayerPed(fromSource), GetPlayerPed(toSource)
    if pedA ~= 0 and pedB ~= 0 then
        local dist = #(GetEntityCoords(pedA) - GetEntityCoords(pedB))
        if dist > Config.MinDistance then return false, L('too_far') end
    end

    local allowed, jobName = canBill(fromSource)
    if not allowed then return false, L('no_perm') end

    society = society or jobName
    local invoiceId = generateInvoiceId()
    local expires = os.time() + (Config.DefaultExpireHours * 3600)

    MySQL.insert.await([[
        INSERT INTO rp_invoices
        (invoice_id, sender_cid, target_cid, society, amount, reason, status, expires_at)
        VALUES (?, ?, ?, ?, ?, ?, 'pending', FROM_UNIXTIME(?))
    ]], {
        invoiceId,
        sender.PlayerData.citizenid,
        target.PlayerData.citizenid,
        society,
        amount,
        reason,
        expires,
    })

    exports.rp_core:Notify(fromSource, L('created', invoiceId, amount), 'success')
    exports.rp_core:Notify(toSource, L('received', invoiceId, amount, reason), 'inform')
    TriggerClientEvent('rp_billing:client:newInvoice', toSource, {
        invoice_id = invoiceId,
        amount = amount,
        reason = reason,
        society = society,
    })

    if GetResourceState('rp_logs') == 'started' then
        exports.rp_logs:Log('billing', fromSource, 'Facture créée', {
            invoice = invoiceId,
            amount = amount,
            target = target.PlayerData.citizenid,
        })
    end

    return true, invoiceId
end

exports('CreateInvoice', CreateInvoice)

---@param source number
---@param invoiceId string
---@return boolean, string
local function PayInvoice(source, invoiceId)
    if type(invoiceId) ~= 'string' then return false, L('invalid') end
    local player = exports.rp_core:GetPlayer(source)
    if not player then return false, L('invalid') end

    local row = MySQL.single.await(
        'SELECT * FROM rp_invoices WHERE invoice_id = ? AND target_cid = ? LIMIT 1',
        { invoiceId, player.PlayerData.citizenid }
    )
    if not row then return false, L('not_found') end
    if row.status ~= 'pending' then return false, L('not_found') end
    if row.expires_at and os.time() > (type(row.expires_at) == 'number' and row.expires_at or 0) then
        -- MySQL may return datetime string; check via SQL update
    end

    local expired = MySQL.scalar.await(
        'SELECT TIMESTAMPDIFF(SECOND, NOW(), expires_at) FROM rp_invoices WHERE invoice_id = ?',
        { invoiceId }
    )
    if expired and expired < 0 then
        MySQL.update.await('UPDATE rp_invoices SET status = ? WHERE invoice_id = ?', { 'expired', invoiceId })
        return false, L('expired')
    end

    if not exports.rp_core:RemoveMoney(source, 'bank', row.amount, 'invoice:' .. invoiceId) then
        return false, L('no_money')
    end

    if row.society and row.society ~= 'admin' then
        exports.rp_core:AddSocietyMoney(row.society, row.amount, 'invoice:' .. invoiceId)
    end

    MySQL.update.await(
        'UPDATE rp_invoices SET status = ?, paid_at = NOW() WHERE invoice_id = ? AND status = ?',
        { 'paid', invoiceId, 'pending' }
    )

    exports.rp_core:Notify(source, L('paid', invoiceId), 'success')
    local sender = exports.qbx_core:GetPlayerByCitizenId(row.sender_cid)
    if sender then
        exports.rp_core:Notify(sender.PlayerData.source, L('paid', invoiceId), 'success')
    end

    if GetResourceState('rp_logs') == 'started' then
        exports.rp_logs:Log('billing', source, 'Facture payée', { invoice = invoiceId, amount = row.amount })
    end
    return true, 'ok'
end

exports('PayInvoice', PayInvoice)

---@param source number
---@param invoiceId string
local function RefuseInvoice(source, invoiceId)
    local player = exports.rp_core:GetPlayer(source)
    if not player or type(invoiceId) ~= 'string' then return false end
    local affected = MySQL.update.await(
        'UPDATE rp_invoices SET status = ? WHERE invoice_id = ? AND target_cid = ? AND status = ?',
        { 'refused', invoiceId, player.PlayerData.citizenid, 'pending' }
    )
    if affected and affected > 0 then
        exports.rp_core:Notify(source, L('refused', invoiceId), 'error')
        return true
    end
    return false
end

exports('RefuseInvoice', RefuseInvoice)

lib.callback.register('rp_billing:getMine', function(source)
    local player = exports.rp_core:GetPlayer(source)
    if not player then return {} end
    return MySQL.query.await(
        'SELECT invoice_id, society, amount, reason, status, created_at, expires_at FROM rp_invoices WHERE target_cid = ? ORDER BY id DESC LIMIT 50',
        { player.PlayerData.citizenid }
    ) or {}
end)

RegisterNetEvent('rp_billing:server:create', function(targetId, amount, reason)
    local src = source
    if not exports.rp_core:RateLimit(src, 'bill_create', 2000) then return end
    CreateInvoice(src, tonumber(targetId), amount, reason)
end)

RegisterNetEvent('rp_billing:server:pay', function(invoiceId)
    local src = source
    if not exports.rp_core:RateLimit(src, 'bill_pay', 1500) then return end
    local ok, msg = PayInvoice(src, invoiceId)
    if not ok then exports.rp_core:Notify(src, msg, 'error') end
end)

RegisterNetEvent('rp_billing:server:refuse', function(invoiceId)
    local src = source
    if not exports.rp_core:RateLimit(src, 'bill_refuse', 1500) then return end
    RefuseInvoice(src, invoiceId)
end)

MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `rp_invoices` (
          `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
          `invoice_id` VARCHAR(32) NOT NULL,
          `sender_cid` VARCHAR(50) NOT NULL,
          `target_cid` VARCHAR(50) NOT NULL,
          `society` VARCHAR(50) DEFAULT NULL,
          `amount` INT UNSIGNED NOT NULL,
          `reason` VARCHAR(180) NOT NULL,
          `status` ENUM('pending','paid','refused','expired') NOT NULL DEFAULT 'pending',
          `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
          `paid_at` TIMESTAMP NULL DEFAULT NULL,
          `expires_at` TIMESTAMP NULL DEFAULT NULL,
          PRIMARY KEY (`id`),
          UNIQUE KEY `uk_invoice_id` (`invoice_id`),
          KEY `idx_inv_target` (`target_cid`),
          KEY `idx_inv_sender` (`sender_cid`),
          KEY `idx_inv_status` (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end)

print('[rp_billing] ready')
