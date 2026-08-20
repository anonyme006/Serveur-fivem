--[[
    Bridges automatiques — donne les clés :
    - sortie garage / fourrière (pa_garage / ox_garage)
    - achat concessionnaire (esx_concessionnaire)
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

--- pa_garage / ox_garage : après spawn client (sortie garage + fourrière)
RegisterNetEvent('ox_garage:registerSpawn', function(plate, _netId)
    giveFromGarage(source, plate)
end)

--- Client esx_core / concessionnaire → revendique les clés après achat
RegisterNetEvent('esx_core:keys:onVehicleAcquired', function(plate, label)
    local src = source
    giveFromPurchase(src, plate, label)
end)

--- Hooks génériques (autres scripts)
AddEventHandler('esx_vehicleshop:setVehicleOwned', function(src, plate)
    if type(src) == 'number' then
        giveFromPurchase(src, plate, plate)
    end
end)

AddEventHandler('esx_concessionnaire:vehiclePurchased', function(src, plate, model)
    if type(src) == 'number' then
        giveFromPurchase(src, plate, model or plate)
    end
end)
