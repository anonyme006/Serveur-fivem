--[[
    Export system — Port / Gare / Aéroport
]]

Export = {}

--- Destinations indexées
---@param id string
---@return table|nil
local function getDestination(id)
    for _, dest in ipairs(Config.Export.destinations) do
        if dest.id == id then return dest end
    end
    return nil
end

--- Démarre un export (employé grossiste)
---@param source number
---@param destId string
---@param cart { item: string, qty: integer }[]
---@return boolean, string|nil, table|nil data
function Export.Start(source, destId, cart)
    if not Config.Export.enabled then return false, 'error' end

    local player = Payment.GetPlayer(source)
    if not player then return false, 'error' end

    local job = player.PlayerData.job
    if job.name ~= Config.Job.name then return false, 'no_permission' end
    if (job.grade and job.grade.level or 0) < Config.Export.minGrade then
        return false, 'no_permission'
    end

    local dest = getDestination(destId)
    if not dest then return false, 'error' end

    if type(cart) ~= 'table' or #cart == 0 then
        return false, 'cart_empty'
    end

    local lines = {}
    local value = 0

    for _, line in ipairs(cart) do
        local item = tostring(line.item or '')
        local qty = math.floor(tonumber(line.qty) or 0)
        if item == '' or qty < 1 then return false, 'invalid_amount' end

        local product = Stock.Get(item)
        if not product then return false, 'error' end
        if Stock.GetQty(item) < qty then return false, 'export_no_stock' end

        local lineValue = product.price * qty
        value = value + lineValue
        lines[#lines + 1] = {
            item = item,
            label = product.label,
            qty = qty,
            price = product.price,
            total = lineValue,
        }
    end

    -- Retirer du stock
    local reserved = {}
    for _, line in ipairs(lines) do
        if not Stock.Remove(line.item, line.qty) then
            for _, r in ipairs(reserved) do Stock.Add(r.item, r.qty) end
            return false, 'export_no_stock'
        end
        reserved[#reserved + 1] = line
    end

    local reward = Wholesaler.Round(value * Config.Export.rewardMultiplier)

    local exportId = MySQL.insert.await([[
        INSERT INTO wholesaler_exports (citizenid, destination, items, value, reward, status)
        VALUES (?, ?, ?, ?, ?, 'active')
    ]], {
        player.PlayerData.citizenid,
        destId,
        json.encode(lines),
        value,
        reward,
    })

    DB.LogHistory({
        citizenid = player.PlayerData.citizenid,
        company = Config.Job.name,
        action = 'export_started',
        details = { exportId = exportId, dest = destId, lines = lines },
        amount = reward,
    })

    return true, nil, {
        id = exportId,
        destination = dest,
        reward = reward,
        value = value,
        items = lines,
    }
end

--- Termine un export
---@param source number
---@param exportId integer
---@return boolean, string|nil, integer|nil reward
function Export.Complete(source, exportId)
    local player = Payment.GetPlayer(source)
    if not player then return false, 'error' end

    local row = MySQL.single.await(
        'SELECT * FROM wholesaler_exports WHERE id = ? AND status = ?',
        { exportId, 'active' }
    )
    if not row then return false, 'error' end
    if row.citizenid ~= player.PlayerData.citizenid then
        return false, 'no_permission'
    end

    local reward = row.reward or 0

    -- Crédite le compte grossiste (vente export)
    Payment.CreditWholesaler(reward)
    -- Prime conducteur
    local driverCut = Wholesaler.Round(reward * 0.10)
    Payment.PayPlayer(source, driverCut, 'wholesaler-export')

    MySQL.update.await([[
        UPDATE wholesaler_exports SET status = 'completed', completed_at = NOW() WHERE id = ?
    ]], { exportId })

    DB.LogHistory({
        citizenid = player.PlayerData.citizenid,
        company = Config.Job.name,
        action = 'export_completed',
        details = { exportId = exportId, destination = row.destination },
        amount = reward,
    })

    return true, nil, reward
end
