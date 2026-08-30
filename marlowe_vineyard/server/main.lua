Marlowe = Marlowe or {}

local QBX = exports.qbx_core

---@param source number
---@return table|nil
local function getPlayer(source)
    return QBX:GetPlayer(source)
end

---@param player table
---@return boolean
local function isMarloweEmployee(player)
    return player
        and player.PlayerData
        and player.PlayerData.job
        and player.PlayerData.job.name == Config.Job
end

---@param player table
---@param minGrade number
---@return boolean
local function hasMinGrade(player, minGrade)
    return isMarloweEmployee(player) and player.PlayerData.job.grade.level >= minGrade
end

---@param player table
---@param requireDuty boolean
---@return boolean
local function isOnDuty(player, requireDuty)
    if not requireDuty then return true end
    return player.PlayerData.job.onduty == true
end

---@param source number
---@param coords vector3
---@param target vector3
---@param maxDistance number
---@return boolean
local function isNear(source, coords, target, maxDistance)
    if not coords then return false end
    return Marlowe.IsNearCoords(coords, target, maxDistance)
end

---@param source number
---@return vector3|nil
local function getPlayerCoords(source)
    local ped = GetPlayerPed(source)
    if ped <= 0 then return nil end
    return GetEntityCoords(ped)
end

---@param source number
---@param minGrade number
---@param requireDuty boolean
---@param coords? vector3
---@param target? vector3
---@param maxDistance? number
---@return table|nil, string|nil
function Marlowe.ValidatePlayer(source, minGrade, requireDuty, coords, target, maxDistance)
    local player = getPlayer(source)
    if not player then return nil, 'Joueur introuvable.' end
    if not isMarloweEmployee(player) then return nil, Config.Notifications.NoJob end
    if minGrade and not hasMinGrade(player, minGrade) then return nil, Config.Notifications.NoGrade end
    if requireDuty and not isOnDuty(player, true) then return nil, Config.Notifications.NoDuty end
    if coords and target and maxDistance and not isNear(source, coords, target, maxDistance) then
        return nil, Config.Notifications.TooFar
    end
    return player, nil
end

---@param source number
---@return table|nil
function Marlowe.GetValidatedMarlowePlayer(source)
    local player = getPlayer(source)
    if not isMarloweEmployee(player) then return nil end
    return player
end

---@param source number
---@param item string
---@param amount number
---@return boolean
local function hasItem(source, item, amount)
    local count = exports.ox_inventory:Search(source, 'count', item) or 0
    return count >= amount
end

---@param source number
---@param items table[]
---@return boolean
local function hasAnyWineForBottling(source, items)
    for i = 1, #items do
        local entry = items[i]
        if hasItem(source, entry.item, entry.amount) then
            return true
        end
    end
    return false
end

---@param source number
---@param items table[]
---@return string|nil, table|nil
local function getBottlingWine(source, items)
    for i = 1, #items do
        local entry = items[i]
        if hasItem(source, entry.item, entry.amount) then
            return entry.item, entry
        end
    end
    return nil, nil
end

---@param source number
---@param items table[]
---@return boolean
local function removeItems(source, items)
    for i = 1, #items do
        local entry = items[i]
        if not exports.ox_inventory:RemoveItem(source, entry.item, entry.amount) then
            return false
        end
    end
    return true
end

---@param source number
---@param items table[]
---@return boolean
local function hasAllItems(source, items)
    for i = 1, #items do
        local entry = items[i]
        if not hasItem(source, entry.item, entry.amount) then
            return false
        end
    end
    return true
end

