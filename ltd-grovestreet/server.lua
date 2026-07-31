--[[
    LTD Grove Street — Server
    Toute la logique métier, sécurité et persistance côté serveur.
]]

-- =============================================================================
-- FRAMEWORK BRIDGE
-- =============================================================================
local Framework = {}
local ESX, QBCore

CreateThread(function()
    if Config.Framework == 'auto' then
        if GetResourceState('es_extended') == 'started' then
            Config.Framework = 'esx'
        elseif GetResourceState('qb-core') == 'started' then
            Config.Framework = 'qbcore'
        end
    end

    if Config.Framework == 'esx' then
        ESX = exports['es_extended']:getSharedObject()
        Framework.type = 'esx'
    elseif Config.Framework == 'qbcore' then
        QBCore = exports['qb-core']:GetCoreObject()
        Framework.type = 'qbcore'
    else
        print('^1[LTD-Grove]^7 Framework non détecté ! Configurez Config.Framework.')
    end
end)

---@param source number
---@return table|nil
local function GetPlayer(source)
    if Framework.type == 'esx' then
        return ESX.GetPlayerFromId(source)
    elseif Framework.type == 'qbcore' then
        return QBCore.Functions.GetPlayer(source)
    end
end

---@param player table
---@return string|nil
local function GetIdentifier(player)
    if Framework.type == 'esx' then
        return player.identifier
    elseif Framework.type == 'qbcore' then
        return player.PlayerData.citizenid
    end
end

---@param player table
---@return string|nil jobName
---@return number grade
local function GetJob(player)
    if Framework.type == 'esx' then
        local job = player.getJob()
        return job.name, job.grade
    elseif Framework.type == 'qbcore' then
        local job = player.PlayerData.job
        return job.name, job.grade.level
    end
end

---@param player table
---@param amount number
---@return boolean
local function RemoveMoney(player, amount, account)
    account = account or 'cash'
    if Framework.type == 'esx' then
        if account == 'bank' then
            if player.getAccount('bank').money >= amount then
                player.removeAccountMoney('bank', amount)
                return true
            end
        else
            if player.getMoney() >= amount then
                player.removeMoney(amount)
                return true
            end
        end
    elseif Framework.type == 'qbcore' then
        if account == 'bank' then
            return player.Functions.RemoveMoney('bank', amount)
        else
            return player.Functions.RemoveMoney('cash', amount)
        end
    end
    return false
end

---@param player table
---@param amount number
---@param account string
local function AddMoney(player, amount, account)
    account = account or 'cash'
    if Framework.type == 'esx' then
        if account == 'bank' then
            player.addAccountMoney('bank', amount)
        else
            player.addMoney(amount)
        end
    elseif Framework.type == 'qbcore' then
        player.Functions.AddMoney(account == 'bank' and 'bank' or 'cash', amount)
    end
end

---@param player table
---@param amount number
---@param account string
---@return boolean
local function HasMoney(player, amount, account)
    account = account or 'cash'
    if Framework.type == 'esx' then
        if account == 'bank' then
            return player.getAccount('bank').money >= amount
        end
        return player.getMoney() >= amount
    elseif Framework.type == 'qbcore' then
        return player.Functions.GetMoney(account == 'bank' and 'bank' or 'cash') >= amount
    end
    return false
end

-- =============================================================================
-- ÉTAT SERVEUR
-- =============================================================================
local StoreStock = {}       -- Réserve arrière { [item] = count }
local ShelfStock = {}       -- Rayons { [shelfId_item] = count }
local SalesHistory = {}     -- Historique ventes (persisté MySQL)
local ActiveDelivery = nil  -- { orderId, items, orderedBy, vehicleNetId }
local DeliveryCooldown = 0
local Statistics = { totalSales = 0, totalRevenue = 0, itemsSold = {} }

