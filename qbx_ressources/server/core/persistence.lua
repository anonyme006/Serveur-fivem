if Config.Modules and Config.Modules.core == false then return end

--[[
    Persistance véhicules QBox (player_vehicles)
    state : 0 = sorti, 1 = garage, 2 = fourrière
]]

local cols = Config.Persistence.columns
local stateCfg = Config.Persistence.state or { out = 0, garaged = 1, impound = 2 }

local function log(msg)
    if Config.AutoImpound.log then
        print(('^3[qbx_ressources]^0 %s'):format(msg))
    end
end

local function autoImpoundOnBoot()
    if not Config.AutoImpound.enabled then return end

    local impoundId = Config.AutoImpound.impoundId or 'impound'
    local tbl = cols.table
    local storedCol = cols.stored
    local parkingCol = cols.parking
    local outState = stateCfg.out or 0
    local impoundState = stateCfg.impound or 2

    local rows = MySQL.query.await(([[
        SELECT `%s` AS plate, `%s` AS owner, `%s` AS parking
        FROM `%s`
        WHERE `%s` = ?
          AND (`%s` IS NULL OR `%s` NOT IN ('cover', 'used_parking'))
    ]]):format(
        cols.plate, cols.owner, parkingCol,
        tbl,
        storedCol,
        parkingCol, parkingCol
    ), { outState }) or {}

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

    local params = { impoundState, impoundId }
    for _, p in ipairs(plates) do params[#params + 1] = p end

    local sql = ('UPDATE `%s` SET `%s` = ?, `%s` = ? WHERE REPLACE(UPPER(`%s`), " ", "") IN (%s)'):format(
        tbl, storedCol, parkingCol, cols.plate, inList
    )
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
            local player = Core.GetPlayerFromCitizenId(row.owner)
            if player and player.PlayerData and player.PlayerData.source then
                TriggerClientEvent('qbx_ressources:notify', player.PlayerData.source, Core.Locale('impound_reboot', row.plate), 'inform')
            end
        end
    end)
end

MySQL.ready(function()
    SetTimeout(3000, autoImpoundOnBoot)
end)

lib.callback.register('qbx_ressources:saveVehicle', function(source, plate, props)
    if not Config.Persistence.enabled then return false end
    if type(props) ~= 'table' then return false end

    local citizenid = Core.GetIdentifier(source)
    if not citizenid then return false end

    plate = Core.NormalizePlate(plate)
    if plate == '' then return false end

    local row = MySQL.single.await(
        ('SELECT `%s` AS owner, `%s` AS vehicle FROM `%s` WHERE REPLACE(UPPER(`%s`), " ", "") = ? LIMIT 1'):format(
            cols.owner, cols.vehicle, cols.table, cols.plate
        ),
        { plate }
    )

    if not row or row.owner ~= citizenid then
        return false
    end

    local merged = Core.DecodeJson(row.vehicle)
    for k, v in pairs(props) do
        merged[k] = v
    end
    merged.plate = merged.plate or plate

    MySQL.update.await(
        ('UPDATE `%s` SET `%s` = ? WHERE REPLACE(UPPER(`%s`), " ", "") = ?'):format(
            cols.table, cols.vehicle, cols.plate
        ),
        { json.encode(merged), plate }
    )

    return true
end)

function Core.SetVehicleStored(plate, stored, parking)
    plate = Core.NormalizePlate(plate)
    local stateVal
    if stored == true or stored == 1 then
        if parking == (Config.AutoImpound.impoundId or 'impound') then
            stateVal = stateCfg.impound or 2
        else
            stateVal = stateCfg.garaged or 1
        end
    else
        stateVal = stateCfg.out or 0
    end

    local params = { stateVal }
    local sql = ('UPDATE `%s` SET `%s` = ?'):format(cols.table, cols.stored)

    if parking ~= nil then
        sql = sql .. (', `%s` = ?'):format(cols.parking)
        params[#params + 1] = parking
    end

    sql = sql .. (' WHERE REPLACE(UPPER(`%s`), " ", "") = ?'):format(cols.plate)
    params[#params + 1] = plate

    return MySQL.update.await(sql, params)
end

RegisterNetEvent('qbx_ressources:persistDamage', function(plate, props)
    local src = source
    if not Config.Persistence.enabled or type(props) ~= 'table' then return end

    local citizenid = Core.GetIdentifier(src)
    if not citizenid then return end

    plate = Core.NormalizePlate(plate)
    local row = MySQL.single.await(
        ('SELECT `%s` AS owner, `%s` AS vehicle FROM `%s` WHERE REPLACE(UPPER(`%s`), " ", "") = ? LIMIT 1'):format(
            cols.owner, cols.vehicle, cols.table, cols.plate
        ),
        { plate }
    )
    if not row or row.owner ~= citizenid then return end

    local merged = Core.DecodeJson(row.vehicle)
    for k, v in pairs(props) do
        merged[k] = v
    end

    MySQL.update.await(
        ('UPDATE `%s` SET `%s` = ? WHERE REPLACE(UPPER(`%s`), " ", "") = ?'):format(
            cols.table, cols.vehicle, cols.plate
        ),
        { json.encode(merged), plate }
    )
end)
