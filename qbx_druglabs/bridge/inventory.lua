Bridge = Bridge or {}

---@param source number
---@param item string
---@param count number|nil
---@return number
function Bridge.GetItemCount(source, item, count)
    count = count or 1
    local result = exports.ox_inventory:Search(source, 'count', item)
    return tonumber(result) or 0
end

---@param source number
---@param items table<string, number>
---@return boolean, string|nil missingItem
function Bridge.HasItems(source, items)
    if type(items) ~= 'table' then return true end
    for item, amount in pairs(items) do
        amount = math.floor(tonumber(amount) or 0)
        if amount > 0 and Bridge.GetItemCount(source, item) < amount then
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
function Bridge.AddItem(source, item, count, metadata)
    count = math.floor(tonumber(count) or 0)
    if count <= 0 or not DrugLabs.IsNonEmptyString(item) then return false end
    return exports.ox_inventory:AddItem(source, item, count, metadata) == true
end

---@param source number
---@param item string
---@param count number
---@param metadata table|nil
---@param slot number|nil
---@return boolean
function Bridge.RemoveItem(source, item, count, metadata, slot)
    count = math.floor(tonumber(count) or 0)
    if count <= 0 or not DrugLabs.IsNonEmptyString(item) then return false end
    return exports.ox_inventory:RemoveItem(source, item, count, metadata, slot) == true
end

---@param source number
---@param items table<string, number>
---@return boolean
function Bridge.RemoveItems(source, items)
    if type(items) ~= 'table' then return true end
    local removed = {}
    for item, amount in pairs(items) do
        amount = math.floor(tonumber(amount) or 0)
        if amount > 0 then
            if not Bridge.RemoveItem(source, item, amount) then
                for i = 1, #removed do
                    Bridge.AddItem(source, removed[i].item, removed[i].count)
                end
                return false
            end
            removed[#removed + 1] = { item = item, count = amount }
        end
    end
    return true
end

---@param source number
---@param item string
---@return table|nil slotData
function Bridge.GetItemWithMetadata(source, item)
    local slots = exports.ox_inventory:Search(source, 'slots', item)
    if type(slots) ~= 'table' then return nil end
    for _, slot in pairs(slots) do
        if slot and slot.name == item then
            return slot
        end
    end
    return nil
end

---@param labId number
---@return string
function Bridge.GetStashId(labId)
    return ('druglab_%s_storage'):format(labId)
end

---@param labId number
---@param slots number
---@param weight number
---@param label string
function Bridge.RegisterStash(labId, slots, weight, label)
    local stashId = Bridge.GetStashId(labId)
    exports.ox_inventory:RegisterStash(stashId, label or ('Lab #%s'):format(labId), slots or 50, weight or 200000, false)
    return stashId
end

---@param source number
---@param labId number
function Bridge.OpenStash(source, labId)
    local stashId = Bridge.GetStashId(labId)
    exports.ox_inventory:forceOpenInventory(source, 'stash', stashId)
end

---@param item string
---@return boolean
function Bridge.ItemExists(item)
    if not DrugLabs.IsNonEmptyString(item) then return false end
    local ok, result = pcall(function()
        return exports.ox_inventory:Items(item)
    end)
    return ok and result ~= nil
end

---@param source number
---@param items table<string, number>
---@return boolean
function Bridge.CanCarryItems(source, items)
    if type(items) ~= 'table' then return true end
    for item, amount in pairs(items) do
        amount = math.floor(tonumber(amount) or 0)
        if amount > 0 then
            local can = exports.ox_inventory:CanCarryItem(source, item, amount)
            if not can then return false end
        end
    end
    return true
end
