--[[
    Bridge inventaire pour les clés véhicules.
    Supporte ox_inventory (métadonnées plate) et ESX (item générique + meta si dispo).
]]

Core.Inventory = Core.Inventory or {}

local function invCfg()
    return (Config.Keys and Config.Keys.inventory) or {}
end

function Core.Inventory.GetSystem()
    local mode = invCfg().system or 'auto'
    if mode == 'ox' or (mode == 'auto' and GetResourceState('ox_inventory') == 'started') then
        return 'ox'
    end
    if mode == 'esx' or mode == 'auto' then
        return 'esx'
    end
    return 'none'
end

function Core.Inventory.ItemName()
    return invCfg().item or 'vehicle_key'
end

function Core.Inventory.Enabled()
    return Config.Keys and Config.Keys.enabled and invCfg().enabled ~= false
end

---@param src number
---@param plate string
---@return number count
function Core.Inventory.CountVehicleKeys(src, plate)
    if not Core.Inventory.Enabled() then return 0 end
    plate = Core.NormalizePlate(plate)
    local item = Core.Inventory.ItemName()
    local system = Core.Inventory.GetSystem()

    if system == 'ox' then
        local count = exports.ox_inventory:Search(src, 'count', item, { plate = plate })
        return tonumber(count) or 0
    end

    if system == 'esx' then
        local xPlayer = Core.GetPlayer(src)
        if not xPlayer then return 0 end
        -- ESX Legacy peut stocker metadata sur l'item
        local inv = xPlayer.getInventory and xPlayer.getInventory() or {}
        local total = 0
        for _, entry in pairs(inv) do
            if entry and entry.name == item and (entry.count or 0) > 0 then
                local meta = entry.metadata or entry.info or {}
                local p = Core.NormalizePlate(meta.plate or meta.Plate or '')
                if p == plate or p == '' then
                    -- sans metadata : on compte 1 max pour compat (clé générique)
                    if p == plate then
                        total = total + (entry.count or 1)
                    end
                end
            end
        end
        return total
    end

    return 0
end

---@param src number
---@param plate string
---@return boolean
function Core.Inventory.HasVehicleKey(src, plate)
    return Core.Inventory.CountVehicleKeys(src, plate) > 0
end

---@param src number
---@param plate string
---@param label? string
---@param count? number
---@return boolean success
function Core.Inventory.AddVehicleKey(src, plate, label, count)
    if not Core.Inventory.Enabled() then return false end
    plate = Core.NormalizePlate(plate)
    if plate == '' then return false end

    count = math.max(1, tonumber(count) or 1)
    local item = Core.Inventory.ItemName()
    local system = Core.Inventory.GetSystem()
    local meta = {
        plate = plate,
        label = ('Clé %s'):format(label or plate),
        description = ('Clé du véhicule %s'):format(plate),
    }

    if system == 'ox' then
        local ok = exports.ox_inventory:AddItem(src, item, count, meta)
        return ok and true or false
    end

    if system == 'esx' then
        local xPlayer = Core.GetPlayer(src)
        if not xPlayer then return false end
        -- ESX Legacy 1.9+ : metadata en 3e/4e arg selon version
        local ok = pcall(function()
            xPlayer.addInventoryItem(item, count, meta)
        end)
        if not ok then
            xPlayer.addInventoryItem(item, count)
        end
        return true
    end

    return false
end

---@param src number
---@param plate string
---@param count? number
---@return boolean
function Core.Inventory.RemoveVehicleKey(src, plate, count)
    if not Core.Inventory.Enabled() then return false end
    plate = Core.NormalizePlate(plate)
    count = math.max(1, tonumber(count) or 1)
    local item = Core.Inventory.ItemName()
    local system = Core.Inventory.GetSystem()

    if system == 'ox' then
        return exports.ox_inventory:RemoveItem(src, item, count, { plate = plate }) and true or false
    end

    if system == 'esx' then
        local xPlayer = Core.GetPlayer(src)
        if not xPlayer then return false end
        xPlayer.removeInventoryItem(item, count)
        return true
    end

    return false
end