-- =============================================================================
-- UTILITAIRES
-- =============================================================================
local function Notify(source, msg, nType)
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'LTD Grove Street',
        description = msg,
        type = nType or 'inform',
    })
end

---@param source number
---@param coords vector3
---@param maxDist number
---@return boolean
local function IsNearCoords(source, coords, maxDist)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false end
    local playerCoords = GetEntityCoords(ped)
    return #(playerCoords - coords) <= maxDist
end

---@param source number
---@return boolean isEmployee
---@return number grade
local function IsEmployee(source)
    local player = GetPlayer(source)
    if not player then return false, 0 end
    local jobName, grade = GetJob(player)
    if jobName ~= Config.JobName then return false, grade end
    return true, grade
end

---@param grade number
---@param permission string
---@return boolean
local function HasPermission(grade, permission)
    local gradeData = Config.Grades[grade]
    if not gradeData then return false end
    return gradeData[permission] == true
end

local function GetShelfKey(shelfId, item)
    return shelfId .. '_' .. item
end

local function InitStock()
    for item, count in pairs(Config.InitialStock) do
        StoreStock[item] = count
    end
end

local function GetShelfItemConfig(shelfId, item)
    local shelf = Config.Shelves[shelfId]
    if not shelf then return nil end
    for _, entry in ipairs(shelf.items) do
        if entry.item == item then return entry end
    end
end

-- =============================================================================
-- SOCIÉTÉ (compte entreprise)
-- =============================================================================
local function GetSocietyBalance()
    if Framework.type == 'esx' then
        local account = exports['esx_addonaccount']:getSharedAccount(Config.SocietyName)
        if account then return account.money end
    elseif Framework.type == 'qbcore' then
        -- Adapter selon votre script de société (qb-management, etc.)
        local result = MySQL.scalar.await('SELECT amount FROM management_funds WHERE job_name = ?', { Config.JobName })
        return result or 0
    end
    return 0
end

local function AddSocietyMoney(amount)
    if Framework.type == 'esx' then
        local account = exports['esx_addonaccount']:getSharedAccount(Config.SocietyName)
        if account then account.addMoney(amount) end
    elseif Framework.type == 'qbcore' then
        MySQL.update('UPDATE management_funds SET amount = amount + ? WHERE job_name = ?', { amount, Config.JobName })
    end
    Statistics.totalRevenue = Statistics.totalRevenue + amount
end

local function RemoveSocietyMoney(amount)
    if Framework.type == 'esx' then
        local account = exports['esx_addonaccount']:getSharedAccount(Config.SocietyName)
        if account and account.money >= amount then
            account.removeMoney(amount)
            return true
        end
    elseif Framework.type == 'qbcore' then
        local balance = GetSocietyBalance()
        if balance >= amount then
            MySQL.update('UPDATE management_funds SET amount = amount - ? WHERE job_name = ?', { amount, Config.JobName })
            return true
        end
    end
    return false
end

-- =============================================================================
-- BASE DE DONNÉES
-- =============================================================================
local function InitDatabase()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS ltd_grove_sales (
            id INT AUTO_INCREMENT PRIMARY KEY,
            seller_identifier VARCHAR(60) NOT NULL,
            buyer_identifier VARCHAR(60) DEFAULT NULL,
            item VARCHAR(50) DEFAULT NULL,
            quantity INT DEFAULT 1,
            amount INT NOT NULL,
            payment_type VARCHAR(20) DEFAULT 'cash',
            sale_type ENUM('shelf', 'register') DEFAULT 'shelf',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS ltd_grove_stock (
            item VARCHAR(50) PRIMARY KEY,
            reserve_count INT DEFAULT 0,
            shelf_data LONGTEXT DEFAULT '{}'
        )
    ]])
end

