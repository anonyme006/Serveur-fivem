if not Config.Cover.enabled then return end

local covers = {} -- plate -> { owner, coords, props }

local function loadCovers()
    local rows = MySQL.query.await('SELECT * FROM esx_core_covers') or {}
    covers = {}
    for _, row in ipairs(rows) do
        local plate = Core.NormalizePlate(row.plate)
        covers[plate] = {
            owner = row.owner,
            coords = Core.DecodeJson(row.coords),
            props = Core.DecodeJson(row.props),
            plate = plate,
        }
    end
    TriggerClientEvent('esx_core:cover:sync', -1, covers)
end

MySQL.ready(function()
    SetTimeout(2000, loadCovers)
end)

lib.callback.register('esx_core:cover:getAll', function()
    return covers
end)

lib.callback.register('esx_core:cover:put', function(source, plate, coords, props)
    local xPlayer = Core.GetPlayer(source)
    if not xPlayer then return false, 'cover_busy' end

    plate = Core.NormalizePlate(plate)
    if plate == '' or type(coords) ~= 'table' then return false, 'cover_busy' end

    if covers[plate] then return false, 'cover_has' end

    local allowed = false
    if Core.HasKey then
        allowed = Core.HasKey(xPlayer.identifier, 'vehicle', plate)
    end
    if not allowed then
        local cols = Config.Persistence.columns
        local owned = MySQL.single.await(
            ('SELECT 1 FROM `%s` WHERE `%s` = ? AND REPLACE(`%s`, " ", "") = ? LIMIT 1'):format(
                cols.table, cols.owner, cols.plate
            ),
            { xPlayer.identifier, plate }
        )
        allowed = owned ~= nil
    end
    if not allowed then return false, 'key_no_key' end

    MySQL.insert.await(
        'INSERT INTO esx_core_covers (plate, owner, coords, props) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE owner = VALUES(owner), coords = VALUES(coords), props = VALUES(props)',
        { plate, xPlayer.identifier, json.encode(coords), json.encode(props or {}) }
    )

    covers[plate] = {
        owner = xPlayer.identifier,
        coords = coords,
        props = props or {},
        plate = plate,
    }

    -- Marque rangé "street cover" pour ne pas fourrière-reboot si on veut garder la bâche
    -- On laisse stored=0 mais on retire l'entité monde côté client
    Core.SetVehicleStored(plate, true, 'cover')

    TriggerClientEvent('esx_core:cover:sync', -1, covers)
    return true, 'cover_on'
end)

lib.callback.register('esx_core:cover:remove', function(source, plate)
    local xPlayer = Core.GetPlayer(source)
    if not xPlayer then return false, 'cover_busy', nil end

    plate = Core.NormalizePlate(plate)
    local entry = covers[plate]
    if not entry then return false, 'cover_none', nil end

    local allowed = entry.owner == xPlayer.identifier
    if not allowed and Core.HasKey then
        allowed = Core.HasKey(xPlayer.identifier, 'vehicle', plate)
    end
    if not allowed then
        return false, 'key_no_key', nil
    end

    MySQL.update.await('DELETE FROM esx_core_covers WHERE plate = ?', { plate })
    covers[plate] = nil

    Core.SetVehicleStored(plate, false, nil)

    TriggerClientEvent('esx_core:cover:sync', -1, covers)
    return true, 'cover_off', entry
end)

AddEventHandler('playerJoining', function()
    local src = source
    SetTimeout(5000, function()
        TriggerClientEvent('esx_core:cover:sync', src, covers)
    end)
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetTimeout(2500, loadCovers)
end)
