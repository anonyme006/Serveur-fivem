ShopCreator = ShopCreator or {}

local rateBuckets = {}

---@param source number
---@param key string
---@param windowMs? number
---@return boolean
function ShopCreator.RateLimit(source, key, windowMs)
    windowMs = windowMs or Config.RateLimit.windowMs
    local now = GetGameTimer()
    local bucketKey = ('%s:%s'):format(source, key)
    local last = rateBuckets[bucketKey] or 0
    if now - last < windowMs then
        return false
    end
    rateBuckets[bucketKey] = now
    return true
end

AddEventHandler('playerDropped', function()
    local src = source
    for key in pairs(rateBuckets) do
        if key:find('^' .. src .. ':') then
            rateBuckets[key] = nil
        end
    end
end)

---@param source number
---@return table|nil
function ShopCreator.GetPlayer(source)
    return exports.qbx_core:GetPlayer(source)
end

---@param source number
---@return string|nil
function ShopCreator.GetCitizenId(source)
    local player = ShopCreator.GetPlayer(source)
    if not player then return nil end
    return player.PlayerData.citizenid
end

---@param source number
---@return string
function ShopCreator.GetPlayerName(source)
    local player = ShopCreator.GetPlayer(source)
    if not player then return GetPlayerName(source) or 'Unknown' end
    local ci = player.PlayerData.charinfo or {}
    local name = ((ci.firstname or '') .. ' ' .. (ci.lastname or '')):match('^%s*(.-)%s*$')
    if name == '' then
        return GetPlayerName(source) or 'Unknown'
    end
    return name
end

---@param source number
---@return boolean
function ShopCreator.IsAdmin(source)
    if type(source) ~= 'number' or source <= 0 then return false end

    if IsPlayerAceAllowed(source, Config.AdminAce) then
        return true
    end

    for i = 1, #(Config.AdminPermissions or {}) do
        local perm = Config.AdminPermissions[i]
        local ok, has = pcall(function()
            return exports.qbx_core:HasPermission(source, perm)
        end)
        if ok and has then
            return true
        end
    end

    local citizenid = ShopCreator.GetCitizenId(source)
    if citizenid and ShopCreator.AdminList and ShopCreator.AdminList[citizenid] then
        return true
    end

    local license = GetPlayerIdentifierByType(source, 'license')
    if license and ShopCreator.AdminList and ShopCreator.AdminList[license] then
        return true
    end

    return false
end

---@param source number
---@param amount number
---@param account 'cash'|'bank'
---@param reason string
---@return boolean
function ShopCreator.RemoveMoney(source, amount, account, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    account = account == 'bank' and 'bank' or 'cash'
    local ok, success = pcall(function()
        return exports.qbx_core:RemoveMoney(source, account, amount, reason or 'shopcreator')
    end)
    if ok then return success and true or false end

    local player = ShopCreator.GetPlayer(source)
    if not player then return false end
    return player.Functions.RemoveMoney(account, amount, reason or 'shopcreator') and true or false
end

---@param source number
---@param amount number
---@param account 'cash'|'bank'
---@param reason string
---@return boolean
function ShopCreator.AddMoney(source, amount, account, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    account = account == 'bank' and 'bank' or 'cash'
    local ok, success = pcall(function()
        return exports.qbx_core:AddMoney(source, account, amount, reason or 'shopcreator')
    end)
    if ok then return success and true or false end

    local player = ShopCreator.GetPlayer(source)
    if not player then return false end
    return player.Functions.AddMoney(account, amount, reason or 'shopcreator') and true or false
end

---@param source number
---@param account 'cash'|'bank'
---@return number
function ShopCreator.GetMoney(source, account)
    account = account == 'bank' and 'bank' or 'cash'
    local ok, amount = pcall(function()
        return exports.qbx_core:GetMoney(source, account)
    end)
    if ok and type(amount) == 'number' then return amount end

    local player = ShopCreator.GetPlayer(source)
    if not player then return 0 end
    return player.Functions.GetMoney(account) or 0
end

---@param itemName string
---@return boolean
function ShopCreator.ItemExists(itemName)
    itemName = ShopCreator.SanitizeItemName(itemName)
    if not itemName then return false end
    local ok, items = pcall(function()
        return exports.ox_inventory:Items(itemName)
    end)
    if ok and items then return true end
    return false
end

---@param itemName string
---@return table|nil
function ShopCreator.GetItemData(itemName)
    itemName = ShopCreator.SanitizeItemName(itemName)
    if not itemName then return nil end
    local ok, item = pcall(function()
        return exports.ox_inventory:Items(itemName)
    end)
    if ok and type(item) == 'table' then return item end
    return nil
end

---@param source number
---@param message string
---@param nType? string
function ShopCreator.Notify(source, message, nType)
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Shop Creator',
        description = message,
        type = nType or 'inform',
    })
end

---@param key string
---@return string
function ShopCreator.L(key)
    local locale = Locales[Config.Locale] or Locales.fr or {}
    return locale[key] or key
end