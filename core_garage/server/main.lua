--[[--------------------------------------------------------------------------
    core_garage — serveur principal
---------------------------------------------------------------------------]]

local function notify(source, msg, nType)
    TriggerClientEvent('ox_lib:notify', source, {
        title = _('garage'),
        description = msg,
        type = nType or 'inform',
        position = Config.Notify.position,
        duration = Config.Notify.duration,
    })
end

GarageNotify = notify

function GarageLog(action, data)
    MySQL.insert.await([[
        INSERT INTO garage_logs (action, plate, owner, identifier, garage, company, details)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        action,
        data.plate or '',
        data.owner,
        data.identifier,
        data.garage,
        data.company,
        GarageUtils.Encode(data.details or {}),
    })
    if Config.Company.consoleLog then
        print(('[core_garage:log] %s plate=%s by=%s'):format(action, data.plate or '?', data.identifier or '?'))
    end
end

---@param source number
---@return string|nil
function GarageGetIdentifier(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    return xPlayer and xPlayer.getIdentifier() or nil
end

--- Push garages au client
local function pushGarages(source)
    local list = {}
    for _, g in pairs(GarageDB.garages) do
        list[#list + 1] = {
            id = g.id,
            name = g.name,
            label = g.label,
            type = g.type,
            coords = g.coords,
            spawn = g.spawn,
            heading = g.heading,
            store = g.store,
            blip = g.blip,
            marker = g.marker,
            job = g.job,
            gang = g.gang,
            minGrade = g.min_grade,
            vehicleType = g.vehicle_type,
            impoundPrice = g.impound_price,
            impoundTime = g.impound_time,
            enabled = g.enabled,
        }
    end
    TriggerClientEvent('core_garage:client:setGarages', source, list)
end

function GarageBroadcast()
    local players = ESX.GetPlayers()
    for _, src in ipairs(players) do
        pushGarages(src)
    end
end

AddEventHandler('core_garage:server:dbReady', function()
    Wait(500)
    GarageBroadcast()
end)

RegisterNetEvent('esx:playerLoaded', function(playerId)
    local src = type(playerId) == 'number' and playerId or source
    if not GarageDB.ready then return end
    pushGarages(src)
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    CreateThread(function()
        while not GarageDB.ready do Wait(200) end
        Wait(1000)
        GarageBroadcast()
    end)
end)

lib.callback.register('core_garage:getGarages', function(source)
    local list = {}
    for _, g in pairs(GarageDB.garages) do
        list[#list + 1] = g
    end
    return list
end)

lib.callback.register('core_garage:getLocalePack', function()
    return {
        locale = Config.Locale,
        strings = Locales[Config.Locale] or Locales['fr'],
        ui = Config.UI,
        categories = Config.Categories,
        imageUrl = Config.General.vehicleImageUrl,
    }
end)

--- Paiement
function GaragePay(source, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return true end
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    local account = Config.General.payAccount or 'bank'
    local bal = xPlayer.getAccount(account)
    if not bal or (bal.money or 0) < amount then
        -- fallback cash
        if account ~= 'money' then
            local cash = xPlayer.getAccount('money')
            if cash and (cash.money or 0) >= amount then
                xPlayer.removeAccountMoney('money', amount, 'core_garage')
                return true
            end
        end
        return false
    end
    xPlayer.removeAccountMoney(account, amount, 'core_garage')
    return true
end

exports('GetGarage', function(name) return GarageDB.GetGarage(name) end)
exports('GetVehicleByPlate', function(plate)
    plate = GarageUtils.NormalizePlate(plate)
    return MySQL.single.await('SELECT * FROM garage_vehicles WHERE plate = ?', { plate })
end)
exports('SetVehicleStored', function(plate, stored, garage)
    plate = GarageUtils.NormalizePlate(plate)
    MySQL.update.await('UPDATE garage_vehicles SET stored = ?, garage = COALESCE(?, garage), net_id = NULL WHERE plate = ?', {
        stored and 1 or 0, garage, plate
    })
    GarageSecurity.UnlockPlate(plate)
end)
