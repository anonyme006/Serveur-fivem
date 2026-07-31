local function isWeaponName(name)
    if not name then return false end
    return name:find('weapon_', 1, true) == 1 or name:find('WEAPON_', 1, true) == 1
end

local function countWeapons(src)
    local items = exports.ox_inventory:GetInventoryItems(src) or {}
    local n = 0
    for _, item in pairs(items) do
        if item and isWeaponName(item.name) then
            n = n + (item.count or 1)
        end
    end
    return n
end

CreateThread(function()
    if not exports.ox_inventory or not exports.ox_inventory.registerHook then
        print('[vibe_inventory_restrictions] registerHook indisponible — module inactif')
        return
    end

    exports.ox_inventory:registerHook('swapItems', function(payload)
        local src = payload.source
        local item = payload.fromSlot and payload.fromSlot.name
        if not item and payload.items then
            item = payload.items[1] and payload.items[1].name
        end
        if not item then return true end

        local restrict = Config.JobItems[item]
        if restrict then
            local job = exports.vibe_api:GetJob(src)
            if not job or not restrict[job.name] or not job.onduty then
                exports.vibe_api:Notify(src, 'Inventaire', 'Item reserve a un metier en service.', 'error')
                return false
            end
        end

        local isWeapon = item:find('weapon_', 1, true) == 1 or item:find('WEAPON_', 1, true) == 1
        if isWeapon and countWeapons(src) >= Config.MaxWeapons then
            exports.vibe_api:Notify(src, 'Inventaire', 'Limite d armes atteinte.', 'error')
            return false
        end
        return true
    end, {})
end)
