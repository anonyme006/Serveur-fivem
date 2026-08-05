--[[
    Stock management — core_wholesaler
]]

Stock = {}

--- Cache mémoire pour lectures rapides (rafraîchi après mutations)
local cache = {}
local cacheReady = false

--- Charge le stock en cache
function Stock.RefreshCache()
    local rows = MySQL.query.await([[
        SELECT s.item, s.quantity, p.label, p.category, p.price, p.image, p.requires_ammo, p.active
        FROM wholesaler_stock s
        INNER JOIN wholesaler_products p ON p.item = s.item
        WHERE p.active = 1
    ]]) or {}

    cache = {}
    for _, row in ipairs(rows) do
        cache[row.item] = {
            item = row.item,
            quantity = row.quantity,
            label = row.label,
            category = row.category,
            price = row.price,
            image = row.image,
            requiresAmmo = row.requires_ammo == 1,
        }
    end
    cacheReady = true
    return cache
end

--- Retourne tout le stock (optionnellement filtré par catégories)
---@param categories string[]|nil
---@return table[]
function Stock.GetAll(categories)
    if not cacheReady then Stock.RefreshCache() end

    local filter
    if categories and categories ~= '*' then
        filter = {}
        for _, c in ipairs(categories) do filter[c] = true end
    end

    local list = {}
    for _, entry in pairs(cache) do
        if not filter or filter[entry.category] then
            list[#list + 1] = entry
        end
    end

    table.sort(list, function(a, b)
        if a.category == b.category then
            return a.label < b.label
        end
        return a.category < b.category
    end)

    return list
end

--- Quantité disponible
---@param item string
---@return integer
function Stock.GetQty(item)
    if not cacheReady then Stock.RefreshCache() end
    return cache[item] and cache[item].quantity or 0
end

--- Prix actuel (DB, peut différer du config)
---@param item string
---@return integer|nil
function Stock.GetPrice(item)
    if not cacheReady then Stock.RefreshCache() end
    return cache[item] and cache[item].price or nil
end

--- Entrée cache complète
---@param item string
---@return table|nil
function Stock.Get(item)
    if not cacheReady then Stock.RefreshCache() end
    return cache[item]
end

--- Retire du stock (transactionnel). Retourne false si insuffisant.
---@param item string
---@param qty integer
---@return boolean
function Stock.Remove(item, qty)
    qty = math.floor(tonumber(qty) or 0)
    if qty <= 0 then return false end

    local affected = MySQL.update.await(
        'UPDATE wholesaler_stock SET quantity = quantity - ? WHERE item = ? AND quantity >= ?',
        { qty, item, qty }
    )

    if not affected or affected < 1 then
        return false
    end

    if cache[item] then
        cache[item].quantity = cache[item].quantity - qty
    end
    return true
end

--- Ajoute du stock
---@param item string
---@param qty integer
---@return boolean
function Stock.Add(item, qty)
    qty = math.floor(tonumber(qty) or 0)
    if qty <= 0 then return false end

    local exists = MySQL.scalar.await('SELECT COUNT(*) FROM wholesaler_products WHERE item = ?', { item })
    if not exists or exists < 1 then return false end

    MySQL.update.await(
        'UPDATE wholesaler_stock SET quantity = quantity + ? WHERE item = ?',
        { qty, item }
    )

    if cache[item] then
        cache[item].quantity = cache[item].quantity + qty
    else
        Stock.RefreshCache()
    end
    return true
end

--- Définit une quantité absolue
---@param item string
---@param qty integer
---@return boolean
function Stock.Set(item, qty)
    qty = math.floor(tonumber(qty) or 0)
    if qty < 0 then return false end

    local affected = MySQL.update.await(
        'UPDATE wholesaler_stock SET quantity = ? WHERE item = ?',
        { qty, item }
    )
    if not affected or affected < 1 then return false end

    if cache[item] then
        cache[item].quantity = qty
    end
    return true
end

--- Met à jour le prix
---@param item string
---@param price integer
---@return boolean
function Stock.SetPrice(item, price)
    price = math.floor(tonumber(price) or 0)
    if price < 0 then return false end

    local affected = MySQL.update.await(
        'UPDATE wholesaler_products SET price = ? WHERE item = ?',
        { price, item }
    )
    if not affected or affected < 1 then return false end

    if cache[item] then
        cache[item].price = price
    end
    return true
end

--- Import livraison (plusieurs items)
---@param items { item: string, qty: integer }[]
---@return integer count
function Stock.Import(items)
    local count = 0
    for _, entry in ipairs(items) do
        if Stock.Add(entry.item, entry.qty) then
            count = count + 1
        end
    end
    return count
end
