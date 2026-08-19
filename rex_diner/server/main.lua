Rex = Rex or {}
Rex.Service = {}       ---@type table<number, { restaurant: string, startedAt: number }>
Rex.Cooldowns = {}     ---@type table<string, number>
Rex.ActiveCrafts = {}  ---@type table<number, boolean>
Rex.ActiveDeliveries = {} ---@type table<number, number>

---@param source number
---@return table|nil
function Rex.GetPlayer(source)
    return exports.qbx_core:GetPlayer(source)
end

---@param source number
---@return string|nil
function Rex.GetCitizenId(source)
    local player = Rex.GetPlayer(source)
    return player and player.PlayerData and player.PlayerData.citizenid or nil
end

---@param source number
---@return string
function Rex.GetName(source)
    local player = Rex.GetPlayer(source)
    if not player or not player.PlayerData or not player.PlayerData.charinfo then
        return GetPlayerName(source) or ('ID %s'):format(source)
    end
    local c = player.PlayerData.charinfo
    return ('%s %s'):format(c.firstname or '', c.lastname or ''):gsub('%s+', ' '):gsub('^%s*(.-)%s*$', '%1')
end

---@param source number
---@return string, string
function Rex.GetNames(source)
    local player = Rex.GetPlayer(source)
    if not player or not player.PlayerData or not player.PlayerData.charinfo then
        return '', ''
    end
    return player.PlayerData.charinfo.firstname or '', player.PlayerData.charinfo.lastname or ''
end

---@param source number
---@return string|nil, number, boolean
function Rex.GetJob(source)
    local player = Rex.GetPlayer(source)
    if not player or not player.PlayerData or not player.PlayerData.job then
        return nil, 0, false
    end
    local job = player.PlayerData.job
    return job.name, job.grade and job.grade.level or 0, job.onduty == true
end

---@param source number
---@return string|nil, table|nil, number, boolean
function Rex.GetContext(source)
    local job, grade, onDuty = Rex.GetJob(source)
    local key, restaurant = Rex.GetRestaurantByJob(job)
    if Rex.Service[source] then
        onDuty = true
    end
    return key, restaurant, grade, onDuty
end

---@param source number
---@param permission string|nil
---@param requireDuty boolean|nil
---@return boolean, string|nil, table|nil
function Rex.Authorize(source, permission, requireDuty)
    local key, restaurant, grade, onDuty = Rex.GetContext(source)
    if not key or not restaurant then
        return false, 'Vous n\'êtes pas employé de ce restaurant.'
    end
    if requireDuty ~= false and not onDuty then
        return false, 'Vous devez être en service.'
    end
    if permission and not Rex.HasPermission(grade, permission) then
        return false, 'Permission insuffisante.'
    end
    return true, nil, {
        key = key,
        restaurant = restaurant,
        grade = grade,
        onDuty = onDuty,
        citizenid = Rex.GetCitizenId(source),
        name = Rex.GetName(source),
    }
end

---@param source number
---@param action string
---@return boolean
function Rex.Cooldown(source, action)
    local seconds = Config.Cooldowns[action] or 2
    local key = ('%s:%s'):format(source, action)
    local now = os.time()
    if (Rex.Cooldowns[key] or 0) + seconds > now then
        return false
    end
    Rex.Cooldowns[key] = now
    return true
end

function Rex.GetItemCount(source, item)
    return tonumber(exports.ox_inventory:Search(source, 'count', item)) or 0
end

function Rex.HasItems(source, items)
    for item, amount in pairs(items) do
        amount = math.floor(tonumber(amount) or 0)
        if amount > 0 and Rex.GetItemCount(source, item) < amount then
            return false, item
        end
    end
    return true
end

function Rex.AddItem(source, item, count, metadata)
    count = math.floor(tonumber(count) or 0)
    if count <= 0 then return false end
    return exports.ox_inventory:AddItem(source, item, count, metadata) == true
end

