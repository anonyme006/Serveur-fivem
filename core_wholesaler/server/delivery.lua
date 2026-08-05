--[[
    Delivery system — transporteurs
]]

Delivery = {}

--- Vérifie si le joueur est transporteur
---@param player table
---@return boolean
function Delivery.IsTransporter(player)
    if not Config.Delivery.enabled then return false end
    return Wholesaler.JobInList(player.PlayerData.job.name, Config.Delivery.jobs)
end

--- Commandes en attente de livraison (disponibles + fulfillment delivery, pas encore prises)
---@return table[]
function Delivery.GetAvailable()
    return MySQL.query.await([[
        SELECT * FROM wholesaler_orders
        WHERE fulfillment = 'delivery'
          AND status = ?
          AND (delivery_citizenid IS NULL OR delivery_citizenid = '')
        ORDER BY id ASC
    ]], { Config.Orders.statuses.available }) or {}
end

--- Prendre une livraison
---@param source number
---@param orderId integer
---@return boolean, string|nil, table|nil
function Delivery.Take(source, orderId)
    local player = Payment.GetPlayer(source)
    if not player then return false, 'error' end
    if not Delivery.IsTransporter(player) then return false, 'delivery_need_job' end

    local citizenid = player.PlayerData.citizenid

    local affected = MySQL.update.await([[
        UPDATE wholesaler_orders
        SET delivery_citizenid = ?
        WHERE id = ?
          AND fulfillment = 'delivery'
          AND status = ?
          AND (delivery_citizenid IS NULL OR delivery_citizenid = '')
    ]], {
        citizenid,
        orderId,
        Config.Orders.statuses.available,
    })

    if not affected or affected < 1 then
        return false, 'error'
    end

    local order = MySQL.single.await('SELECT * FROM wholesaler_orders WHERE id = ?', { orderId })
    return true, nil, order
end

--- Confirmer chargement au quai (côté client valide la zone)
---@param source number
---@param orderId integer
---@return boolean, string|nil
function Delivery.Load(source, orderId)
    local player = Payment.GetPlayer(source)
    if not player then return false, 'error' end

    local order = MySQL.single.await('SELECT * FROM wholesaler_orders WHERE id = ?', { orderId })
    if not order then return false, 'error' end
    if order.delivery_citizenid ~= player.PlayerData.citizenid then
        return false, 'delivery_not_yours'
    end
    if order.status ~= Config.Orders.statuses.available then
        return false, 'error'
    end

    return true
end

--- Terminer la livraison chez le client
---@param source number
---@param orderId integer
---@return boolean, string|nil, integer|nil reward
function Delivery.Complete(source, orderId)
    local player = Payment.GetPlayer(source)
    if not player then return false, 'error' end

    local order = MySQL.single.await('SELECT * FROM wholesaler_orders WHERE id = ?', { orderId })
    if not order then return false, 'error' end
    if order.delivery_citizenid ~= player.PlayerData.citizenid then
        return false, 'delivery_not_yours'
    end
    if order.status ~= Config.Orders.statuses.available then
        return false, 'error'
    end

    -- Donner les items au destinataire s'il est en ligne, sinon au livreur (stash logique : livreur)
    local buyerSrc = Orders.GetSourceByCitizenId(order.citizenid)
    local items = json.decode(order.items) or {}
    local targetSrc = buyerSrc or source

    for _, line in ipairs(items) do
        local canCarry = exports.ox_inventory:CanCarryItem(targetSrc, line.item, line.qty)
        if canCarry then
            exports.ox_inventory:AddItem(targetSrc, line.item, line.qty)
        else
            -- Fallback : drop au sol non implémenté → ajoute ce qui passe
            exports.ox_inventory:AddItem(targetSrc, line.item, 1)
        end
    end

    local reward = order.delivery_reward or 0
    Payment.PayPlayer(source, reward, 'wholesaler-delivery')

    MySQL.update.await([[
        UPDATE wholesaler_orders SET status = ?, completed_at = NOW() WHERE id = ?
    ]], { Config.Orders.statuses.delivered, orderId })

    DB.LogHistory({
        orderId = orderId,
        citizenid = order.citizenid,
        company = order.company,
        action = 'order_delivered',
        details = { transporter = player.PlayerData.citizenid, reward = reward },
        amount = order.total,
    })

    if buyerSrc then
        TriggerClientEvent('ox_lib:notify', buyerSrc, {
            title = _('wholesaler'),
            description = _('delivery_complete', orderId, Wholesaler.FormatMoney(0)),
            type = 'inform',
            duration = Config.Notify.duration,
        })
    end

    return true, nil, reward
end
