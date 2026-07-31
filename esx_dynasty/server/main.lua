--[[
    esx_dynasty — Server
    Job Dynasty 8 + CRUD logements + employés + actualités
]]

local Properties = {}
local InsideBucketBase = 7000

local function notify(src, msg, nType)
    TriggerClientEvent('esx_dynasty:notify', src, msg, nType or 'inform')
end

local function vecToTable(v)
    if not v then return nil end
    if type(v) == 'vector3' or type(v) == 'vector4' then
        return { x = v.x + 0.0, y = v.y + 0.0, z = v.z + 0.0 }
    end
    if type(v) == 'table' and v.x then
        return { x = v.x + 0.0, y = v.y + 0.0, z = v.z + 0.0, h = v.h }
    end
    return nil
end

local InteriorAliases = {
    apartment_low = 'apt_low',
    apartment_mid = 'apt_mid',
    apartment_high = 'apt_high_dellperro',
    apartment_modern7 = 'apt_modern_1',
    mansion = 'house_franklin',
    farmhouse = 'house_madrazo',
    office = 'office_arcadius',
    warehouse = 'warehouse_medium',
}

local function getInterior(id)
    id = InteriorAliases[id] or id
    for i = 1, #Config.Interiors do
        if Config.Interiors[i].id == id then
            return Config.Interiors[i]
        end
    end
    return Config.Interiors[1]
end

local function serializeInterior(it)
    if not it then return nil end
    local ipls = it.ipl
    if type(ipls) == 'string' then ipls = { ipls } end
    return {
        id = it.id,
        label = it.label,
        description = it.description or '',
        type = it.type,
        tier = it.tier or 'mid',
        image = it.image,
        entry = vecToTable(it.entry),
        heading = it.heading or 0.0,
        stash = vecToTable(it.stash),
        wardrobe = vecToTable(it.wardrobe),
        ipl = ipls,
        isMlo = it.entry == nil or it.type == 'mlo',
    }
end

local function parsePoint(p)
    if type(p) ~= 'table' then return nil end
    local x, y, z = tonumber(p.x), tonumber(p.y), tonumber(p.z)
    if not x or not y or not z then return nil end
    return { x = x + 0.0, y = y + 0.0, z = z + 0.0, h = (tonumber(p.h) or 0) + 0.0 }
end

local function isEmployee(xPlayer)
    return xPlayer and xPlayer.job and xPlayer.job.name == Config.JobName
end

local function hasPermission(xPlayer, perm)
    if not isEmployee(xPlayer) then return false end
    local minGrade = Config.Permissions[perm]
    if minGrade == nil then return false end
    return (xPlayer.job.grade or 0) >= minGrade
end

local function playerName(xPlayer)
    if xPlayer.getName then return xPlayer.getName() end
    return GetPlayerName(xPlayer.source) or 'Inconnu'
end

local function rowToProperty(row)
    if not row then return nil end
    return {
        id = row.id,
        label = row.label,
        address = row.address or '',
        description = row.description or '',
        interior = row.interior,
        property_type = row.property_type,
        status = row.status,
        price_sale = tonumber(row.price_sale) or 0,
        price_rent = tonumber(row.price_rent) or 0,
        entrance = {
            x = row.entrance_x + 0.0,
            y = row.entrance_y + 0.0,
            z = row.entrance_z + 0.0,
            h = (row.entrance_h or 0) + 0.0,
        },
        garage = (row.garage_x and {
            x = row.garage_x + 0.0,
            y = row.garage_y + 0.0,
            z = row.garage_z + 0.0,
            h = (row.garage_h or 0) + 0.0,
        }) or nil,
        owner = row.owner,
        owner_name = row.owner_name,
        renter = row.renter,
        renter_name = row.renter_name,
        locked = row.locked == 1 or row.locked == true,
        created_by = row.created_by,
        created_at = row.created_at,
    }
end

local function loadProperties()
    local rows = MySQL.query.await('SELECT * FROM dynasty_properties ORDER BY id DESC') or {}
    Properties = {}
    for i = 1, #rows do
        local p = rowToProperty(rows[i])
        Properties[p.id] = p
    end
    TriggerClientEvent('esx_dynasty:syncProperties', -1, Properties)
end

