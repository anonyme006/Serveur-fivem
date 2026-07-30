local MODULE = 'shops'

CoreCreator.RegisterModule(MODULE, {
    afterCreate = function(_, id)
        CoreUtils.Debug('Shop created', id)
    end,
})

local playerShopCooldown = {}

local function getShopData(shop)
    return shop and shop.data or {}
end

local function playerAllowed(src, data)
    if data.job and data.job ~= '' then
        local job, grade = Bridge.GetJob(src)
        if job ~= data.job then return false, 'job' end
        if data.minGrade and grade < (tonumber(data.minGrade) or 0) then return false, 'grade' end
    end
    if data.gang and data.gang ~= '' then
        local gang, grade = Bridge.GetGang(src)
        if Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
            if gang ~= data.gang then return false, 'gang' end
            if data.minGangGrade and grade < (tonumber(data.minGangGrade) or 0) then return false, 'gang_grade' end
        else
            local identifier = Bridge.GetIdentifier(src)
            local row = MySQL.single.await(
                'SELECT grade FROM core_creator_gang_members WHERE gang_name = ? AND identifier = ? LIMIT 1',
                { data.gang, identifier }
            )
            if not row then return false, 'gang' end
            if data.minGangGrade and (tonumber(row.grade) or 0) < (tonumber(data.minGangGrade) or 0) then
                return false, 'gang_grade'
            end
        end
    end
    if data.schedule and data.schedule.enabled then
        local hour = tonumber(os.date('%H'))
        local openH = tonumber(data.schedule.open) or 0
        local closeH = tonumber(data.schedule.close) or 24
        if openH < closeH then
            if hour < openH or hour >= closeH then return false, 'closed' end
        else
            if hour < openH and hour >= closeH then return false, 'closed' end
        end
    end
    return true
end

RegisterNetEvent('core_creator:shops:buy', function(shopId, itemIndex, amount)
    local src = source
    shopId = tonumber(shopId)
    itemIndex = tonumber(itemIndex)
    amount = math.floor(tonumber(amount) or 1)
    if not shopId or not itemIndex or amount < 1 or amount > 50 then return end

    local now = GetGameTimer()
    if playerShopCooldown[src] and now - playerShopCooldown[src] < Config.Cooldowns.shopBuy then
        Bridge.Notify(src, _('error.cooldown'), 'error')
        return
    end
    playerShopCooldown[src] = now

    local shop = Database.GetById(MODULE, shopId)
    if not shop or not shop.active then return end

    local near, _ = ServerValidator.PlayerNearCoords(src, shop.coords, (shop.data and shop.data.interactDistance) or Config.Distances.interaction)
    if not near then
        Bridge.Notify(src, _('error.distance'), 'error')
        return
    end

    local data = getShopData(shop)
    local allowed, reason = playerAllowed(src, data)
    if not allowed then
        Bridge.Notify(src, _('error.permission') .. ' (' .. tostring(reason) .. ')', 'error')
        return
    end

    local items = data.items or {}
    local item = items[itemIndex]
    if type(item) ~= 'table' or type(item.name) ~= 'string' then return end

    local price = math.floor(tonumber(item.price) or 0) * amount
    local currency = item.currency or data.currency or 'money'
    local mode = data.mode or 'buy' -- buy = player buys from shop, sell = player sells to shop

    if mode == 'buy' then
        if item.stock ~= nil then
            local stock = tonumber(item.stock) or 0
            if stock < amount then
                Bridge.Notify(src, 'Stock insuffisant', 'error')
                return
            end
        end
        if not Bridge.CanCarryItem(src, item.name, amount) then
            Bridge.Notify(src, 'Inventaire plein', 'error')
            return
        end
        if not Bridge.RemoveMoney(src, currency, price, 'shop_buy') then
            Bridge.Notify(src, _('error.money'), 'error')
            return
        end
        if not Bridge.AddItem(src, item.name, amount) then
            Bridge.AddMoney(src, currency, price, 'shop_buy_refund')
            Bridge.Notify(src, _('error.item'), 'error')
            return
        end
        if item.stock ~= nil then
            item.stock = (tonumber(item.stock) or 0) - amount
            data.items = items
            Database.Update(MODULE, shopId, { data = data }, 'system')
        end
        Bridge.Notify(src, ('Achat: %sx %s'):format(amount, item.name), 'success')
        Logger.Log(src, 'shop_buy', MODULE, shopId, { item = item.name, amount = amount, price = price })
    else
        if not Bridge.HasItem(src, item.name, amount) then
            Bridge.Notify(src, _('error.item'), 'error')
            return
        end
        if not Bridge.RemoveItem(src, item.name, amount) then return end
        Bridge.AddMoney(src, currency, price, 'shop_sell')
        Bridge.Notify(src, ('Vente: %sx %s'):format(amount, item.name), 'success')
        Logger.Log(src, 'shop_sell', MODULE, shopId, { item = item.name, amount = amount, price = price })
    end
end)

AddEventHandler('playerDropped', function()
    playerShopCooldown[source] = nil
end)

-- Active shops for clients
RegisterNetEvent('core_creator:shops:requestSync', function()
    local src = source
    local rows = Database.GetAll(MODULE, true)
    TriggerClientEvent('core_creator:shops:sync', src, rows)
end)

AddEventHandler('core_creator:databaseReady', function()
    Wait(100)
    TriggerClientEvent('core_creator:shops:sync', -1, Database.GetAll(MODULE, true))
end)

AddEventHandler('core_creator:entityChanged', function(moduleName)
    if moduleName ~= MODULE then return end
    TriggerClientEvent('core_creator:shops:sync', -1, Database.GetAll(MODULE, true))
end)