local function LoadStockFromDB()
    local rows = MySQL.query.await('SELECT * FROM ltd_grove_stock')
    if rows and #rows > 0 then
        for _, row in ipairs(rows) do
            StoreStock[row.item] = row.reserve_count
            if row.shelf_data and row.shelf_data ~= '' then
                local shelfData = json.decode(row.shelf_data) or {}
                for key, count in pairs(shelfData) do
                    ShelfStock[key] = count
                end
            end
        end
    else
        InitStock()
        SaveStockToDB()
    end
end

function SaveStockToDB()
    local itemShelfMap = {}
    for key, count in pairs(ShelfStock) do
        local item = key:match('^.-_(.+)$')
        if item then
            itemShelfMap[item] = itemShelfMap[item] or {}
            itemShelfMap[item][key] = count
        end
    end

    for item, count in pairs(StoreStock) do
        MySQL.insert(
            'INSERT INTO ltd_grove_stock (item, reserve_count, shelf_data) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE reserve_count = ?, shelf_data = ?',
            { item, count, json.encode(itemShelfMap[item] or {}), count, json.encode(itemShelfMap[item] or {}) }
        )
    end
end

local function LogSale(sellerId, buyerId, item, quantity, amount, paymentType, saleType)
    MySQL.insert('INSERT INTO ltd_grove_sales (seller_identifier, buyer_identifier, item, quantity, amount, payment_type, sale_type) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        sellerId, buyerId, item, quantity, amount, paymentType, saleType
    })

    Statistics.totalSales = Statistics.totalSales + 1
    if item then
        Statistics.itemsSold[item] = (Statistics.itemsSold[item] or 0) + quantity
    end

    table.insert(SalesHistory, 1, {
        seller = sellerId,
        buyer = buyerId,
        item = item,
        quantity = quantity,
        amount = amount,
        paymentType = paymentType,
        saleType = saleType,
        time = os.time(),
    })

    if #SalesHistory > 100 then
        table.remove(SalesHistory)
    end
end

-- =============================================================================
-- COFFRE OX_INVENTORY
-- =============================================================================
local function RegisterStash()
    local stash = Config.Locations.stash
    exports.ox_inventory:RegisterStash(stash.stashId, 'Coffre LTD Grove', stash.slots, stash.weight, {
        [Config.JobName] = 0,
    })
end

-- =============================================================================
-- CALLBACKS OX_LIB
-- =============================================================================

-- Vérifier si le joueur est employé
lib.callback.register('ltd:server:isEmployee', function(source)
    local isEmp, grade = IsEmployee(source)
    return { isEmployee = isEmp, grade = grade }
end)

-- Obtenir le stock réserve
lib.callback.register('ltd:server:getStoreStock', function(source)
    local isEmp = IsEmployee(source)
    if not isEmp then return nil end
    if not IsNearCoords(source, Config.Locations.stockroom.coords, Config.InteractDistance) then
        return nil
    end
    return StoreStock
end)

-- Obtenir le stock d'un rayon
lib.callback.register('ltd:server:getShelfStock', function(source, shelfId)
    local shelf = Config.Shelves[shelfId]
    if not shelf then return nil end
    if not IsNearCoords(source, shelf.coords, Config.InteractDistance) then
        return nil
    end

    local stock = {}
    for _, entry in ipairs(shelf.items) do
        local key = GetShelfKey(shelfId, entry.item)
        stock[entry.item] = ShelfStock[key] or 0
    end
    return stock
end)

-- Remplir un rayon depuis la réserve
lib.callback.register('ltd:server:fillShelf', function(source, shelfId, item, quantity)
    local isEmp, grade = IsEmployee(source)
    if not isEmp or not HasPermission(grade, 'canStock') then
        Notify(source, Config.Notifications.noJob, 'error')
        return false
    end

    local shelf = Config.Shelves[shelfId]
    if not shelf then return false end
    if not IsNearCoords(source, shelf.coords, Config.InteractDistance) then
        Notify(source, Config.Notifications.tooFar, 'error')
        return false
    end

    quantity = math.floor(tonumber(quantity) or 0)
    if quantity <= 0 or quantity > 50 then return false end

    local itemConfig = GetShelfItemConfig(shelfId, item)
    if not itemConfig then return false end

    local reserve = StoreStock[item] or 0
    if reserve < quantity then
        Notify(source, Config.Notifications.noStock, 'error')
        return false
    end

    StoreStock[item] = reserve - quantity
    local key = GetShelfKey(shelfId, item)
    ShelfStock[key] = (ShelfStock[key] or 0) + quantity

    SaveStockToDB()
    Notify(source, string.format(Config.Notifications.stockFilled, itemConfig.label, quantity), 'success')
    return true
end)

