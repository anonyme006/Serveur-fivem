ShopCreator = ShopCreator or {}

---@param source number
---@param shopId number
---@return boolean
function ShopCreator.IsOwner(source, shopId)
    shopId = tonumber(shopId)
    if not shopId then return false end

    local shop = ShopCreator.Cache.shops[shopId]
    if not shop or shop.ownership_mode ~= 'owned' then
        return false
    end

    local citizenid = ShopCreator.GetCitizenId(source)
    return citizenid ~= nil and shop.owner_citizenid == citizenid
end

---@param shopId number
---@param citizenid string
---@return table|nil
function ShopCreator.GetEmployee(shopId, citizenid)
    shopId = tonumber(shopId)
    if not shopId or not citizenid then return nil end

    local shop = ShopCreator.Cache.shops[shopId]
    if not shop then return nil end

    for i = 1, #(shop.employees or {}) do
        local emp = shop.employees[i]
        if emp.active and emp.citizenid == citizenid then
            return emp
        end
    end

    return nil
end

---@param source number
---@param shopId number
---@return table|nil
function ShopCreator.GetEmployeeBySource(source, shopId)
    local citizenid = ShopCreator.GetCitizenId(source)
    if not citizenid then return nil end
    return ShopCreator.GetEmployee(shopId, citizenid)
end

---@param source number
---@param shopId number
---@return table
function ShopCreator.GetEffectivePermissions(source, shopId)
    if ShopCreator.IsAdmin(source) or ShopCreator.IsOwner(source, shopId) then
        return ShopCreator.DeepCopy(ShopCreator.OwnerPermissions)
    end

    local employee = ShopCreator.GetEmployeeBySource(source, shopId)
    if employee then
        return ShopCreator.DeepCopy(employee.permissions)
    end

    return ShopCreator.DeepCopy(ShopCreator.DefaultPermissions)
end

---@param source number
---@param shopId number
---@param permKey string
---@return boolean
function ShopCreator.HasShopPermission(source, shopId, permKey)
    if ShopCreator.IsAdmin(source) then
        return true
    end

    if ShopCreator.IsOwner(source, shopId) then
        return true
    end

    local perms = ShopCreator.GetEffectivePermissions(source, shopId)
    return perms[permKey] == true
end