function Rex.RemoveItem(source, item, count)
    count = math.floor(tonumber(count) or 0)
    if count <= 0 then return false end
    return exports.ox_inventory:RemoveItem(source, item, count) == true
end

function Rex.RemoveItems(source, items)
    local removed = {}
    for item, amount in pairs(items) do
        amount = math.floor(tonumber(amount) or 0)
        if amount > 0 then
            if not Rex.RemoveItem(source, item, amount) then
                for i = 1, #removed do
                    Rex.AddItem(source, removed[i].item, removed[i].count)
                end
                return false
            end
            removed[#removed + 1] = { item = item, count = amount }
        end
    end
    return true
end

function Rex.GetMoney(source, moneyType)
    return exports.qbx_core:GetMoney(source, moneyType) or 0
end

function Rex.RemoveMoney(source, moneyType, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    return exports.qbx_core:RemoveMoney(source, moneyType, amount, reason) == true
end

function Rex.AddMoney(source, moneyType, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    return exports.qbx_core:AddMoney(source, moneyType, amount, reason) == true
end

function Rex.SocietyAccount(restaurantKey)
    local restaurant = Rex.GetRestaurant(restaurantKey)
    return Config.SocietyAccountPrefix .. (restaurant and restaurant.job or restaurantKey)
end

function Rex.AddSociety(account, amount, reason)
    if not Config.EnableSocietyAccount then return end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return end
    pcall(function() exports['Renewed-Banking']:addAccountMoney(account, amount) end)
    pcall(function() exports.qbx_management:AddMoney(account, amount) end)
    Rex.Debug('society', account, amount, reason)
end

function Rex.Notify(source, title, description, nType)
    TriggerClientEvent('ox_lib:notify', source, {
        title = title,
        description = description,
        type = nType or 'inform',
        duration = 6000,
    })
end

function Rex.EnsureEmployee(restaurantKey, citizenid, name, grade)
    MySQL.insert.await([[
        INSERT INTO rex_diner_employees (restaurant, identifier, name, grade)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE name = VALUES(name), grade = VALUES(grade)
    ]], { restaurantKey, citizenid, name or '', grade or 0 })
end

function Rex.GetOnlinePlayers()
    local ok, players = pcall(function()
        return exports.qbx_core:GetQBPlayers()
    end)
    if ok and type(players) == 'table' then
        return players
    end
    local list = {}
    for _, id in ipairs(GetPlayers()) do
        local src = tonumber(id)
        local player = src and Rex.GetPlayer(src)
        if player then list[src] = player end
    end
    return list
end

---@param source number
---@param maxDist number|nil
---@return table[]
function Rex.GetNearbyPlayers(source, maxDist)
    maxDist = maxDist or Config.PaymentDistance or 5.0
    local ped = GetPlayerPed(source)
    if ped == 0 then return {} end
    local coords = GetEntityCoords(ped)
    local list = {}
    for _, id in ipairs(GetPlayers()) do
        local sid = tonumber(id)
        if sid and sid ~= source then
            local tPed = GetPlayerPed(sid)
            if tPed ~= 0 then
                local dist = #(coords - GetEntityCoords(tPed))
                if dist <= maxDist then
                    list[#list + 1] = {
                        id = sid,
                        name = Rex.GetName(sid),
                        distance = math.floor(dist * 10) / 10,
                    }
                end
            end
        end
    end
    table.sort(list, function(a, b) return a.distance < b.distance end)
    return list
end

AddEventHandler('playerDropped', function()
    local src = source
    Rex.Service[src] = nil
    Rex.ActiveCrafts[src] = nil
    Rex.ActiveDeliveries[src] = nil
    for key in pairs(Rex.Cooldowns) do
        if key:find(('^%s:'):format(src)) then
            Rex.Cooldowns[key] = nil
        end
    end
end)

CreateThread(function()
    Wait(500)
    for key in pairs(Config.Restaurants) do
        if Rex.InitStock then Rex.InitStock(key) end
    end
    print('[rex_diner] v2.0.0 démarré')
end)