-- Achat client depuis un rayon
lib.callback.register('ltd:server:buyFromShelf', function(source, shelfId, item, quantity, paymentType)
    local shelf = Config.Shelves[shelfId]
    if not shelf then return false end
    if not IsNearCoords(source, shelf.coords, Config.InteractDistance) then
        Notify(source, Config.Notifications.tooFar, 'error')
        return false
    end

    quantity = math.floor(tonumber(quantity) or 0)
    if quantity <= 0 or quantity > 20 then return false end

    paymentType = paymentType == 'bank' and 'bank' or 'cash'

    local itemConfig = GetShelfItemConfig(shelfId, item)
    if not itemConfig then return false end

    local key = GetShelfKey(shelfId, item)
    local available = ShelfStock[key] or 0
    if available < quantity then
        Notify(source, Config.Notifications.noShelfStock, 'error')
        return false
    end

    local totalPrice = itemConfig.price * quantity
    local player = GetPlayer(source)
    if not player then return false end

    if not HasMoney(player, totalPrice, paymentType) then
        Notify(source, Config.Notifications.notEnoughMoney, 'error')
        return false
    end

    if not exports.ox_inventory:CanCarryItem(source, item, quantity) then
        Notify(source, 'Inventaire plein.', 'error')
        return false
    end

    RemoveMoney(player, totalPrice, paymentType)
    exports.ox_inventory:AddItem(source, item, quantity)

    ShelfStock[key] = available - quantity
    AddSocietyMoney(totalPrice)

    local identifier = GetIdentifier(player)
    LogSale('self-service', identifier, item, quantity, totalPrice, paymentType, 'shelf')
    SaveStockToDB()

    Notify(source, string.format(Config.Notifications.purchaseSuccess, itemConfig.label, quantity, totalPrice), 'success')
    return true
end)

-- Encaisser un client à la caisse
lib.callback.register('ltd:server:chargeCustomer', function(source, targetId, amount, paymentType)
    local isEmp, grade = IsEmployee(source)
    if not isEmp or not HasPermission(grade, 'canRegister') then
        Notify(source, Config.Notifications.noJob, 'error')
        return false
    end

    if not IsNearCoords(source, Config.Locations.register.coords, Config.InteractDistance) then
        Notify(source, Config.Notifications.tooFar, 'error')
        return false
    end

    targetId = tonumber(targetId)
    amount = math.floor(tonumber(amount) or 0)
    if not targetId or amount <= 0 or amount > 100000 then return false end

    paymentType = paymentType == 'bank' and 'bank' or 'cash'

    local targetPlayer = GetPlayer(targetId)
    if not targetPlayer then return false end

    -- Vérifier distance entre employé et client
    local empPed = GetPlayerPed(source)
    local targetPed = GetPlayerPed(targetId)
    if #(GetEntityCoords(empPed) - GetEntityCoords(targetPed)) > 5.0 then
        Notify(source, 'Le client est trop loin.', 'error')
        return false
    end

    if not HasMoney(targetPlayer, amount, paymentType) then
        Notify(source, Config.Notifications.chargeFailed, 'error')
        Notify(targetId, Config.Notifications.notEnoughMoney, 'error')
        return false
    end

    RemoveMoney(targetPlayer, amount, paymentType)
    AddSocietyMoney(amount)

    local sellerPlayer = GetPlayer(source)
    local sellerId = GetIdentifier(sellerPlayer)
    local buyerId = GetIdentifier(targetPlayer)

    LogSale(sellerId, buyerId, nil, 1, amount, paymentType, 'register')

    -- Ticket de caisse
    local receiptMetadata = {
        description = string.format('LTD Grove — $%d — %s', amount, os.date('%d/%m/%Y %H:%M')),
        amount = amount,
        date = os.date('%d/%m/%Y %H:%M'),
        seller = sellerId,
    }
    exports.ox_inventory:AddItem(targetId, Config.ReceiptItem, 1, receiptMetadata)

    Notify(source, string.format(Config.Notifications.chargeSuccess, amount), 'success')
    Notify(targetId, string.format('Vous avez payé $%d à LTD Grove Street.', amount), 'inform')
    return true
end)

