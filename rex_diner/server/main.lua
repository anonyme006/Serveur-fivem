RexDiner = RexDiner or {}
RexDiner.ServiceCache = {} ---@type table<number, { restaurant: string, startedAt: number }>
RexDiner.Cooldowns = {} ---@type table<string, number>
RexDiner.ActiveCrafts = {} ---@type table<number, boolean>
RexDiner.ActiveDeliveries = {} ---@type table<number, number> source -> deliveryId

local function debugPrint(...)
    if Config.Debug then
        print('[rex_diner]', ...)
    end
end

RexDiner.Debug = debugPrint

---@param source number
---@return table|nil
function RexDiner.GetPlayer(source)
    return exports.qbx_core:GetPlayer(source)
end

---@param source number
---@return string|nil
function RexDiner.GetCitizenId(source)
    local player = RexDiner.GetPlayer(source)
    return player and player.PlayerData and player.PlayerData.citizenid or nil
end

---@param source number
---@return string
function RexDiner.GetCharName(source)
    local player = RexDiner.GetPlayer(source)
    if not player or not player.PlayerData or not player.PlayerData.charinfo then
        return GetPlayerName(source) or ('ID %s'):format(source)
    end
    local info = player.PlayerData.charinfo
    return ('%s %s'):format(info.firstname or '', info.lastname or ''):gsub('%s+', ' '):gsub('^%s*(.-)%s*$', '%1')
end

---@param source number
---@return string|nil firstname
---@return string|nil lastname
function RexDiner.GetCharNames(source)
    local player = RexDiner.GetPlayer(source)
    if not player or not player.PlayerData or not player.PlayerData.charinfo then
        return nil, nil
    end
    return player.PlayerData.charinfo.firstname, player.PlayerData.charinfo.lastname
end

---@param source number
---@return string|nil jobName
---@return number grade
---@return boolean onDuty
function RexDiner.GetJob(source)
    local player = RexDiner.GetPlayer(source)
    if not player or not player.PlayerData or not player.PlayerData.job then
        return nil, 0, false
    end
    local job = player.PlayerData.job
    return job.name, job.grade and job.grade.level or 0, job.onduty == true
end

---@param source number
---@return string|nil restaurantKey
---@return table|nil restaurant
---@return number grade
---@return boolean onDuty
function RexDiner.GetEmployeeContext(source)
    local jobName, grade, onDuty = RexDiner.GetJob(source)
    local key, restaurant = GetRestaurantByJob(jobName)
    return key, restaurant, grade, onDuty
end

---@param source number
---@param permission string
---@param requireDuty boolean|nil
---@return boolean
---@return string|nil errorMsg
---@return table|nil ctx
function RexDiner.Authorize(source, permission, requireDuty)
    local key, restaurant, grade, onDuty = RexDiner.GetEmployeeContext(source)
    if not key or not restaurant then
        return false, 'Vous n\'êtes pas employé de ce restaurant.', nil
    end
    if requireDuty ~= false and not onDuty and not RexDiner.ServiceCache[source] then
        return false, 'Vous devez être en service.', nil
    end
    if permission and not HasPermission(grade, permission) then
        return false, 'Permission insuffisante.', nil
    end
    return true, nil, {
        restaurantKey = key,
        restaurant = restaurant,
        grade = grade,
        onDuty = onDuty or RexDiner.ServiceCache[source] ~= nil,
        citizenid = RexDiner.GetCitizenId(source),
        name = RexDiner.GetCharName(source),
    }
end

---@param source number
---@param action string
---@return boolean
function RexDiner.CheckCooldown(source, action)
    local seconds = Config.Cooldowns[action] or 2
    local key = ('%s:%s'):format(source, action)
    local now = os.time()
    local last = RexDiner.Cooldowns[key] or 0
    if now - last < seconds then
        return false
    end
    RexDiner.Cooldowns[key] = now
    return true
end

---@param source number
---@param item string
---@return number
function RexDiner.GetItemCount(source, item)
    local result = exports.ox_inventory:Search(source, 'count', item)
    return tonumber(result) or 0
end

---@param source number
---@param items table<string, number>
---@return boolean
---@return string|nil
function RexDiner.HasItems(source, items)
    for item, amount in pairs(items) do
        amount = math.floor(tonumber(amount) or 0)
        if amount > 0 and RexDiner.GetItemCount(source, item) < amount then
            return false, item
        end
    end
    return true
end

---@param source number
---@param item string
---@param count number
---@param metadata table|nil
---@return boolean
function RexDiner.AddItem(source, item, count, metadata)
    count = math.floor(tonumber(count) or 0)
    if count <= 0 then return false end
    return exports.ox_inventory:AddItem(source, item, count, metadata) == true
