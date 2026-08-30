if Config.Modules and Config.Modules.core == false then return end

if not Config.KeyShop or not Config.KeyShop.enabled then return end

local function getOwnedPlates(citizenid)
    local cols = Config.Persistence.columns
    return MySQL.query.await(
        ('SELECT `%s` AS plate, `%s` AS vehicle FROM `%s` WHERE `%s` = ?'):format(
            cols.plate, cols.vehicle, cols.table, cols.owner
        ),
        { citizenid }
    ) or {}
end

lib.callback.register('qbx_ressources:keyshop:list', function(source)
    local citizenid = Core.GetIdentifier(source)
    if not citizenid then return {} end

    local rows = getOwnedPlates(citizenid)
    local list = {}
    for _, row in ipairs(rows) do
        local plate = Core.NormalizePlate(row.plate)
        local props = Core.DecodeJson(row.vehicle)
        local count = 0
        if Core.Inventory and Core.Inventory.Enabled() then
            count = Core.Inventory.CountVehicleKeys(source, plate)
        end
        list[#list + 1] = {
            plate = plate,
            label = plate,
            model = props.model,
            keys = count,
        }
    end
    table.sort(list, function(a, b) return a.plate < b.plate end)
    return list
end)

lib.callback.register('qbx_ressources:keyshop:buy', function(source, plate)
    local citizenid = Core.GetIdentifier(source)
    if not citizenid then return false, 'cover_busy' end

    plate = Core.NormalizePlate(plate)
    if plate == '' then return false, 'key_no_vehicle' end

    local cols = Config.Persistence.columns
    local owned = MySQL.single.await(
        ('SELECT 1 FROM `%s` WHERE `%s` = ? AND REPLACE(UPPER(`%s`), " ", "") = ? LIMIT 1'):format(
            cols.table, cols.owner, cols.plate
        ),
        { citizenid, plate }
    )
    if not owned then return false, 'used_not_owner' end

    local maxKeys = tonumber(Config.KeyShop.maxKeysPerPlate) or 3
    if Core.Inventory and Core.Inventory.Enabled() then
        local have = Core.Inventory.CountVehicleKeys(source, plate)
        if have >= maxKeys then
            return false, 'keyshop_max', maxKeys
        end
    end

    local price = tonumber(Config.KeyShop.price) or 100
    local account = Core.NormalizeAccount(Config.KeyShop.account or 'bank')
    if Core.GetMoney(source, account) < price then
        return false, 'used_no_money'
    end

    if not Core.RemoveMoney(source, account, price, 'keyshop') then
        return false, 'used_no_money'
    end

    local before = 0
    if Core.Inventory and Core.Inventory.Enabled() then
        before = Core.Inventory.CountVehicleKeys(source, plate)
    end

    Core.EnsureVehicleKey(source, plate, plate, 'key_shop')

    local after = before
    if Core.Inventory and Core.Inventory.Enabled() then
        after = Core.Inventory.CountVehicleKeys(source, plate)
    end

    if after <= before then
        Core.AddMoney(source, account, price, 'keyshop-refund')
        return false, 'keyshop_inventory_full'
    end

    if Core.Log then
        Core.Log('money', '🛒 Achat clé serrurier', ('Plaque `%s` — **%s$** (%s)'):format(plate, price, account), {
            color = 'money',
            src = source,
        })
    end

    return true, 'keyshop_bought', plate, price
end)
