--[[
  Bridge client pour ox_inventory_ui
  Ouvre le thème custom en miroir des événements ox_inventory.
]]

local uiOpen = false

local function nuiFocus(state)
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(false)
end

local function closeUi()
    if not uiOpen then return end
    uiOpen = false
    nuiFocus(false)
    SendNUIMessage({ action = 'closeInventory' })
end

local function openUi(payload)
    uiOpen = true
    nuiFocus(true)
    SendNUIMessage({
        action = 'setupInventory',
        data = payload or {},
    })
end

--- Ouverture manuelle (tests / fallback)
RegisterCommand('invui', function()
    local playerData = {
        playerName = GetPlayerName(PlayerId()) or 'Joueur',
        leftInventory = {
            id = 'player',
            label = GetPlayerName(PlayerId()) or 'Joueur',
            maxWeight = 60000,
            weight = 0,
            slots = 25,
            items = {},
        },
        rightInventory = {
            id = 'drop',
            label = '',
            maxWeight = 60000,
            weight = 0,
            slots = 25,
            items = {},
        },
    }

    -- Tente de récupérer l'inventaire ox si disponible
    local ok, items = pcall(function()
        return exports.ox_inventory:GetPlayerItems()
    end)

    if ok and type(items) == 'table' then
        local list, total = {}, 0
        for slot, item in pairs(items) do
            if item then
                list[#list + 1] = {
                    slot = item.slot or slot,
                    name = item.name,
                    label = item.label,
                    count = item.count,
                    weight = item.weight,
                    description = item.description,
                    metadata = item.metadata,
                }
                total = total + ((item.weight or 0) * (item.count or 1))
            end
        end
        playerData.leftInventory.items = list
        playerData.leftInventory.weight = total
    end

    openUi(playerData)
end, false)

RegisterNUICallback('exit', function(_, cb)
    closeUi()
    pcall(function()
        exports.ox_inventory:closeInventory()
    end)
    cb({ ok = true })
end)

RegisterNUICallback('closeInventory', function(_, cb)
    closeUi()
    cb({ ok = true })
end)

RegisterNUICallback('useItem', function(data, cb)
    if data and data.slot then
        pcall(function()
            exports.ox_inventory:useItem(data.slot)
        end)
        -- Fallback event
        TriggerServerEvent('ox_inventory:useItem', data.slot)
    end
    cb({ ok = true })
end)

RegisterNUICallback('giveItem', function(data, cb)
    if data and data.slot then
        TriggerServerEvent('ox_inventory:giveItem', data.slot, data.count or 1)
    end
    cb({ ok = true })
end)

RegisterNUICallback('setItemAmount', function(_, cb)
    cb({ ok = true })
end)

RegisterNUICallback('selectItem', function(_, cb)
    cb({ ok = true })
end)

-- ESC de secours
CreateThread(function()
    while true do
        if uiOpen and IsControlJustReleased(0, 322) then -- ESC
            closeUi()
        end
        Wait(uiOpen and 0 or 500)
    end
end)

exports('open', openUi)
exports('close', closeUi)
