--- API unifiée pour notifier / ouvrir apps téléphone

---@param source number
---@param title string
---@param message string
---@param app? string
local function NotifyPhone(source, title, message, app)
    local phone = Config.PhoneResource
    if phone == 'none' then
        exports.rp_core:Notify(source, ('%s: %s'):format(title, message), 'inform')
        return
    end

    if phone == 'npwd' and GetResourceState('npwd') == 'started' then
        exports.npwd:emitMessage({
            sender = title,
            subject = app or 'notification',
            message = message,
            source = source,
        })
        return
    end

    if phone == 'lb-phone' and GetResourceState('lb-phone') == 'started' then
        exports['lb-phone']:SendNotification(source, {
            app = app or 'Wallet',
            title = title,
            content = message,
        })
        return
    end

    if phone == 'sd-phone' and GetResourceState('sd-phone') == 'started' then
        -- API variable selon version — fallback notify
        TriggerClientEvent('sd-phone:client:notify', source, { title = title, message = message })
        return
    end

    exports.rp_core:Notify(source, ('%s: %s'):format(title, message), 'inform')
end

exports('NotifyPhone', NotifyPhone)

--- Exposition solde banque pour apps téléphone
lib.callback.register('rp_phone_bridge:getBank', function(source)
    if not Config.Features.banking then return nil end
    return {
        bank = exports.rp_core:GetMoney(source, 'bank'),
        cash = exports.rp_core:GetMoney(source, 'cash'),
    }
end)

lib.callback.register('rp_phone_bridge:getInvoices', function(source)
    if not Config.Features.invoices or GetResourceState('rp_billing') ~= 'started' then return {} end
    local player = exports.rp_core:GetPlayer(source)
    if not player then return {} end
    return MySQL and MySQL.query.await and MySQL.query.await(
        'SELECT invoice_id, amount, reason, status, society FROM rp_invoices WHERE target_cid = ? AND status = ? ORDER BY id DESC LIMIT 20',
        { player.PlayerData.citizenid, 'pending' }
    ) or {}
end)

AddEventHandler('rp_billing:server:invoiceCreated', function(target, payload)
    if Config.Features.invoices then
        NotifyPhone(target, 'Facture', payload.reason or 'Nouvelle facture', 'Wallet')
    end
end)

print(('[rp_phone_bridge] mode=%s'):format(Config.PhoneResource))
