if Config.Modules and Config.Modules.core == false then return end

--[[
    Bridge inventaire clés — ox_inventory (QBox)
]]

Core.Inventory = Core.Inventory or {}

local function invCfg()
    return (Config.Keys and Config.Keys.inventory) or {}
end

function Core.Inventory.GetSystem()
    if GetResourceState('ox_inventory') == 'started' then
        return 'ox'
    end
    return 'none'
end

function Core.Inventory.ItemName()
    return invCfg().item or 'vehicle_key'
end

function Core.Inventory.Enabled()
    return Config.Keys and Config.Keys.enabled and invCfg().enabled ~= false
end

function Core.Inventory.CountVehicleKeys(src, plate)
    if not Core.Inventory.Enabled() then return 0 end
    plate = Core.NormalizePlate(plate)
    local item = Core.Inventory.ItemName()
    if Core.Inventory.GetSystem() ~= 'ox' then return 0 end
    local count = exports.ox_inventory:Search(src, 'count', item, { plate = plate })
    return tonumber(count) or 0
end

function Core.Inventory.HasVehicleKey(src, plate)
    return Core.Inventory.CountVehicleKeys(src, plate) > 0
end

function Core.Inventory.AddVehicleKey(src, plate, label, count)
    if not Core.Inventory.Enabled() then return false end
    plate = Core.NormalizePlate(plate)
    if plate == '' then return false end
    if Core.Inventory.GetSystem() ~= 'ox' then return false end

    count = math.max(1, tonumber(count) or 1)
    local item = Core.Inventory.ItemName()
    local meta = {
        plate = plate,
        label = ('Clé %s'):format(label or plate),
        description = ('Clé du véhicule %s'):format(plate),
    }
    local ok = exports.ox_inventory:AddItem(src, item, count, meta)
    return ok and true or false
end

function Core.Inventory.RemoveVehicleKey(src, plate, count)
    if not Core.Inventory.Enabled() then return false end
    plate = Core.NormalizePlate(plate)
    count = math.max(1, tonumber(count) or 1)
    if Core.Inventory.GetSystem() ~= 'ox' then return false end
    return exports.ox_inventory:RemoveItem(src, Core.Inventory.ItemName(), count, { plate = plate }) and true or false
end