-- Historique des ventes
lib.callback.register('ltd:server:getSalesHistory', function(source)
    local isEmp, grade = IsEmployee(source)
    if not isEmp then return nil end

    local rows = MySQL.query.await(
        'SELECT * FROM ltd_grove_sales ORDER BY created_at DESC LIMIT 50'
    )
    return rows or {}
end)

-- Compte société
lib.callback.register('ltd:server:getSocietyBalance', function(source)
    local isEmp, grade = IsEmployee(source)
    if not isEmp or grade < Config.BossMinGrade then return nil end
    if not IsNearCoords(source, Config.Locations.boss.coords, Config.InteractDistance) then
        return nil
    end
    return GetSocietyBalance()
end)

-- Dépôt société
lib.callback.register('ltd:server:depositSociety', function(source, amount)
    local isEmp, grade = IsEmployee(source)
    if not isEmp or grade < Config.BossMinGrade then return false end
    if not IsNearCoords(source, Config.Locations.boss.coords, Config.InteractDistance) then
        return false
    end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local player = GetPlayer(source)
    if not player or not HasMoney(player, amount, 'cash') then
        Notify(source, Config.Notifications.notEnoughMoney, 'error')
        return false
    end

    RemoveMoney(player, amount, 'cash')
    AddSocietyMoney(amount)
    Notify(source, string.format(Config.Notifications.societyDeposit, amount), 'success')
    return true
end)

-- Retrait société
lib.callback.register('ltd:server:withdrawSociety', function(source, amount)
    local isEmp, grade = IsEmployee(source)
    if not isEmp or grade < Config.BossMinGrade then return false end
    if not IsNearCoords(source, Config.Locations.boss.coords, Config.InteractDistance) then
        return false
    end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    if not RemoveSocietyMoney(amount) then
        Notify(source, Config.Notifications.notEnoughMoney, 'error')
        return false
    end

    local player = GetPlayer(source)
    AddMoney(player, amount, 'cash')
    Notify(source, string.format(Config.Notifications.societyWithdraw, amount), 'success')
    return true
end)

-- Statistiques
lib.callback.register('ltd:server:getStatistics', function(source)
    local isEmp, grade = IsEmployee(source)
    if not isEmp or grade < Config.BossMinGrade then return nil end

    local totalRevenue = MySQL.scalar.await('SELECT COALESCE(SUM(amount), 0) FROM ltd_grove_sales') or 0
    local totalSales = MySQL.scalar.await('SELECT COUNT(*) FROM ltd_grove_sales') or 0
    local topItems = MySQL.query.await([[
        SELECT item, SUM(quantity) as total_qty, SUM(amount) as total_amount
        FROM ltd_grove_sales WHERE item IS NOT NULL
        GROUP BY item ORDER BY total_qty DESC LIMIT 5
    ]])

    return {
        totalRevenue = totalRevenue,
        totalSales = totalSales,
        topItems = topItems or {},
        societyBalance = GetSocietyBalance(),
    }
end)

