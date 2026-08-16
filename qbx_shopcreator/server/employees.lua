ShopCreator = ShopCreator or {}

local Repo = ShopCreator.Repository

---@param source number
---@param shopId number
---@param citizenid string
---@param name string|nil
---@return table
function ShopCreator.HireEmployee(source, shopId, citizenid, name)
    shopId = tonumber(shopId)
    if not ShopCreator.HasShopPermission(source, shopId, 'manage_employees') then
        return { ok = false, error = ShopCreator.L('no_permission') }
    end

    citizenid = ShopCreator.SanitizeString(citizenid, 64)
    if not citizenid then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    if ShopCreator.IsOwner(source, shopId) and ShopCreator.GetCitizenId(source) == citizenid then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    local shop = ShopCreator.Cache.shops[shopId]
    if not shop then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    if Repo.CountEmployees(shopId) >= Config.MaxEmployeesPerShop then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    if ShopCreator.GetEmployee(shopId, citizenid) then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    name = ShopCreator.SanitizeString(name, 96) or citizenid
    local permissions = ShopCreator.DeepCopy(ShopCreator.DefaultPermissions)

    local employeeId = Repo.InsertEmployee(shopId, citizenid, name, permissions)
    ShopCreator.ReloadShop(shopId)

    ShopCreator.Log('employee_hired', {
        shopId = shopId,
        employeeId = employeeId,
        citizenid = citizenid,
        by = ShopCreator.GetCitizenId(source),
    })

    ShopCreator.Notify(source, ShopCreator.L('employee_hired'), 'success')

    local employee = ShopCreator.GetEmployee(shopId, citizenid)
    return { ok = true, data = employee }
end

---@param source number
---@param shopId number
---@param employeeId number
---@return table
function ShopCreator.FireEmployee(source, shopId, employeeId)
    shopId = tonumber(shopId)
    employeeId = tonumber(employeeId)

    if not ShopCreator.HasShopPermission(source, shopId, 'manage_employees') then
        return { ok = false, error = ShopCreator.L('no_permission') }
    end

    local shop = ShopCreator.Cache.shops[shopId]
    if not shop then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    local target
    for i = 1, #(shop.employees or {}) do
        if shop.employees[i].id == employeeId then
            target = shop.employees[i]
            break
        end
    end

    if not target or not target.active then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    if shop.owner_citizenid == target.citizenid then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    Repo.FireEmployee(employeeId, shopId)
    ShopCreator.ReloadShop(shopId)

    ShopCreator.Log('employee_fired', {
        shopId = shopId,
        employeeId = employeeId,
        by = ShopCreator.GetCitizenId(source),
    })

    ShopCreator.Notify(source, ShopCreator.L('employee_fired'), 'success')
    return { ok = true }
end

---@param source number
---@param shopId number
---@param employeeId number
---@param permissions table
---@return table
function ShopCreator.UpdateEmployeePermissions(source, shopId, employeeId, permissions)
    shopId = tonumber(shopId)
    employeeId = tonumber(employeeId)

    if not ShopCreator.HasShopPermission(source, shopId, 'manage_permissions') then
        return { ok = false, error = ShopCreator.L('no_permission') }
    end

    local shop = ShopCreator.Cache.shops[shopId]
    if not shop then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    local target
    for i = 1, #(shop.employees or {}) do
        if shop.employees[i].id == employeeId then
            target = shop.employees[i]
            break
        end
    end

    if not target or not target.active then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    if shop.owner_citizenid == target.citizenid then
        return { ok = false, error = ShopCreator.L('no_permission') }
    end

    local normalized = ShopCreator.NormalizePermissions(permissions)
    Repo.UpdateEmployeePermissions(employeeId, shopId, normalized)
    ShopCreator.ReloadShop(shopId)

    ShopCreator.Log('employee_permissions', {
        shopId = shopId,
        employeeId = employeeId,
        by = ShopCreator.GetCitizenId(source),
    })

    return { ok = true, data = normalized }
end
