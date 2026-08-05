--[[
    Orders — cycle de vie
    pending → prepared → available → withdrawn | delivered
]]

Orders = {}

-- Timers de préparation en cours { [orderId] = true }
local preparing = {}

--- Vérifie l'autorisation munitions
---@param player table
---@return boolean
local function canBuyAmmo(player)
    if not Config.AmmoAuth.enabled then return true end
    local job = player.PlayerData.job
    if not Wholesaler.JobInList(job.name, Config.AmmoAuth.jobs) then return false end
    return (job.grade and job.grade.level or 0) >= Config.AmmoAuth.minGrade
end

--- Crée une commande après validation stock + paiement
---@param source number
---@param cart { item: string, qty: integer }[]
---@param method string
---@param fulfillment string 'pickup'|'delivery'
---@param deliveryCoords vector3|nil
---@return integer|nil orderId, string|nil errKey
function Orders.Create(source, cart, method, fulfillment, deliveryCoords)
    local player = Payment.GetPlayer(source)
    if not player then return nil, 'error' end

    local job = player.PlayerData.job
    if not Config.AllowedCompanies[job.name] then
        return nil, 'not_authorized'
    end
    if (job.grade and job.grade.level or 0) < Config.BuyerMinGrade then
        return nil, 'no_permission'
    end

    if type(cart) ~= 'table' or #cart == 0 then
        return nil, 'cart_empty'
    end
    if #cart > Config.Orders.maxLines then
        return nil, 'max_lines'
    end

    -- Validation lignes + calcul
    local lines = {}
    local subtotal = 0
    local totalQty = 0

    for _, line in ipairs(cart) do
        local item = tostring(line.item or '')
        local qty = math.floor(tonumber(line.qty) or 0)
        if item == '' or qty < 1 or qty > Config.Orders.maxQtyPerLine then
            return nil, 'invalid_amount'
        end

        local product = Stock.Get(item)
        if not product then return nil, 'error' end

        if not Wholesaler.CanAccessCategory(job.name, product.category) then
            return nil, 'not_authorized'
        end

        if product.requiresAmmo and not canBuyAmmo(player) then
            return nil, 'ammo_denied'
        end

        if Stock.GetQty(item) < qty then
            return nil, 'out_of_stock'
        end

        local lineTotal = product.price * qty
        subtotal = subtotal + lineTotal
        totalQty = totalQty + qty

        lines[#lines + 1] = {
            item = item,
            label = product.label,
            qty = qty,
            price = product.price,
            total = lineTotal,
            image = product.image,
        }
    end

    local tax, vat, total = Wholesaler.CalcTaxes(subtotal)

    -- Réservation stock
    local reserved = {}
    for _, line in ipairs(lines) do
        if not Stock.Remove(line.item, line.qty) then
            -- rollback
            for _, r in ipairs(reserved) do
                Stock.Add(r.item, r.qty)
            end
            return nil, 'out_of_stock'
        end
        reserved[#reserved + 1] = line
    end

    -- Paiement
    local paid, payErr = Payment.Charge(source, total, method)
    if not paid then
        for _, r in ipairs(reserved) do
            Stock.Add(r.item, r.qty)
        end
        return nil, payErr == 'funds' and 'payment_failed' or 'error'
    end

    fulfillment = fulfillment == 'delivery' and 'delivery' or 'pickup'
    local reward = 0
    if fulfillment == 'delivery' and Config.Delivery.enabled then
        reward = Wholesaler.Round(Config.Delivery.rewardBase + total * Config.Delivery.rewardPercent)
    end

    local citizenid = player.PlayerData.citizenid
    local companyLabel = job.label or job.name

    local orderId = MySQL.insert.await([[
        INSERT INTO wholesaler_orders
            (citizenid, company, items, subtotal, tax, vat, total, payment_method, fulfillment, status, delivery_reward, delivery_coords)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        citizenid,
        job.name,
        json.encode(lines),
        subtotal,
        tax,
        vat,
        total,
        method,
        fulfillment,
        Config.Orders.statuses.pending,
        reward,
        deliveryCoords and json.encode({
            x = deliveryCoords.x,
            y = deliveryCoords.y,
            z = deliveryCoords.z,
        }) or nil,
    })

    DB.LogHistory({
        orderId = orderId,
        citizenid = citizenid,
        company = job.name,
        action = 'order_created',
        details = { lines = lines, method = method, fulfillment = fulfillment },
        amount = total,
    })

    DB.UpsertCompany(job.name, companyLabel, total)

    -- Lancer la préparation asynchrone
    Orders.SchedulePreparation(orderId, totalQty, citizenid)

    return orderId
end

--- Planifie le passage pending → prepared → available
---@param orderId integer
---@param totalQty integer
---@param citizenid string
function Orders.SchedulePreparation(orderId, totalQty, citizenid)
    if preparing[orderId] then return end
    preparing[orderId] = true

    local totalMs = (Config.Orders.prepareBase + totalQty * Config.Orders.preparePerItem) * 1000
    local halfMs = math.floor(totalMs / 2)

    -- pending → prepared (mi-parcours)
    SetTimeout(halfMs, function()
        local status = MySQL.scalar.await('SELECT status FROM wholesaler_orders WHERE id = ?', { orderId })
        if status ~= Config.Orders.statuses.pending then return end

        MySQL.update.await([[
            UPDATE wholesaler_orders SET status = ?, prepared_at = NOW() WHERE id = ?
        ]], { Config.Orders.statuses.prepared, orderId })

        Wholesaler.Debug('Order', orderId, 'prepared')
    end)

    -- prepared → available
    SetTimeout(totalMs, function()
        preparing[orderId] = nil

        local status = MySQL.scalar.await('SELECT status FROM wholesaler_orders WHERE id = ?', { orderId })
        if status ~= Config.Orders.statuses.pending and status ~= Config.Orders.statuses.prepared then
            return
        end

        MySQL.update.await([[
            UPDATE wholesaler_orders
            SET status = ?, available_at = NOW(),
                prepared_at = COALESCE(prepared_at, NOW())
            WHERE id = ?
        ]], { Config.Orders.statuses.available, orderId })

        local target = Orders.GetSourceByCitizenId(citizenid)
        if target then
            TriggerClientEvent('ox_lib:notify', target, {
                title = _('wholesaler'),
                description = _('order_ready', orderId),
                type = 'success',
                duration = Config.Notify.duration,
                position = Config.Notify.position,
            })
        end

        Wholesaler.Debug('Order', orderId, 'now available')
    end)
end

--- Source depuis citizenid
---@param citizenid string
---@return number|nil
function Orders.GetSourceByCitizenId(citizenid)
    local players = exports.qbx_core:GetQBPlayers()
    if not players then return nil end
    for src, ply in pairs(players) do
        if ply.PlayerData.citizenid == citizenid then
            return src
        end
    end
    return nil
end

--- Commandes d'un joueur
---@param citizenid string
---@param limit integer|nil
---@return table[]
function Orders.GetByCitizen(citizenid, limit)
    limit = limit or 50
    return MySQL.query.await(
        'SELECT * FROM wholesaler_orders WHERE citizenid = ? ORDER BY id DESC LIMIT ?',
        { citizenid, limit }
    ) or {}
end

--- Commandes d'une entreprise
---@param company string
---@param limit integer|nil
---@return table[]
function Orders.GetByCompany(company, limit)
    limit = limit or 50
    return MySQL.query.await(
        'SELECT * FROM wholesaler_orders WHERE company = ? ORDER BY id DESC LIMIT ?',
        { company, limit }
    ) or {}
end

--- Commandes disponibles au retrait pour un citizenid
---@param citizenid string
---@return table[]
function Orders.GetAvailablePickup(citizenid)
    return MySQL.query.await([[
        SELECT * FROM wholesaler_orders
        WHERE citizenid = ? AND status = ? AND fulfillment = 'pickup'
        ORDER BY id ASC
    ]], { citizenid, Config.Orders.statuses.available }) or {}
end

--- Retrait au quai → items dans ox_inventory
---@param source number
---@param orderId integer
---@return boolean, string|nil
function Orders.Withdraw(source, orderId)
    local player = Payment.GetPlayer(source)
    if not player then return false, 'error' end

    local order = MySQL.single.await(
        'SELECT * FROM wholesaler_orders WHERE id = ?',
        { orderId }
    )
    if not order then return false, 'error' end
    if order.citizenid ~= player.PlayerData.citizenid then return false, 'no_permission' end
    if order.status ~= Config.Orders.statuses.available then return false, 'error' end
    if order.fulfillment ~= 'pickup' then return false, 'error' end

    local items = json.decode(order.items) or {}

    -- Vérifier place inventaire
    for _, line in ipairs(items) do
        local canCarry = exports.ox_inventory:CanCarryItem(source, line.item, line.qty)
        if not canCarry then
            return false, 'pickup_inventory'
        end
    end

    for _, line in ipairs(items) do
        exports.ox_inventory:AddItem(source, line.item, line.qty)
    end

    MySQL.update.await([[
        UPDATE wholesaler_orders SET status = ?, completed_at = NOW() WHERE id = ?
    ]], { Config.Orders.statuses.withdrawn, orderId })

    DB.LogHistory({
        orderId = orderId,
        citizenid = player.PlayerData.citizenid,
        company = order.company,
        action = 'order_withdrawn',
        amount = order.total,
    })

    return true
end

--- Historique d'achats
---@param citizenid string
---@param limit integer|nil
---@return table[]
function Orders.GetHistory(citizenid, limit)
    limit = limit or 30
    return MySQL.query.await([[
        SELECT * FROM wholesaler_history
        WHERE citizenid = ? AND action IN ('order_created', 'order_withdrawn', 'order_delivered')
        ORDER BY id DESC LIMIT ?
    ]], { citizenid, limit }) or {}
end

--- Toutes les commandes (boss)
---@param limit integer|nil
---@return table[]
function Orders.GetAll(limit)
    limit = limit or 100
    return MySQL.query.await(
        'SELECT * FROM wholesaler_orders ORDER BY id DESC LIMIT ?',
        { limit }
    ) or {}
end

--- Marque préparée manuellement (employé)
---@param orderId integer
---@return boolean
function Orders.MarkPrepared(orderId)
    local affected = MySQL.update.await([[
        UPDATE wholesaler_orders
        SET status = ?, prepared_at = NOW(), available_at = NOW()
        WHERE id = ? AND status = ?
    ]], {
        Config.Orders.statuses.available,
        orderId,
        Config.Orders.statuses.pending,
    })
    return affected and affected > 0
end

--- Au démarrage : reprendre les préparations pending
function Orders.ResumePending()
    local rows = MySQL.query.await(
        'SELECT id, citizenid, items, created_at FROM wholesaler_orders WHERE status = ?',
        { Config.Orders.statuses.pending }
    ) or {}

    for _, row in ipairs(rows) do
        local items = json.decode(row.items) or {}
        local totalQty = 0
        for _, line in ipairs(items) do
            totalQty = totalQty + (line.qty or 0)
        end

        -- Délai restant approximatif
        local created = row.created_at
        local elapsed = 0
        if type(created) == 'number' then
            elapsed = os.time() - math.floor(created / 1000)
        end
        local totalDelay = Config.Orders.prepareBase + totalQty * Config.Orders.preparePerItem
        local remaining = math.max(5, totalDelay - elapsed)

        preparing[row.id] = true
        SetTimeout(remaining * 1000, function()
            preparing[row.id] = nil
            local status = MySQL.scalar.await('SELECT status FROM wholesaler_orders WHERE id = ?', { row.id })
            if status ~= Config.Orders.statuses.pending then return end

            MySQL.update.await([[
                UPDATE wholesaler_orders
                SET status = ?, prepared_at = NOW(), available_at = NOW()
                WHERE id = ?
            ]], { Config.Orders.statuses.available, row.id })

            local target = Orders.GetSourceByCitizenId(row.citizenid)
            if target then
                TriggerClientEvent('ox_lib:notify', target, {
                    title = _('wholesaler'),
                    description = _('order_ready', row.id),
                    type = 'success',
                    duration = Config.Notify.duration,
                })
            end
        end)
    end

    Wholesaler.Debug('Resumed', #rows, 'pending orders')
end