-- Employés (ESX)
lib.callback.register('ltd:server:getEmployees', function(source)
    local isEmp, grade = IsEmployee(source)
    if not isEmp or grade < Config.BossMinGrade then return nil end

    if Framework.type == 'esx' then
        local rows = MySQL.query.await(
            'SELECT identifier, firstname, lastname, job_grade FROM users WHERE job = ? ORDER BY job_grade DESC',
            { Config.JobName }
        )
        return rows or {}
    elseif Framework.type == 'qbcore' then
        local rows = MySQL.query.await(
            'SELECT citizenid as identifier, charinfo, job FROM players WHERE JSON_EXTRACT(job, "$.name") = ?',
            { Config.JobName }
        )
        local employees = {}
        for _, row in ipairs(rows or {}) do
            local charinfo = json.decode(row.charinfo) or {}
            local job = json.decode(row.job) or {}
            table.insert(employees, {
                identifier = row.identifier,
                firstname = charinfo.firstname or 'Inconnu',
                lastname = charinfo.lastname or '',
                job_grade = job.grade and job.grade.level or 0,
            })
        end
        return employees
    end
    return {}
end)

-- Changer le grade d'un employé
lib.callback.register('ltd:server:setEmployeeGrade', function(source, targetIdentifier, newGrade)
    local isEmp, grade = IsEmployee(source)
    if not isEmp or grade < Config.BossMinGrade then return false end

    newGrade = math.floor(tonumber(newGrade) or -1)
    if not Config.Grades[newGrade] then return false end

    if Framework.type == 'esx' then
        MySQL.update('UPDATE users SET job_grade = ? WHERE identifier = ? AND job = ?', {
            newGrade, targetIdentifier, Config.JobName
        })
    elseif Framework.type == 'qbcore' then
        local row = MySQL.single.await('SELECT job FROM players WHERE citizenid = ?', { targetIdentifier })
        if row then
            local job = json.decode(row.job) or {}
            job.grade = { level = newGrade, name = Config.Grades[newGrade].label }
            MySQL.update('UPDATE players SET job = ? WHERE citizenid = ?', { json.encode(job), targetIdentifier })
        end
    end

    Notify(source, Config.Notifications.gradeUpdated, 'success')
    return true
end)

-- Licencier un employé
lib.callback.register('ltd:server:fireEmployee', function(source, targetIdentifier)
    local isEmp, grade = IsEmployee(source)
    if not isEmp or grade < Config.BossMinGrade then return false end

    if Framework.type == 'esx' then
        MySQL.update('UPDATE users SET job = ?, job_grade = ? WHERE identifier = ? AND job = ?', {
            'unemployed', 0, targetIdentifier, Config.JobName
        })
    elseif Framework.type == 'qbcore' then
        local row = MySQL.single.await('SELECT job FROM players WHERE citizenid = ?', { targetIdentifier })
        if row then
            local job = json.decode(row.job) or {}
            job.name = 'unemployed'
            job.grade = { level = 0, name = 'Chômeur' }
            MySQL.update('UPDATE players SET job = ? WHERE citizenid = ?', { json.encode(job), targetIdentifier })
        end
    end

    Notify(source, Config.Notifications.employeeFired, 'success')
    return true
end)

-- Recruter un joueur proche
lib.callback.register('ltd:server:hireEmployee', function(source, targetId)
    local isEmp, grade = IsEmployee(source)
    if not isEmp or grade < Config.BossMinGrade then return false end

    targetId = tonumber(targetId)
    if not targetId then return false end

    local targetPlayer = GetPlayer(targetId)
    if not targetPlayer then return false end

    if Framework.type == 'esx' then
        targetPlayer.setJob(Config.JobName, 0)
    elseif Framework.type == 'qbcore' then
        targetPlayer.Functions.SetJob(Config.JobName, 0)
    end

    Notify(source, Config.Notifications.employeeHired, 'success')
    Notify(targetId, 'Vous avez été recruté chez LTD Grove Street !', 'success')
    return true
end)

