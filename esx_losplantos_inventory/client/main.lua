local InventoryOpen = false
local SelectedIndex = 1
local CachedItems = {}

local function Notify(msg)
    if ESX and ESX.ShowNotification then
        ESX.ShowNotification(msg)
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(msg)
        EndTextCommandThefeedPostTicker(false, true)
    end
end

local function GetItemImage(name)
    local key = string.lower(name or '')
    local file = Config.ItemImages[key] or 'default.svg'
    return ('nui://%s/html/img/%s'):format(GetCurrentResourceName(), file)
end

local function GetItemLabel(item)
    if item.label and item.label ~= '' then
        return item.label
    end
    local key = string.lower(item.name or '')
    return Config.ItemLabels[key] or item.name
end

local function BuildInventoryPayload()
    local playerData = ESX.GetPlayerData()
    local inventory = playerData.inventory or {}
    local items = {}
    local currentWeight = 0.0

    for _, item in ipairs(inventory) do
        local count = item.count or item.amount or 0
        if Config.ShowEmptyItems or count > 0 then
            local weight = (item.weight or 0) * count
            currentWeight = currentWeight + weight
            items[#items + 1] = {
                name = item.name,
                label = GetItemLabel(item),
                count = count,
                weight = item.weight or 0,
                usable = item.usable == true or item.canRemove == true,
                canRemove = item.canRemove ~= false,
                image = GetItemImage(item.name),
            }
        end
    end

    -- Compte le poids via ESX Legacy si dispo
    if playerData.maxWeight then
        -- ok
    end

    local maxWeight = Config.MaxWeight
    if playerData.maxWeight and playerData.maxWeight > 0 then
        maxWeight = playerData.maxWeight
    end

    -- Certains ESX exposent weight déjà calculé
    if playerData.weight then
        currentWeight = playerData.weight
    end

    CachedItems = items

    return {
        items = items,
        weight = currentWeight,
        maxWeight = maxWeight,
        selected = SelectedIndex,
    }
end

local function SendInventory()
    local payload = BuildInventoryPayload()
    if SelectedIndex > #payload.items then
        SelectedIndex = math.max(1, #payload.items)
        payload.selected = SelectedIndex
    elseif SelectedIndex < 1 and #payload.items > 0 then
        SelectedIndex = 1
        payload.selected = SelectedIndex
    end
    SendNUIMessage({
        action = 'open',
        data = payload,
    })
end

local function OpenInventory()
    if InventoryOpen then return end
    if not ESX or not ESX.IsPlayerLoaded or not ESX.IsPlayerLoaded() then
        return
    end

    InventoryOpen = true
    SelectedIndex = 1
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    SendInventory()
end

local function CloseInventory()
    if not InventoryOpen then return end
    InventoryOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function RefreshIfOpen()
    if InventoryOpen then
        SendInventory()
    end
end

RegisterCommand('losplantos_inventory', function()
    if InventoryOpen then
        CloseInventory()
    else
        OpenInventory()
    end
end, false)

RegisterKeyMapping('losplantos_inventory', 'Ouvrir inventaire Los Plantos', 'keyboard', Config.OpenKey)

RegisterNUICallback('close', function(_, cb)
    CloseInventory()
    cb('ok')
end)

RegisterNUICallback('select', function(data, cb)
    local index = tonumber(data.index) or 1
    SelectedIndex = index
    cb('ok')
end)

RegisterNUICallback('use', function(data, cb)
    local index = tonumber(data.index) or SelectedIndex
    local item = CachedItems[index]
    if not item then
        cb('error')
        return
    end

    TriggerServerEvent('esx_losplantos_inventory:useItem', item.name)
    cb('ok')
end)

RegisterNUICallback('give', function(data, cb)
    local index = tonumber(data.index) or SelectedIndex
    local count = tonumber(data.count) or 1
    local item = CachedItems[index]
    if not item then
        cb('error')
        return
    end

    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
    if closestPlayer == -1 or closestDistance > 3.0 then
        Notify('Aucun joueur à proximité')
        cb('error')
        return
    end

    TriggerServerEvent('esx_losplantos_inventory:giveItem', GetPlayerServerId(closestPlayer), item.name, count)
    cb('ok')
end)

RegisterNUICallback('drop', function(data, cb)
    local index = tonumber(data.index) or SelectedIndex
    local count = tonumber(data.count) or 1
    local item = CachedItems[index]
    if not item then
        cb('error')
        return
    end

    TriggerServerEvent('esx_losplantos_inventory:dropItem', item.name, count)
    cb('ok')
end)

RegisterNUICallback('navigate', function(data, cb)
    local dir = data.direction
    local count = #CachedItems
    if count == 0 then
        cb('ok')
        return
    end

    if dir == 'up' then
        SelectedIndex = SelectedIndex - 1
        if SelectedIndex < 1 then SelectedIndex = count end
    elseif dir == 'down' then
        SelectedIndex = SelectedIndex + 1
        if SelectedIndex > count then SelectedIndex = 1 end
    end

    SendNUIMessage({
        action = 'select',
        index = SelectedIndex,
    })
    cb('ok')
end)

-- Sync inventaire ESX
RegisterNetEvent('esx:playerLoaded', function()
    RefreshIfOpen()
end)

RegisterNetEvent('esx:setInventory', function()
    Wait(50)
    RefreshIfOpen()
end)

RegisterNetEvent('esx:addInventoryItem', function()
    Wait(50)
    RefreshIfOpen()
end)

RegisterNetEvent('esx:removeInventoryItem', function()
    Wait(50)
    RefreshIfOpen()
end)

RegisterNetEvent('esx_losplantos_inventory:refresh', function()
    RefreshIfOpen()
end)

-- Contrôles clavier pendant NUI (flèches / entrée)
CreateThread(function()
    while true do
        if InventoryOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 106, true)

            if IsDisabledControlJustPressed(0, 172) then -- UP
                SendNUIMessage({ action = 'key', key = 'up' })
            elseif IsDisabledControlJustPressed(0, 173) then -- DOWN
                SendNUIMessage({ action = 'key', key = 'down' })
            elseif IsDisabledControlJustPressed(0, 191) then -- ENTER
                SendNUIMessage({ action = 'key', key = 'enter' })
            elseif IsDisabledControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 200) then
                CloseInventory()
            end
            Wait(0)
        else
            Wait(250)
        end
    end
end)

-- Export pour d'autres scripts
exports('OpenInventory', OpenInventory)
exports('CloseInventory', CloseInventory)
exports('IsInventoryOpen', function()
    return InventoryOpen
end)
