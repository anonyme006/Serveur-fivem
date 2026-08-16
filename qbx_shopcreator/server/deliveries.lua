ShopCreator = ShopCreator or {}

local Repo = ShopCreator.Repository

---@param source number
---@return table
function ShopCreator.ListDeliveryJobs(source)
    if not ShopCreator.RateLimit(source, 'list_delivery', Config.RateLimit.deliveryMs) then
        return { ok = false, error = ShopCreator.L('rate_limited') }
    end

    local rows = Repo.ListOpenDeliveryJobs()
    local jobs = {}

    for i = 1, #rows do
        local row = rows[i]
        jobs[#jobs + 1] = {
            id = row.id,
            shop_id = row.shop_id,
            shop_name = row.shop_name,
            item_count = tonumber(row.item_count) or 0,
            reward = row.reward,
            origin_label = 'Entrepôt portuaire',
            dest_label = row.shop_name,
            status = row.status,
        }
    end

    return { ok = true, data = jobs }
end

---@param source number
---@param jobId number
---@return table
function ShopCreator.AcceptDelivery(source, jobId)
    jobId = tonumber(jobId)
    if not jobId then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    if not ShopCreator.RateLimit(source, 'accept_delivery', Config.RateLimit.deliveryMs) then
        return { ok = false, error = ShopCreator.L('rate_limited') }
    end

    local citizenid = ShopCreator.GetCitizenId(source)
    if not citizenid then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    local job = Repo.GetDeliveryJob(jobId)
    if not job or job.status ~= 'open' then
        return { ok = false, error = ShopCreator.L('delivery_failed') }
    end

    local order = job.order_id and Repo.GetStockOrder(job.order_id)
    if order and order.method == 'self' then
        local canSelf = order.ordered_by == citizenid
            or ShopCreator.HasShopPermission(source, job.shop_id, 'collect_stock_orders')
        if not canSelf then
            return { ok = false, error = ShopCreator.L('no_permission') }
        end
    end

    local playerName = ShopCreator.GetPlayerName(source)
    local affected = Repo.AcceptDeliveryJob(jobId, citizenid, playerName)
    if not affected or affected < 1 then
        return { ok = false, error = ShopCreator.L('delivery_failed') }
    end

    job = Repo.GetDeliveryJob(jobId)
    if job and job.order_id then
        Repo.UpdateStockOrderStatus(job.order_id, ShopCreator.OrderStatus.accepted)
    end

    ShopCreator.Log('delivery_accepted', { jobId = jobId, citizenid = citizenid })
    ShopCreator.Notify(source, ShopCreator.L('delivery_accepted'), 'success')

    return {
        ok = true,
        data = {
            id = jobId,
            shop_id = job and job.shop_id,
            status = 'accepted',
            reward = job and job.reward or 0,
        },
    }
end

---@param source number
---@param jobId number
---@return table
function ShopCreator.CompleteDelivery(source, jobId)
    jobId = tonumber(jobId)
    if not jobId then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    if not ShopCreator.RateLimit(source, 'complete_delivery', Config.RateLimit.deliveryMs) then
        return { ok = false, error = ShopCreator.L('rate_limited') }
    end

    local citizenid = ShopCreator.GetCitizenId(source)
    if not citizenid then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    local job = Repo.GetDeliveryJob(jobId)
    if not job or job.status ~= 'accepted' or job.accepted_by ~= citizenid then
        return { ok = false, error = ShopCreator.L('delivery_failed') }
    end

    local affected = Repo.CompleteDeliveryJob(jobId, citizenid)
    if not affected or affected < 1 then
        return { ok = false, error = ShopCreator.L('delivery_failed') }
    end

    if job.order_id then
        ShopCreator.ApplyStockFromOrder(job.shop_id, job.order_id)
    end

    local reward = tonumber(job.reward) or 0
    if reward > 0 then
        ShopCreator.AddMoney(source, reward, 'cash', 'delivery_payout')
        Repo.InsertTransaction(
            job.shop_id,
            ShopCreator.TransactionTypes.delivery_payout,
            -reward,
            citizenid,
            ShopCreator.GetPlayerName(source),
            'Paiement livraison publique',
            { jobId = jobId }
        )
        ShopCreator.ReloadShop(job.shop_id)
    end

    ShopCreator.Log('delivery_completed', { jobId = jobId, citizenid = citizenid, reward = reward })
    ShopCreator.Notify(source, ShopCreator.L('delivery_completed'), 'success')

    return { ok = true, data = { reward = reward } }
end

---@param source number
---@param jobId number
---@return table
function ShopCreator.CancelSelfDelivery(source, jobId)
    jobId = tonumber(jobId)
    if not jobId then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    local citizenid = ShopCreator.GetCitizenId(source)
    if not citizenid then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    local job = Repo.GetDeliveryJob(jobId)
    if not job then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    local order = Repo.GetStockOrder(job.order_id)
    if not order or order.method ~= 'self' then
        return { ok = false, error = ShopCreator.L('no_permission') }
    end

    if order.ordered_by ~= citizenid
        and not ShopCreator.HasShopPermission(source, job.shop_id, 'collect_stock_orders') then
        return { ok = false, error = ShopCreator.L('no_permission') }
    end

    local affected = Repo.CancelDeliveryJob(jobId, citizenid)
    if not affected or affected < 1 then
        return { ok = false, error = ShopCreator.L('delivery_failed') }
    end

    if order.total_cost and order.total_cost > 0 then
        Repo.AddBalance(job.shop_id, order.total_cost)
    end

    Repo.UpdateStockOrderStatus(job.order_id, ShopCreator.OrderStatus.cancelled)
    ShopCreator.ReloadShop(job.shop_id)

    ShopCreator.Log('delivery_cancelled', { jobId = jobId, citizenid = citizenid })
    return { ok = true }
end