-- =============================================================================
-- LIVRAISONS
-- =============================================================================
lib.callback.register('ltd:server:orderDelivery', function(source, catalogIndex)
    local isEmp, grade = IsEmployee(source)
    if not isEmp or not HasPermission(grade, 'canDelivery') then
        Notify(source, Config.Notifications.noJob, 'error')
        return false
    end

    if not IsNearCoords(source, Config.Locations.deliveryOrder.coords, Config.InteractDistance) then
        Notify(source, Config.Notifications.tooFar, 'error')
        return false
    end

    if ActiveDelivery then
        Notify(source, Config.Notifications.deliveryActive, 'error')
        return false
    end

    if os.time() < DeliveryCooldown then
        Notify(source, Config.Notifications.deliveryCooldown, 'error')
        return false
    end

    catalogIndex = tonumber(catalogIndex)
    local catalogItem = Config.Delivery.catalog[catalogIndex]
    if not catalogItem then return false end

    if not RemoveSocietyMoney(catalogItem.cost) then
        Notify(source, Config.Notifications.notEnoughMoney, 'error')
        return false
    end

    local player = GetPlayer(source)
    ActiveDelivery = {
        items = { { item = catalogItem.item, amount = catalogItem.amount } },
        orderedBy = source,
        orderId = os.time(),
        validated = false,
    }

    DeliveryCooldown = os.time() + Config.Delivery.cooldown

    TriggerClientEvent('ltd:client:startDeliveryMission', source, ActiveDelivery)
    Notify(source, Config.Notifications.deliveryOrdered, 'success')
    return true
end)

lib.callback.register('ltd:server:validateDelivery', function(source)
    local isEmp, grade = IsEmployee(source)
    if not isEmp or not HasPermission(grade, 'canDelivery') then
        Notify(source, Config.Notifications.noJob, 'error')
        return false
    end

    if not IsNearCoords(source, Config.Locations.deliveryValidate.coords, Config.DeliveryValidateDistance) then
        Notify(source, Config.Notifications.tooFar, 'error')
        return false
    end

    if not ActiveDelivery or ActiveDelivery.validated then
        Notify(source, Config.Notifications.deliveryNotReady, 'error')
        return false
    end

    for _, entry in ipairs(ActiveDelivery.items) do
        StoreStock[entry.item] = (StoreStock[entry.item] or 0) + entry.amount
    end

    ActiveDelivery.validated = true
    SaveStockToDB()

    TriggerClientEvent('ltd:client:deliveryComplete', source)
    Notify(source, Config.Notifications.deliveryValidated, 'success')

    SetTimeout(5000, function()
        ActiveDelivery = nil
    end)

    return true
end)

-- Joueurs proches (pour la caisse / recrutement)
lib.callback.register('ltd:server:getNearbyPlayers', function(source)
    local players = {}
    local sourcePed = GetPlayerPed(source)
    local sourceCoords = GetEntityCoords(sourcePed)

    for _, playerId in ipairs(GetPlayers()) do
        local id = tonumber(playerId)
        if id ~= source then
            local ped = GetPlayerPed(id)
            if #(sourceCoords - GetEntityCoords(ped)) <= 5.0 then
                table.insert(players, { id = id, name = GetPlayerName(id) })
            end
        end
    end
    return players
end)

-- =============================================================================
-- INITIALISATION
-- =============================================================================
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    InitDatabase()
    Wait(500)
    LoadStockFromDB()
    RegisterStash()

    print('^2[LTD-Grove]^7 Ressource démarrée — Framework: ' .. (Config.Framework or 'inconnu'))
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    SaveStockToDB()
end)

-- Sauvegarde périodique du stock (toutes les 5 minutes)
CreateThread(function()
    while true do
        Wait(300000)
        SaveStockToDB()
    end
end)
