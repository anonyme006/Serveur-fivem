local consuming = false

local function notify(msg)
    if ESX and ESX.ShowNotification then
        ESX.ShowNotification(msg)
        return
    end
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, true)
end

RegisterNetEvent('esx_consumables:client:notify', function(msg)
    if msg then notify(msg) end
end)

local function progressLabel(def)
    if def.notify and def.notify ~= '' then
        return def.notify
    end
    if def.type == 'drink' then
        return Config.DefaultDrinkLabel
    end
    return Config.DefaultFoodLabel
end

--- Lance la barre + anim, retourne true si terminé
local function runConsume(itemName, def)
    if consuming then
        notify('Action déjà en cours')
        return false
    end

    if GetResourceState('esx_progressbar') ~= 'started' then
        notify('esx_progressbar manquant')
        return false
    end

    consuming = true

    local action = {
        name = 'consume_' .. itemName,
        label = progressLabel(def),
        duration = def.duration or 4000,
        canCancel = true,
        disarm = true,
    }

    if def.anim then
        action.animation = {
            animDict = def.anim.dict,
            anim = def.anim.clip,
            flags = def.anim.flags or 49,
        }
    end

    if def.prop then
        action.prop = def.prop
    end

    local ok = exports['esx_progressbar']:ProgressAwait(action)
    consuming = false
    return ok
end

--- Utilisation via ESX usable item (serveur → client)
RegisterNetEvent('esx_consumables:client:use', function(itemName)
    local def = Config.Items[itemName]
    if not def then return end

    local ok = runConsume(itemName, def)
    if not ok then
        TriggerServerEvent('esx_consumables:server:cancelled', itemName)
        notify('~r~Action annulée')
        return
    end

    TriggerServerEvent('esx_consumables:server:consumed', itemName)
end)

--- Export pour ox_inventory (client.export = 'esx_consumables.useItem')
--- Appelé avec (nil, data) ou (data, slotData) selon version
local function useItemExport(data, extra)
    local itemName = nil
    if type(data) == 'string' then
        itemName = data
    elseif type(data) == 'table' then
        itemName = data.name or data.item or (data.metadata and data.metadata.name)
    end
    if not itemName and type(extra) == 'table' then
        itemName = extra.name
    end
    if not itemName then return end

    local def = Config.Items[itemName]
    if not def then
        -- fallback : type food/drink depuis metadata ox
        local meta = (type(data) == 'table' and data) or (type(extra) == 'table' and extra) or {}
        local status = meta.status or {}
        local isDrink = (status.thirst and status.thirst > 0) or meta.drink
        def = {
            type = isDrink and 'drink' or 'food',
            status = (isDrink and (status.thirst or 200000)) or (status.hunger or 200000),
            duration = meta.usetime or 4000,
            anim = isDrink and {
                dict = 'mp_player_intdrink',
                clip = 'loop_bottle',
                flags = 49,
            } or {
                dict = 'mp_player_inteat@burger',
                clip = 'mp_player_int_eat_burger',
                flags = 49,
            },
            notify = isDrink and Config.DefaultDrinkLabel or Config.DefaultFoodLabel,
        }
        Config.Items[itemName] = def -- cache soft
    end

    local ok = runConsume(itemName, def)
    if not ok then return false end

    -- ox_inventory retire déjà l'item si consume = 1 → skipRemove
    local usingOx = GetResourceState('ox_inventory') == 'started'
    TriggerServerEvent('esx_consumables:server:consumed', itemName, { skipRemove = usingOx })
    return true
end

exports('useItem', useItemExport)
exports('useFood', useItemExport)
exports('useDrink', useItemExport)

--- Commande de test
RegisterCommand('testeat', function(_, args)
    local name = args[1] or 'burger'
    TriggerEvent('esx_consumables:client:use', name)
end, false)

RegisterCommand('testdrink', function(_, args)
    local name = args[1] or 'water'
    TriggerEvent('esx_consumables:client:use', name)
end, false)