local function ensureTables()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `dynasty_properties` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `label` VARCHAR(128) NOT NULL,
            `address` VARCHAR(255) NOT NULL DEFAULT '',
            `description` TEXT NULL,
            `interior` VARCHAR(64) NOT NULL DEFAULT 'apt_mid',
            `property_type` VARCHAR(32) NOT NULL DEFAULT 'appartement',
            `status` VARCHAR(32) NOT NULL DEFAULT 'libre',
            `price_sale` INT NOT NULL DEFAULT 0,
            `price_rent` INT NOT NULL DEFAULT 0,
            `entrance_x` FLOAT NOT NULL,
            `entrance_y` FLOAT NOT NULL,
            `entrance_z` FLOAT NOT NULL,
            `entrance_h` FLOAT NOT NULL DEFAULT 0,
            `garage_x` FLOAT NULL,
            `garage_y` FLOAT NULL,
            `garage_z` FLOAT NULL,
            `garage_h` FLOAT NULL,
            `owner` VARCHAR(64) NULL,
            `owner_name` VARCHAR(128) NULL,
            `renter` VARCHAR(64) NULL,
            `renter_name` VARCHAR(128) NULL,
            `locked` TINYINT(1) NOT NULL DEFAULT 1,
            `created_by` VARCHAR(64) NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            INDEX `idx_owner` (`owner`),
            INDEX `idx_renter` (`renter`),
            INDEX `idx_status` (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `dynasty_keys` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `property_id` INT NOT NULL,
            `identifier` VARCHAR(64) NOT NULL,
            `player_name` VARCHAR(128) NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uk_prop_ident` (`property_id`, `identifier`),
            INDEX `idx_identifier` (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `dynasty_news` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `author` VARCHAR(128) NOT NULL,
            `author_identifier` VARCHAR(64) NULL,
            `type` VARCHAR(32) NOT NULL DEFAULT 'normal',
            `content` TEXT NOT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `dynasty_billboard` (
            `id` INT NOT NULL DEFAULT 1,
            `content` TEXT NOT NULL,
            `updated_by` VARCHAR(128) NULL,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    local billboard = MySQL.scalar.await('SELECT id FROM dynasty_billboard WHERE id = 1')
    if not billboard then
        MySQL.insert.await(
            'INSERT INTO dynasty_billboard (id, content, updated_by) VALUES (1, ?, ?)',
            { 'Bienvenue chez Dynasty 8 — publiez ici les annonces immobilières.', 'Système' }
        )
    end
end

CreateThread(function()
    Wait(800)
    ensureTables()
    loadProperties()
end)

local function getKeys(propertyId)
    return MySQL.query.await(
        'SELECT id, property_id, identifier, player_name FROM dynasty_keys WHERE property_id = ? ORDER BY id ASC',
        { propertyId }
    ) or {}
end

local function hasKey(propertyId, identifier)
    local prop = Properties[propertyId]
    if not prop then return false end
    if prop.owner == identifier or prop.renter == identifier then return true end
    local row = MySQL.scalar.await(
        'SELECT 1 FROM dynasty_keys WHERE property_id = ? AND identifier = ?',
        { propertyId, identifier }
    )
    return row ~= nil
end

local function addKey(propertyId, identifier, name)
    MySQL.insert.await(
        'INSERT IGNORE INTO dynasty_keys (property_id, identifier, player_name) VALUES (?, ?, ?)',
        { propertyId, identifier, name }
    )
end

local function removeKey(propertyId, identifier)
    MySQL.update.await(
        'DELETE FROM dynasty_keys WHERE property_id = ? AND identifier = ?',
        { propertyId, identifier }
    )
end

local function getNews()
    return MySQL.query.await(
        'SELECT id, author, type, content, created_at FROM dynasty_news ORDER BY created_at DESC LIMIT ?',
        { Config.MaxNews or 30 }
    ) or {}
end

local function getBillboard()
    return MySQL.single.await('SELECT content, updated_by, updated_at FROM dynasty_billboard WHERE id = 1')
        or { content = '', updated_by = '', updated_at = '' }
end

local function countOnlineAgents()
    local count = 0
    local xPlayers = ESX.GetExtendedPlayers and ESX.GetExtendedPlayers('job', Config.JobName) or nil
    if xPlayers then
        return #xPlayers
    end
    for _, playerId in ipairs(ESX.GetPlayers()) do
        local xP = ESX.GetPlayerFromId(playerId)
        if isEmployee(xP) then count = count + 1 end
    end
    return count
end

local function getEmployees()
    local list = {}
    local online = {}

    for _, playerId in ipairs(ESX.GetPlayers()) do
        local xP = ESX.GetPlayerFromId(playerId)
        if isEmployee(xP) then
            online[xP.identifier] = true
            list[#list + 1] = {
                identifier = xP.identifier,
                name = playerName(xP),
                grade = xP.job.grade,
                grade_label = xP.job.grade_label or tostring(xP.job.grade),
                online = true,
                source = xP.source,
            }
        end
    end

    local rows = MySQL.query.await([[
        SELECT identifier, firstname, lastname, job_grade
        FROM users
        WHERE job = ?
        ORDER BY job_grade DESC, lastname ASC
    ]], { Config.JobName }) or {}

    for i = 1, #rows do
        local row = rows[i]
        if not online[row.identifier] then
            local name = ((row.firstname or '') .. ' ' .. (row.lastname or '')):gsub('^%s+', ''):gsub('%s+$', '')
            if name == '' then name = row.identifier end
            list[#list + 1] = {
                identifier = row.identifier,
                name = name,
                grade = tonumber(row.job_grade) or 0,
                grade_label = tostring(row.job_grade or 0),
                online = false,
                source = nil,
            }
        end
    end

    return list
end

local function societyDeposit(amount)
    if amount <= 0 then return end
    local account = 'society_' .. Config.JobName
    local exists = MySQL.scalar.await(
        'SELECT 1 FROM addon_account_data WHERE account_name = ?',
        { account }
    )
    if exists then
        MySQL.update.await(
            'UPDATE addon_account_data SET money = money + ? WHERE account_name = ?',
            { amount, account }
        )
    end
end

local function enrichPropertiesWithKeys(props)
    local out = {}
    for id, p in pairs(props) do
        local copy = {}
        for k, v in pairs(p) do copy[k] = v end
        copy.keys = getKeys(id)
        out[#out + 1] = copy
    end
    table.sort(out, function(a, b) return a.id > b.id end)
    return out
end

local function buildPanelPayload(xPlayer)
    local props = enrichPropertiesWithKeys(Properties)
    local keysTotal = 0
    local active = 0
    for i = 1, #props do
        keysTotal = keysTotal + #(props[i].keys or {})
        if props[i].status == 'occupe' or props[i].status == 'location' or props[i].owner then
            active = active + 1
        end
    end

    local interiors = {}
    for i = 1, #Config.Interiors do
        interiors[#interiors + 1] = serializeInterior(Config.Interiors[i])
    end

    return {
        player = {
            name = playerName(xPlayer),
            identifier = xPlayer.identifier,
            grade = xPlayer.job.grade,
            grade_label = xPlayer.job.grade_label or '',
            job_label = xPlayer.job.label or 'Dynasty 8',
        },
        permissions = {
            createProperty = hasPermission(xPlayer, 'createProperty'),
            editProperty = hasPermission(xPlayer, 'editProperty'),
            deleteProperty = hasPermission(xPlayer, 'deleteProperty'),
            sellProperty = hasPermission(xPlayer, 'sellProperty'),
            rentProperty = hasPermission(xPlayer, 'rentProperty'),
            manageEmployees = hasPermission(xPlayer, 'manageEmployees'),
            manageVehicles = hasPermission(xPlayer, 'manageVehicles'),
            postNews = hasPermission(xPlayer, 'postNews'),
            manageBillboard = hasPermission(xPlayer, 'manageBillboard'),
        },
        news = getNews(),
        billboard = getBillboard(),
        employees = getEmployees(),
        vehicles = Config.Garage.vehicles,
        properties = props,
        interiors = interiors,
        stats = {
            total = #props,
            agents = #getEmployees(),
            online = countOnlineAgents(),
            active = active,
            keys = keysTotal,
        },
        currency = Config.Currency,
    }
end

-- ─── Sync on join ────────────────────────────────────────────

RegisterNetEvent('esx:playerLoaded', function(playerId, xPlayer)
    local src = source
    if type(playerId) == 'number' then src = playerId end
    TriggerClientEvent('esx_dynasty:syncProperties', src, Properties)
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    Wait(1000)
    TriggerClientEvent('esx_dynasty:syncProperties', -1, Properties)
end)

-- ─── Callbacks panel ─────────────────────────────────────────

ESX.RegisterServerCallback('esx_dynasty:getCompanyData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not hasPermission(xPlayer, 'openCompanyPanel') then
        cb(nil)
        return
    end
    cb(buildPanelPayload(xPlayer))
end)

ESX.RegisterServerCallback('esx_dynasty:getHousingData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not hasPermission(xPlayer, 'openHousingPanel') then
        cb(nil)
        return
    end
    cb(buildPanelPayload(xPlayer))
end)

ESX.RegisterServerCallback('esx_dynasty:createProperty', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not hasPermission(xPlayer, 'createProperty') then
        cb({ ok = false, error = Translate('no_permission') })
        return
    end
    if type(data) ~= 'table' or not data.label or data.label == '' or not data.entrance then
        cb({ ok = false, error = Translate('invalid_data') })
        return
    end

    local interior = data.interior or 'apt_mid'
    if not getInterior(interior) then
        cb({ ok = false, error = Translate('invalid_data') })
        return
    end

    local status = data.status or 'libre'
    local e = parsePoint(data.entrance)
    local g = parsePoint(data.garage)
    if not e then
        cb({ ok = false, error = Translate('invalid_data') })
        return
    end

    local id = MySQL.insert.await([[
        INSERT INTO dynasty_properties
            (label, address, description, interior, property_type, status,
             price_sale, price_rent, entrance_x, entrance_y, entrance_z, entrance_h,
             garage_x, garage_y, garage_z, garage_h, created_by)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        tostring(data.label):sub(1, 128),
        tostring(data.address or ''):sub(1, 255),
        tostring(data.description or ''),
        interior,
        tostring(data.property_type or 'appartement'):sub(1, 32),
        status,
        tonumber(data.price_sale) or 0,
        tonumber(data.price_rent) or 0,
        e.x, e.y, e.z, e.h,
        g and g.x or nil, g and g.y or nil, g and g.z or nil, g and g.h or nil,
        xPlayer.identifier,
    })

    local row = MySQL.single.await('SELECT * FROM dynasty_properties WHERE id = ?', { id })
    local prop = rowToProperty(row)
    Properties[id] = prop
    TriggerClientEvent('esx_dynasty:syncProperties', -1, Properties)

    if hasPermission(xPlayer, 'postNews') then
        MySQL.insert.await(
            'INSERT INTO dynasty_news (author, author_identifier, type, content) VALUES (?, ?, ?, ?)',
            { playerName(xPlayer), xPlayer.identifier, 'info', ('Nouveau bien créé : %s — %s'):format(prop.label, prop.address) }
        )
    end

    cb({ ok = true, property = prop, message = Translate('property_created') })
end)

ESX.RegisterServerCallback('esx_dynasty:updateProperty', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not hasPermission(xPlayer, 'editProperty') then
        cb({ ok = false, error = Translate('no_permission') })
        return
    end
    local id = tonumber(data and data.id)
    if not id or not Properties[id] then
        cb({ ok = false, error = Translate('invalid_data') })
        return
    end

    local e = parsePoint(data.entrance) or Properties[id].entrance
    local g = parsePoint(data.garage)
    if data.clear_garage then
        g = nil
    elseif not g then
        g = Properties[id].garage
    end

    local locked = Properties[id].locked and 1 or 0
    if data.locked ~= nil then
        locked = (data.locked == false or data.locked == 0) and 0 or 1
    end

    if data.interior and not getInterior(data.interior) then
        cb({ ok = false, error = Translate('invalid_data') })
        return
    end

    MySQL.update.await([[
        UPDATE dynasty_properties SET
            label = ?, address = ?, description = ?, interior = ?, property_type = ?, status = ?,
            price_sale = ?, price_rent = ?,
            entrance_x = ?, entrance_y = ?, entrance_z = ?, entrance_h = ?,
            garage_x = ?, garage_y = ?, garage_z = ?, garage_h = ?,
            locked = ?
        WHERE id = ?
    ]], {
        tostring(data.label or Properties[id].label):sub(1, 128),
        tostring(data.address or Properties[id].address):sub(1, 255),
        tostring(data.description or Properties[id].description or ''),
        data.interior or Properties[id].interior,
        data.property_type or Properties[id].property_type,
        data.status or Properties[id].status,
        tonumber(data.price_sale) or Properties[id].price_sale,
        tonumber(data.price_rent) or Properties[id].price_rent,
        e.x, e.y, e.z, e.h or 0.0,
        g and g.x or nil, g and g.y or nil, g and g.z or nil, g and (g.h or 0) or nil,
        locked,
        id,
    })

    local row = MySQL.single.await('SELECT * FROM dynasty_properties WHERE id = ?', { id })
    Properties[id] = rowToProperty(row)
    TriggerClientEvent('esx_dynasty:syncProperties', -1, Properties)
    cb({ ok = true, property = Properties[id], message = Translate('property_updated') })
end)

ESX.RegisterServerCallback('esx_dynasty:updatePoints', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not hasPermission(xPlayer, 'editProperty') then
        cb({ ok = false, error = Translate('no_permission') })
        return
    end

    local id = tonumber(data and data.id)
    if not id or not Properties[id] then
        cb({ ok = false, error = Translate('invalid_data') })
        return
    end

    local prop = Properties[id]
    local entrance = parsePoint(data.entrance) or prop.entrance
    local garage = prop.garage

    if data.clear_garage then
        garage = nil
    elseif data.garage ~= nil then
        garage = parsePoint(data.garage)
        if data.garage and not garage then
            cb({ ok = false, error = Translate('invalid_data') })
            return
        end
    end

    MySQL.update.await([[
        UPDATE dynasty_properties SET
            entrance_x = ?, entrance_y = ?, entrance_z = ?, entrance_h = ?,
            garage_x = ?, garage_y = ?, garage_z = ?, garage_h = ?
        WHERE id = ?
    ]], {
        entrance.x, entrance.y, entrance.z, entrance.h or 0.0,
        garage and garage.x or nil, garage and garage.y or nil,
        garage and garage.z or nil, garage and (garage.h or 0) or nil,
        id,
    })

    local row = MySQL.single.await('SELECT * FROM dynasty_properties WHERE id = ?', { id })
    Properties[id] = rowToProperty(row)
    TriggerClientEvent('esx_dynasty:syncProperties', -1, Properties)
    cb({ ok = true, property = Properties[id], message = Translate('points_updated') })
end)

ESX.RegisterServerCallback('esx_dynasty:deleteProperty', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not hasPermission(xPlayer, 'deleteProperty') then
        cb({ ok = false, error = Translate('no_permission') })
        return
    end
    local id = tonumber(data and data.id)
    if not id or not Properties[id] then
        cb({ ok = false, error = Translate('invalid_data') })
        return
    end

    MySQL.update.await('DELETE FROM dynasty_keys WHERE property_id = ?', { id })
    MySQL.update.await('DELETE FROM dynasty_properties WHERE id = ?', { id })
    Properties[id] = nil
    TriggerClientEvent('esx_dynasty:syncProperties', -1, Properties)
    cb({ ok = true, message = Translate('property_deleted') })
end)

local function getClosestPlayer(source, maxDist)
    maxDist = maxDist or 3.0
    local ped = GetPlayerPed(source)
    if ped == 0 then return nil end
    local coords = GetEntityCoords(ped)
    local closest, closestDist = nil, maxDist
    for _, playerId in ipairs(ESX.GetPlayers()) do
        if playerId ~= source then
            local targetPed = GetPlayerPed(playerId)
            if targetPed ~= 0 then
                local dist = #(coords - GetEntityCoords(targetPed))
                if dist < closestDist then
                    closestDist = dist
                    closest = playerId
                end
            end
        end
    end
    return closest
end

ESX.RegisterServerCallback('esx_dynasty:sellProperty', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not hasPermission(xPlayer, 'sellProperty') then
        cb({ ok = false, error = Translate('no_permission') })
        return
    end
    local id = tonumber(data and data.id)
    local prop = id and Properties[id]
    if not prop then
        cb({ ok = false, error = Translate('invalid_data') })
        return
    end
    if prop.owner then
        cb({ ok = false, error = Translate('already_owned') })
        return
    end

    local targetId = tonumber(data.target) or getClosestPlayer(source)
    local xTarget = targetId and ESX.GetPlayerFromId(targetId)
    if not xTarget then
        cb({ ok = false, error = Translate('no_nearby_player') })
        return
    end

    local price = tonumber(prop.price_sale) or 0
    if price <= 0 then
        cb({ ok = false, error = Translate('invalid_data') })
        return
    end

    local bank = xTarget.getAccount('bank')
    if not bank or bank.money < price then
        cb({ ok = false, error = Translate('cannot_afford') })
        return
    end

    xTarget.removeAccountMoney('bank', price, 'Achat logement Dynasty')
    local commission = math.floor(price * ((Config.Commission.salePercent or 10) / 100))
    societyDeposit(commission)
    xPlayer.addAccountMoney('bank', math.max(0, price - commission), 'Commission vente Dynasty')

    MySQL.update.await([[
        UPDATE dynasty_properties
        SET owner = ?, owner_name = ?, renter = NULL, renter_name = NULL, status = 'occupe'
        WHERE id = ?
    ]], { xTarget.identifier, playerName(xTarget), id })

    addKey(id, xTarget.identifier, playerName(xTarget))

    local row = MySQL.single.await('SELECT * FROM dynasty_properties WHERE id = ?', { id })
    Properties[id] = rowToProperty(row)
    TriggerClientEvent('esx_dynasty:syncProperties', -1, Properties)

    MySQL.insert.await(
        'INSERT INTO dynasty_news (author, author_identifier, type, content) VALUES (?, ?, ?, ?)',
        {
            playerName(xPlayer),
            xPlayer.identifier,
            'normal',
            ('Vente : %s → %s pour %s%s'):format(prop.label, playerName(xTarget), Config.Currency, price),
        }
    )

    notify(xTarget.source, ('Vous avez acheté %s pour %s%s'):format(prop.label, Config.Currency, price), 'success')
    cb({ ok = true, message = Translate('property_sold', Config.Currency .. price) })
end)

ESX.RegisterServerCallback('esx_dynasty:rentProperty', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not hasPermission(xPlayer, 'rentProperty') then
        cb({ ok = false, error = Translate('no_permission') })
        return
    end
    local id = tonumber(data and data.id)
    local prop = id and Properties[id]
    if not prop then
        cb({ ok = false, error = Translate('invalid_data') })
        return
    end
    if prop.owner or prop.renter then
        cb({ ok = false, error = Translate('already_owned') })
        return
    end

    local targetId = tonumber(data.target) or getClosestPlayer(source)
    local xTarget = targetId and ESX.GetPlayerFromId(targetId)
    if not xTarget then
        cb({ ok = false, error = Translate('no_nearby_player') })
        return
    end

    local price = tonumber(prop.price_rent) or 0
    if price <= 0 then
        cb({ ok = false, error = Translate('invalid_data') })
        return
    end

    local bank = xTarget.getAccount('bank')
    if not bank or bank.money < price then
        cb({ ok = false, error = Translate('cannot_afford') })
        return
    end

    xTarget.removeAccountMoney('bank', price, 'Loyer Dynasty')
    local commission = math.floor(price * ((Config.Commission.rentPercent or 15) / 100))
    societyDeposit(commission)
    xPlayer.addAccountMoney('bank', math.max(0, price - commission), 'Commission location Dynasty')

    MySQL.update.await([[
        UPDATE dynasty_properties
        SET renter = ?, renter_name = ?, status = 'location'
        WHERE id = ?
    ]], { xTarget.identifier, playerName(xTarget), id })

    addKey(id, xTarget.identifier, playerName(xTarget))

    local row = MySQL.single.await('SELECT * FROM dynasty_properties WHERE id = ?', { id })
    Properties[id] = rowToProperty(row)
    TriggerClientEvent('esx_dynasty:syncProperties', -1, Properties)

    MySQL.insert.await(
        'INSERT INTO dynasty_news (author, author_identifier, type, content) VALUES (?, ?, ?, ?)',
        {
            playerName(xPlayer),
            xPlayer.identifier,
            'normal',
            ('Location : %s → %s pour %s%s/sem'):format(prop.label, playerName(xTarget), Config.Currency, price),
        }
    )

    notify(xTarget.source, ('Vous louez %s pour %s%s / semaine'):format(prop.label, Config.Currency, price), 'success')
    cb({ ok = true, message = Translate('property_rented', Config.Currency .. price) })
end)

ESX.RegisterServerCallback('esx_dynasty:revokeProperty', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not hasPermission(xPlayer, 'sellProperty') then
        cb({ ok = false, error = Translate('no_permission') })
        return
    end
    local id = tonumber(data and data.id)
    if not id or not Properties[id] then
        cb({ ok = false, error = Translate('invalid_data') })
        return
    end

    MySQL.update.await([[
        UPDATE dynasty_properties
        SET owner = NULL, owner_name = NULL, renter = NULL, renter_name = NULL, status = 'libre'
        WHERE id = ?
    ]], { id })
    MySQL.update.await('DELETE FROM dynasty_keys WHERE property_id = ?', { id })

    local row = MySQL.single.await('SELECT * FROM dynasty_properties WHERE id = ?', { id })
    Properties[id] = rowToProperty(row)
    TriggerClientEvent('esx_dynasty:syncProperties', -1, Properties)
    cb({ ok = true, message = Translate('property_revoked') })
end)

ESX.RegisterServerCallback('esx_dynasty:giveKeys', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    local id = tonumber(data and data.id)
    local prop = id and Properties[id]
    if not prop then
        cb({ ok = false, error = Translate('invalid_data') })
        return
    end

    local canGive = hasPermission(xPlayer, 'sellProperty')
        or prop.owner == xPlayer.identifier
        or prop.renter == xPlayer.identifier
    if not canGive then
        cb({ ok = false, error = Translate('no_permission') })
        return
    end

    local targetId = tonumber(data.target) or getClosestPlayer(source)
    local xTarget = targetId and ESX.GetPlayerFromId(targetId)
    if not xTarget then
        cb({ ok = false, error = Translate('no_nearby_player') })
        return
    end

    addKey(id, xTarget.identifier, playerName(xTarget))
    notify(xTarget.source, Translate('keys_given') .. ' — ' .. prop.label, 'success')
    cb({ ok = true, message = Translate('keys_given'), keys = getKeys(id) })
end)

ESX.RegisterServerCallback('esx_dynasty:removeKeys', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    local id = tonumber(data and data.id)
    local identifier = data and data.identifier
    local prop = id and Properties[id]
    if not prop or not identifier then
        cb({ ok = false, error = Translate('invalid_data') })
        return
    end

    local can = hasPermission(xPlayer, 'sellProperty')
        or prop.owner == xPlayer.identifier
    if not can then
        cb({ ok = false, error = Translate('no_permission') })
        return
    end

    removeKey(id, identifier)
    cb({ ok = true, message = Translate('keys_removed'), keys = getKeys(id) })
end)

ESX.RegisterServerCallback('esx_dynasty:toggleLock', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    local id = tonumber(data and data.id)
    local prop = id and Properties[id]
    if not prop then
        cb({ ok = false, error = Translate('invalid_data') })
        return
    end
    if not hasKey(id, xPlayer.identifier) and not hasPermission(xPlayer, 'editProperty') then
        cb({ ok = false, error = Translate('no_permission') })
        return
    end

    local locked = not prop.locked
    MySQL.update.await('UPDATE dynasty_properties SET locked = ? WHERE id = ?', { locked and 1 or 0, id })
    Properties[id].locked = locked
    TriggerClientEvent('esx_dynasty:syncProperties', -1, Properties)
    cb({ ok = true, locked = locked })
end)

ESX.RegisterServerCallback('esx_dynasty:canEnter', function(source, cb, propertyId)
    local xPlayer = ESX.GetPlayerFromId(source)
    local id = tonumber(propertyId)
    local prop = id and Properties[id]
    if not prop then
        cb({ ok = false })
        return
    end

    local interior = serializeInterior(getInterior(prop.interior))
    if not interior or not interior.entry then
        cb({ ok = false, mlo = true })
        return
    end

    local payload = {
        ok = true,
        interior = interior,
        bucket = InsideBucketBase + id,
    }

    if not prop.locked then
        cb(payload)
        return
    end

    if hasKey(id, xPlayer.identifier) or hasPermission(xPlayer, 'editProperty') then
        cb(payload)
        return
    end

    cb({ ok = false, error = Translate('enter_denied') })
end)

RegisterNetEvent('esx_dynasty:setBucket', function(bucket)
    local src = source
    local b = tonumber(bucket) or 0
    if b < 0 then b = 0 end
    if b > 0 and (b < InsideBucketBase or b > InsideBucketBase + 100000) then
        return
    end
    SetPlayerRoutingBucket(src, b)
end)

-- ─── News / Billboard ────────────────────────────────────────

ESX.RegisterServerCallback('esx_dynasty:postNews', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not hasPermission(xPlayer, 'postNews') then
        cb({ ok = false, error = Translate('no_permission') })
        return
    end
    local content = data and tostring(data.content or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if content == '' then
        cb({ ok = false, error = Translate('invalid_data') })
        return
    end
    local nType = data.type or 'normal'
    if nType ~= 'normal' and nType ~= 'urgent' and nType ~= 'info' then
        nType = 'normal'
    end

    MySQL.insert.await(
        'INSERT INTO dynasty_news (author, author_identifier, type, content) VALUES (?, ?, ?, ?)',
        { playerName(xPlayer), xPlayer.identifier, nType, content:sub(1, 1000) }
    )
    cb({ ok = true, message = Translate('news_posted'), news = getNews() })
end)

ESX.RegisterServerCallback('esx_dynasty:saveBillboard', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not hasPermission(xPlayer, 'manageBillboard') then
        cb({ ok = false, error = Translate('no_permission') })
        return
    end
    local content = tostring(data and data.content or ''):sub(1, 2000)
    MySQL.update.await(
        'UPDATE dynasty_billboard SET content = ?, updated_by = ? WHERE id = 1',
        { content, playerName(xPlayer) }
    )
    cb({ ok = true, message = Translate('billboard_saved'), billboard = getBillboard() })
end)

-- ─── Employees ───────────────────────────────────────────────

ESX.RegisterServerCallback('esx_dynasty:hireNearby', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not hasPermission(xPlayer, 'manageEmployees') then
        cb({ ok = false, error = Translate('no_permission') })
        return
    end
    local targetId = getClosestPlayer(source, 3.0)
    local xTarget = targetId and ESX.GetPlayerFromId(targetId)
    if not xTarget then
        cb({ ok = false, error = Translate('no_nearby_player') })
        return
    end
    xTarget.setJob(Config.JobName, 0)
    cb({ ok = true, message = Translate('employee_hired'), employees = getEmployees() })
end)

ESX.RegisterServerCallback('esx_dynasty:setEmployeeGrade', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not hasPermission(xPlayer, 'manageEmployees') then
        cb({ ok = false, error = Translate('no_permission') })
        return
    end
    local identifier = data and data.identifier
    local grade = tonumber(data and data.grade)
    if not identifier or grade == nil or grade < 0 or grade > 3 then
        cb({ ok = false, error = Translate('invalid_data') })
        return
    end
    if identifier == xPlayer.identifier then
        cb({ ok = false, error = Translate('no_permission') })
        return
    end

    local target = ESX.GetPlayerFromIdentifier and ESX.GetPlayerFromIdentifier(identifier)
    if target then
        target.setJob(Config.JobName, grade)
    else
        MySQL.update.await('UPDATE users SET job = ?, job_grade = ? WHERE identifier = ?', {
            Config.JobName, grade, identifier
        })
    end
    cb({ ok = true, message = Translate('grade_updated'), employees = getEmployees() })
end)

ESX.RegisterServerCallback('esx_dynasty:fireEmployee', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not hasPermission(xPlayer, 'manageEmployees') then
        cb({ ok = false, error = Translate('no_permission') })
        return
    end
    local identifier = data and data.identifier
    if not identifier or identifier == xPlayer.identifier then
        cb({ ok = false, error = Translate('invalid_data') })
        return
    end

    local target = ESX.GetPlayerFromIdentifier and ESX.GetPlayerFromIdentifier(identifier)
    if target then
        target.setJob('unemployed', 0)
    else
        MySQL.update.await('UPDATE users SET job = ?, job_grade = ? WHERE identifier = ?', {
            'unemployed', 0, identifier
        })
    end
    cb({ ok = true, message = Translate('employee_fired'), employees = getEmployees() })
end)

-- ─── Vehicles ────────────────────────────────────────────────

ESX.RegisterServerCallback('esx_dynasty:canSpawnVehicle', function(source, cb, model)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not hasPermission(xPlayer, 'manageVehicles') and not isEmployee(xPlayer) then
        cb({ ok = false, error = Translate('no_permission') })
        return
    end
    local grade = xPlayer.job.grade or 0
    for i = 1, #Config.Garage.vehicles do
        local v = Config.Garage.vehicles[i]
        if v.model == model then
            if grade >= (v.minGrade or 0) then
                cb({ ok = true })
            else
                cb({ ok = false, error = Translate('vehicle_locked') })
            end
            return
        end
    end
    cb({ ok = false, error = Translate('invalid_data') })
end)

-- Refresh helper for NUI
ESX.RegisterServerCallback('esx_dynasty:refresh', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not isEmployee(xPlayer) then
        cb(nil)
        return
    end
    cb(buildPanelPayload(xPlayer))
end)

exports('GetProperties', function()
    return Properties
end)

exports('GetProperty', function(id)
    return Properties[tonumber(id)]
end)
