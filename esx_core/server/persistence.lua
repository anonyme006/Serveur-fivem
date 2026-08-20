local ESX = exports['es_extended']:getSharedObject()
local cols = Config.Persistence.columns

local function log(msg)
    if Config.AutoImpound.log then
        print(('^3[esx_core]^0 %s'):format(msg))
    end
end

--- Envoie les véhicules sortis (stored = 0) en fourrière au démarrage.
--- Exclut les véhicules sous bâche / parking occasions.
local function autoImpoundOnBoot()
    if not Config.AutoImpound.enabled then return end

    local impoundId = Config.AutoImpound.impoundId or 'impound_public'
    local tbl = cols.table
    local storedCol = cols.stored
    local parkingCol = cols.parking
    local poundCol = cols.pound

    local rows = MySQL.query.await(([[
        SELECT `%s` AS plate, `%s` AS owner, `%s` AS parking
        FROM `%s`
        WHERE `%s` = 0
          AND (`%s` IS NULL OR `%s` NOT IN ('cover', 'used_parking'))
    ]]):format(
        cols.plate, cols.owner, parkingCol,
        tbl,
        storedCol,
        parkingCol, parkingCol
    )) or {}

    if #rows == 0 then
        log('Aucun véhicule sorti à mettre en fourrière.')
        return
    end

    local plates = {}
    for _, row in ipairs(rows) do
        plates[#plates + 1] = Core.NormalizePlate(row.plate)
    end

    if #plates == 0 then return end

    local placeholders = {}
    for i = 1, #plates do placeholders[i] = '?' end
    local inList = table.concat(placeholders, ',')

    local params = { impoundId }
    if Config.AutoImpound.setPoundColumn then
        params[#params + 1] = impoundId
    end
    for _, p in ipairs(plates) do params[#params + 1] = p end

    local sql
    if Config.AutoImpound.setPoundColumn then
        sql = ('UPDATE `%s` SET `%s` = 1, `%s` = ?, `%s` = ? WHERE REPLACE(`%s`, " ", "") IN (%s)'):format(
            tbl, storedCol, parkingCol, poundCol, cols.plate, inList
        )
    else
        sql = ('UPDATE `%s` SET `%s` = 1, `%s` = ? WHERE REPLACE(`%s`, " ", "") IN (%s)'):format(
            tbl, storedCol, parkingCol, cols.plate, inList
        )
    end

    MySQL.update.await(sql, params)
    log(('%d véhicule(s) envoyé(s) en fourrière (%s)'):format(#plates, impoundId))

    if Core.Log then
        Core.Log('vehicles', '🚧 Fourrière automatique (reboot)', ('**%d** véhicule(s) → `%s`'):format(#plates, impoundId), {
            color = 'warning',
            fields = {
                { name = 'Plaques', value = '`' .. table.concat(plates, '`, `') .. '`', inline = false },
            },
        })
    end

    CreateThread(function()
        Wait(15000)
        for _, row in ipairs(rows) do
            local xPlayer = ESX.GetPlayerFromIdentifier and ESX.GetPlayerFromIdentifier(row.owner)
            if xPlayer then
                TriggerClientEvent('esx_core:notify', xPlayer.source, Core.Locale('impound_reboot', row.plate), 'inform')
            end
        end
    end)
end

MySQL.ready(function()
    SetTimeout(3000, autoImpoundOnBoot)
end)

lib.callback.register('esx_core:saveVehicle', function(source, plate, props)
    if not Config.Persistence.enabled then return false end
    if type(props) ~= 'table' then return false end

    local xPlayer = Core.GetPlayer(source)
    if not xPlayer then return false end

    plate = Core.NormalizePlate(plate)
    if plate == '' then return false end

    local row = MySQL.single.await(
        ('SELECT `%s` AS owner, `%s` AS vehicle FROM `%s` WHERE REPLACE(`%s`, " ", "") = ? LIMIT 1'):format(
            cols.owner, cols.vehicle, cols.table, cols.plate
        ),
        { plate }
    )

    if not row or row.owner ~= xPlayer.identifier then
        return false
    end

    local merged = Core.DecodeJson(row.vehicle)
    for k, v in pairs(props) do
        merged[k] = v
    end
    merged.plate = merged.plate or plate

    MySQL.update.await(
        ('UPDATE `%s` SET `%s` = ? WHERE REPLACE(`%s`, " ", "") = ?'):format(
            cols.table, cols.vehicle, cols.plate
        ),
        { json.encode(merged), plate }
    )

    return true
end)

function Core.SetVehicleStored(plate, stored, parking)
    plate = Core.NormalizePlate(plate)
    local params = { stored and 1 or 0 }
    local sql = ('UPDATE `%s` SET `%s` = ?'):format(cols.table, cols.stored)

    if parking ~= nil then
        sql = sql .. (', `%s` = ?'):format(cols.parking)
        params[#params + 1] = parking
    end

    sql = sql .. (' WHERE REPLACE(`%s`, " ", "") = ?'):format(cols.plate)
    params[#params + 1] = plate

    return MySQL.update.await(sql, params)
end

RegisterNetEvent('esx_core:persistDamage', function(plate, props)
    local src = source
    if not Config.Persistence.enabled or type(props) ~= 'table' then return end

    local xPlayer = Core.GetPlayer(src)
    if not xPlayer then return end

    plate = Core.NormalizePlate(plate)
    local row = MySQL.single.await(
        ('SELECT `%s` AS owner, `%s` AS vehicle FROM `%s` WHERE REPLACE(`%s`, " ", "") = ? LIMIT 1'):format(
            cols.owner, cols.vehicle, cols.table, cols.plate
        ),
        { plate }
    )
    if not row or row.owner ~= xPlayer.identifier then return end

    local merged = Core.DecodeJson(row.vehicle)
    for k, v in pairs(props) do
        merged[k] = v
    end

    MySQL.update.await(
        ('UPDATE `%s` SET `%s` = ? WHERE REPLACE(`%s`, " ", "") = ?'):format(
            cols.table, cols.vehicle, cols.plate
        ),
        { json.encode(merged), plate }
    )
end)
