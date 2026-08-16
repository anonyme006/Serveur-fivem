ShopCreator = ShopCreator or {}

local Repo = ShopCreator.Repository

---@return table
function ShopCreator.ReloadAdmins()
    local list, map = Repo.LoadAdmins()
    ShopCreator.AdminList = map
    ShopCreator.AdminEntries = list
    return list
end

---@param source number
---@param identifier string
---@param label string|nil
---@return table
function ShopCreator.AddAdmin(source, identifier, label)
    if not ShopCreator.IsAdmin(source) then
        return { ok = false, error = ShopCreator.L('no_permission') }
    end

    identifier = ShopCreator.SanitizeString(identifier, 128)
    if not identifier then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    if Repo.AdminExists(identifier) then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    label = ShopCreator.SanitizeString(label, 96) or identifier
    local id = Repo.InsertAdmin(identifier, label)
    ShopCreator.ReloadAdmins()

    ShopCreator.Log('admin_added', { id = id, identifier = identifier, by = ShopCreator.GetCitizenId(source) })
    return { ok = true, data = { id = id, identifier = identifier, label = label } }
end

---@param source number
---@param adminId number
---@return table
function ShopCreator.RemoveAdmin(source, adminId)
    if not ShopCreator.IsAdmin(source) then
        return { ok = false, error = ShopCreator.L('no_permission') }
    end

    adminId = tonumber(adminId)
    if not adminId then
        return { ok = false, error = ShopCreator.L('invalid_data') }
    end

    Repo.DeleteAdmin(adminId)
    ShopCreator.ReloadAdmins()

    ShopCreator.Log('admin_removed', { id = adminId, by = ShopCreator.GetCitizenId(source) })
    return { ok = true }
end

---@param source number
---@return table
function ShopCreator.ListShopsAdmin(source)
    if not ShopCreator.IsAdmin(source) then
        return { ok = false, error = ShopCreator.L('no_permission') }
    end

    local summaries = {}
    for _, shop in pairs(ShopCreator.Cache.shops) do
        summaries[#summaries + 1] = ShopCreator.BuildSummary(shop)
    end

    table.sort(summaries, function(a, b) return a.id < b.id end)
    return { ok = true, data = summaries }
end

local function bootstrap()
    if ServerConfig.AutoMigrate then
        local ok, err = pcall(Repo.RunMigration)
        if not ok then
            ShopCreator.Log('migration_failed', { error = tostring(err) })
        end
    end

    ShopCreator.AdminList = {}
    ShopCreator.AdminEntries = {}
    ShopCreator.ReloadAdmins()
    ShopCreator.LoadSettings()
    ShopCreator.LoadShopsIntoCache()

    ShopCreator.Log('resource_started', {
        shops = #(Repo.LoadShopRows() or {}),
        admins = #(ShopCreator.AdminEntries or {}),
    })
end

local function syncPlayer(source)
    if not source or source <= 0 then return end
    while not ShopCreator.Cache.ready do
        Wait(100)
    end
    ShopCreator.SyncAllPublicShops(source)
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= ShopCreator.Resource then return end
    CreateThread(bootstrap)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= ShopCreator.Resource then return end
    ShopCreator.Cache.shops = {}
    ShopCreator.Cache.ready = false
    ShopCreator.Garage.active = {}
end)

AddEventHandler('playerJoining', function()
    local src = source
    CreateThread(function()
        Wait(2000)
        syncPlayer(src)
    end)
end)

RegisterNetEvent('qbx_shopcreator:server:requestShops', function()
    syncPlayer(source)
end)

AddEventHandler('QBCore:Server:OnPlayerLoaded', function()
    syncPlayer(source)
end)

AddEventHandler('qbx_core:server:playerLoaded', function(player)
    if type(player) == 'table' and player.PlayerData and player.PlayerData.source then
        syncPlayer(player.PlayerData.source)
    end
end)

CreateThread(function()
    if GetResourceState(ShopCreator.Resource) == 'started' then
        bootstrap()
    end
end)