local function registerStashes()
    local groups = { [Config.Job] = 0 }

    exports.ox_inventory:RegisterStash(
        Config.Stashes.RawMaterials.id,
        Config.Stashes.RawMaterials.label,
        Config.Stashes.RawMaterials.slots,
        Config.Stashes.RawMaterials.weight,
        nil,
        groups,
        Config.Vineyard.StockPoint.coords
    )

    exports.ox_inventory:RegisterStash(
        Config.Stashes.FinishedProducts.id,
        Config.Stashes.FinishedProducts.label,
        Config.Stashes.FinishedProducts.slots,
        Config.Stashes.FinishedProducts.weight,
        nil,
        groups,
        Config.Vineyard.StockPoint.coords
    )

    exports.ox_inventory:RegisterStash(
        Config.Stashes.DeliveryStock.id,
        Config.Stashes.DeliveryStock.label,
        Config.Stashes.DeliveryStock.slots,
        Config.Stashes.DeliveryStock.weight,
        nil,
        groups,
        Config.Vineyard.StockPoint.coords
    )
end

AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName ~= 'ox_inventory' and resourceName ~= GetCurrentResourceName() then return end
    registerStashes()
end)

lib.callback.register('marlowe:server:canOpenMenu', function(source)
    local player = Marlowe.GetValidatedMarlowePlayer(source)
    return player ~= nil
end)

lib.callback.register('marlowe:server:getPlayerInfo', function(source)
    local player = Marlowe.GetValidatedMarlowePlayer(source)
    if not player then return nil end

    local stats = MarloweDB.GetStats(player.PlayerData.citizenid)
    local dutySeconds = 0

    if player.PlayerData.job.onduty and stats.duty_started_at then
        dutySeconds = os.time() - stats.duty_started_at
    end

    return {
        grade = player.PlayerData.job.grade.level,
        gradeName = player.PlayerData.job.grade.name,
        onDuty = player.PlayerData.job.onduty,
        isBoss = player.PlayerData.job.isboss or false,
        dutySeconds = dutySeconds,
        stats = stats,
    }
end)

lib.callback.register('marlowe:server:toggleDuty', function(source)
    local player, err = Marlowe.ValidatePlayer(source, Config.Permissions.Duty, false)
    if not player then return false, err end

    local citizenid = player.PlayerData.citizenid
    local newDuty = not player.PlayerData.job.onduty
    exports.qbx_core:SetJobDuty(source, newDuty)

    if newDuty then
        MarloweDB.SetDutyStartedAt(citizenid, os.time())
    else
        local stats = MarloweDB.GetStats(citizenid)
        if stats.duty_started_at then
            MarloweDB.AddHoursWorked(citizenid, os.time() - stats.duty_started_at)
        end
        MarloweDB.SetDutyStartedAt(citizenid, nil)
    end

    return true, newDuty
end)

lib.callback.register('marlowe:server:openStash', function(source, stashKey)
    local player, err = Marlowe.ValidatePlayer(source, Config.Permissions.Stock, Config.RequireDuty.Production)
    if not player then return false, err end

    local stash = Config.Stashes[stashKey]
    if not stash then return false, 'Stash invalide.' end

    local coords = getPlayerCoords(source)
    if not isNear(source, coords, Config.Vineyard.StockPoint.coords, 5.0) then
        return false, Config.Notifications.TooFar
    end

    return true, stash.id
end)

lib.callback.register('marlowe:server:getStatistics', function(source)
    local player, err = Marlowe.ValidatePlayer(source, Config.Permissions.Statistics, false)
    if not player then return nil, err end
    return MarloweDB.GetStats(player.PlayerData.citizenid)
end)

RegisterNetEvent('marlowe:server:notify', function(message, nType)
    local src = source
    TriggerClientEvent('ox_lib:notify', src, {
        title = Config.Label,
        description = message,
        type = nType or 'inform',
    })
end)

Marlowe.HasItem = hasItem
Marlowe.HasAllItems = hasAllItems
Marlowe.RemoveItems = removeItems
Marlowe.HasAnyWineForBottling = hasAnyWineForBottling
Marlowe.GetBottlingWine = getBottlingWine
Marlowe.GetPlayerCoords = getPlayerCoords
Marlowe.IsMarloweEmployee = isMarloweEmployee
Marlowe.HasMinGradeServer = hasMinGrade
