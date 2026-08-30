if Config.Modules and Config.Modules.core == false then return end

--[[
    Bridges automatiques — donne les clés :
    - sortie garage / fourrière (ox_garage / qbx_garages)
    - achat concessionnaire (qbx_vehicleshop / qb-vehicleshop)
]]

if not Config.Keys.enabled then return end

local function giveFromGarage(src, plate)
    if not Config.Keys.giveOnGarageTakeOut then return end
    if type(plate) ~= 'string' or plate == '' then return end
    Core.EnsureVehicleKey(src, plate, plate, 'key_garage')
    if Core.Log then
        Core.Log('vehicles', '🚪 Sortie garage', ('Plaque `%s`'):format(Core.NormalizePlate(plate)), {
            color = 'info',
            src = src,
        })
    end
end

local function giveFromPurchase(src, plate, label)
    if not Config.Keys.giveOnPurchase then return end
    if type(plate) ~= 'string' or plate == '' then return end
    Core.EnsureVehicleKey(src, plate, label or plate, 'key_purchase')
end

--- pa_garage / ox_garage : après spawn client
RegisterNetEvent('ox_garage:registerSpawn', function(plate, _netId)
    giveFromGarage(source, plate)
end)

--- qbx_garages / forks similaires
RegisterNetEvent('qbx_garages:server:spawned', function(plate)
    giveFromGarage(source, plate)
end)

AddEventHandler('qbx_garages:server:vehicleTakenOut', function(src, plate)
    if type(src) == 'number' then
        giveFromGarage(src, plate)
    end
end)

--- Client / concessionnaire → revendique les clés après achat
RegisterNetEvent('qbx_ressources:keys:onVehicleAcquired', function(plate, label)
    giveFromPurchase(source, plate, label)
end)

--- qbx_vehicleshop / qb-vehicleshop
AddEventHandler('qbx_vehicleshop:server:buyVehicle', function(src, plate, model)
    if type(src) == 'number' then
        giveFromPurchase(src, plate, model or plate)
    end
end)

AddEventHandler('qb-vehicleshop:server:buyShowroomVehicle', function(src, plate)
    if type(src) == 'number' then
        giveFromPurchase(src, plate, plate)
    end
end)

RegisterNetEvent('qbx_vehicleshop:client:successfulBuy', function(plate, model)
    giveFromPurchase(source, plate, model or plate)
end)