end

---@param source number
---@param item string
---@param count number
---@return boolean
function RexDiner.RemoveItem(source, item, count)
    count = math.floor(tonumber(count) or 0)
    if count <= 0 then return false end
    return exports.ox_inventory:RemoveItem(source, item, count) == true
end

---@param source number
---@param items table<string, number>
---@return boolean
function RexDiner.RemoveItems(source, items)
    local removed = {}
    for item, amount in pairs(items) do
        amount = math.floor(tonumber(amount) or 0)
        if amount > 0 then
            if not RexDiner.RemoveItem(source, item, amount) then
                for i = 1, #removed do
                    RexDiner.AddItem(source, removed[i].item, removed[i].count)
                end
                return false
            end
            removed[#removed + 1] = { item = item, count = amount }
        end
    end
    return true
end

---@param source number
---@param moneyType string
---@return number
function RexDiner.GetMoney(source, moneyType)
    return exports.qbx_core:GetMoney(source, moneyType) or 0
end

---@param source number
---@param moneyType string
---@param amount number
---@param reason string
---@return boolean
function RexDiner.RemoveMoney(source, moneyType, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    return exports.qbx_core:RemoveMoney(source, moneyType, amount, reason) == true
end

---@param source number
---@param moneyType string
---@param amount number
---@param reason string
---@return boolean
function RexDiner.AddMoney(source, moneyType, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    return exports.qbx_core:AddMoney(source, moneyType, amount, reason) == true
end

---@param account string
---@param amount number
---@param reason string
function RexDiner.AddSocietyMoney(account, amount, reason)
    if not Config.EnableSocietyAccount then return end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return end
    pcall(function()
        exports['Renewed-Banking']:addAccountMoney(account, amount)
    end)
    pcall(function()
        exports.qbx_management:AddMoney(account, amount)
    end)
    debugPrint('Society deposit', account, amount, reason)
end

---@param restaurantKey string
---@return string
function RexDiner.SocietyAccount(restaurantKey)
    local restaurant = GetRestaurant(restaurantKey)
    local job = restaurant and restaurant.job or restaurantKey
    return Config.SocietyAccountPrefix .. job
end

---@param amount number
---@return string
function RexDiner.FormatMoney(amount)
    amount = math.floor(tonumber(amount) or 0)
    local formatted = tostring(amount):reverse():gsub('(%d%d%d)', '%1 '):reverse():gsub('^ ', '')
    return formatted .. ' ' .. (Config.Currency or '$')
end

---@param restaurantKey string
function RexDiner.EnsureEmployeeRow(restaurantKey, citizenid, name, grade)
    MySQL.insert.await([[
        INSERT INTO rex_diner_employees (restaurant, identifier, name, grade)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE name = VALUES(name), grade = VALUES(grade)
    ]], { restaurantKey, citizenid, name or '', grade or 0 })
end

---@param source number
---@param title string
---@param description string
---@param nType string|nil
function RexDiner.Notify(source, title, description, nType)
    TriggerClientEvent('ox_lib:notify', source, {
        title = title,
        description = description,
        type = nType or 'inform',
        duration = 6000,
    })
end

--- Online players map (citizenid helpers)
---@return table
function RexDiner.GetOnlinePlayers()
    local ok, players = pcall(function()
        return exports.qbx_core:GetQBPlayers()
    end)
    if ok and type(players) == 'table' then
        return players
    end

    local fallback = {}
    for _, id in ipairs(GetPlayers()) do
        local src = tonumber(id)
        if src then
            local player = RexDiner.GetPlayer(src)
            if player then
                fallback[src] = player
            end
        end
    end
    return fallback
end

AddEventHandler('playerDropped', function()
    local src = source
    RexDiner.ServiceCache[src] = nil
    RexDiner.ActiveCrafts[src] = nil
    RexDiner.ActiveDeliveries[src] = nil
    for key in pairs(RexDiner.Cooldowns) do
        if key:find(('^%s:'):format(src)) then
            RexDiner.Cooldowns[key] = nil
        end
    end
end)

CreateThread(function()
    Wait(1000)
    for key in pairs(Config.Restaurants) do
        if RexDiner.InitStock then
            RexDiner.InitStock(key)
        end
    end
    print('[rex_diner] Resource démarrée — restaurants:', json.encode((function()
        local keys = {}
        for k in pairs(Config.Restaurants) do keys[#keys + 1] = k end
        return keys
    end)()))
end)
