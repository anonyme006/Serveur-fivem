if not Config.KeyShop or not Config.KeyShop.enabled then return end

local function getOwnedPlates(identifier)
    local cols = Config.Persistence.columns
    return MySQL.query.await(
        ('SELECT `%s` AS plate, `%s` AS vehicle FROM `%s` WHERE `%s` = ?'):format(
            cols.plate, cols.vehicle, cols.table, cols.owner
        ),
        { identifier }
    ) or {}
end

lib.callback.register('esx_core:keyshop:list', function(source)
    local xPlayer = Core.GetPlayer(source)
    if not xPlayer then return {} end

    local rows = getOwnedPlates(xPlayer.identifier)
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

lib.callback.register('esx_core:keyshop:buy', function(source, plate)
    local xPlayer = Core.GetPlayer(source)
    if not xPlayer then return false, 'cover_busy' end

    plate = Core.NormalizePlate(plate)
    if plate == '' then return false, 'key_no_vehicle' end

    local cols = Config.Persistence.columns
    local owned = MySQL.single.await(
        ('SELECT 1 FROM `%s` WHERE `%s` = ? AND REPLACE(UPPER(`%s`), " ", "") = ? LIMIT 1'):format(
            cols.table, cols.owner, cols.plate
        ),
        { xPlayer.identifier, plate }
    )
    if not owned then return false, 'used_not_owner' end

    local maxKeys = tonumber(Config.KeyShop.maxKeysPerPlate) or 3
    if Core.Inventory and Core.Inventory.Enabled() then
        local have = Core.Inventory.CountVehicleKeys(source, plate)
        if have >= maxKeys then
            return false, 'keyshop_max', maxKeys
        end
    end

    local price = tonumber(Config.KeyShop.price) or 750
    local account = Config.KeyShop.account or 'bank'
    local bal = xPlayer.getAccount(account)
    if not bal or (bal.money or 0) < price then
        return false, 'used_no_money'
    end

    xPlayer.removeAccountMoney(account, price)

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
        xPlayer.addAccountMoney(account, price)
        return false, 'keyshop_inventory_full'
    end

    return true, 'keyshop_bought', plate, price
end)
