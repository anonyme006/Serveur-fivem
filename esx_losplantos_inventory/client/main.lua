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

local function GetNearbyPlayersSync()
    local players = {}
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local maxDist = Config.GiveDistance or 3.0
    local ids = {}

    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local ped = GetPlayerPed(player)
            if DoesEntityExist(ped) then
                local dist = #(myCoords - GetEntityCoords(ped))
                if dist <= maxDist then
                    local serverId = GetPlayerServerId(player)
                    ids[#ids + 1] = serverId
                    players[#players + 1] = {
                        id = serverId,
                        name = GetPlayerName(player) or ('ID ' .. serverId),
                        distance = dist,
                    }
                end
            end
        end
    end

    table.sort(players, function(a, b)
        return a.distance < b.distance
    end)

    -- Enrichit avec les noms RP si callback dispo (non bloquant pour le NUI)
    if #ids > 0 and ESX and ESX.TriggerServerCallback then
        ESX.TriggerServerCallback('esx_losplantos_inventory:getPlayerNames', function(names)
            if type(names) ~= 'table' then return end
            for i = 1, #players do
                local key = tostring(players[i].id)
                if names[key] and names[key] ~= '' then
                    players[i].name = names[key]
                end
            end
            if InventoryOpen then
                SendNUIMessage({ action = 'nearbyPlayers', players = players })
            end
        end, ids)
    end

    return players
end

local function BuildInventoryPayload()
    local playerData = ESX.GetPlayerData()
    local inventory = playerData.inventory or {}
    local accounts = playerData.accounts or {}
    local items = {}
    local currentWeight = 0.0

    -- Comptes (argent / argent sale)
    for _, account in ipairs(accounts) do
        local money = account.money or 0
        if Config.Accounts[account.name] and money > 0 then
            items[#items + 1] = {
                name = account.name,
                label = account.label or GetItemLabel({ name = account.name }),
                count = money,
                weight = 0,
                usable = false,
                canRemove = true,
                isAccount = true,
                image = GetItemImage(account.name),
            }
        end
    end

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
                usable = item.usable == true,
                canRemove = item.canRemove ~= false,
                isAccount = false,
                image = GetItemImage(item.name),
            }
        end
    end

    local maxWeight = Config.MaxWeight
    if playerData.maxWeight and playerData.maxWeight > 0 then
        maxWeight = playerData.maxWeight
    end

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

local function ResolveItem(data)
    local index = tonumber(data and data.index) or SelectedIndex
    return CachedItems[index], index
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
    SelectedIndex = tonumber(data.index) or 1
    cb('ok')
end)

RegisterNUICallback('notify', function(data, cb)
    if data and data.message then
        Notify(data.message)
    end
    cb('ok')
end)

RegisterNUICallback('getNearbyPlayers', function(_, cb)
    cb(GetNearbyPlayersSync())
end)

RegisterNUICallback('use', function(data, cb)
    local item = ResolveItem(data)
    if not item then
        cb({ ok = false })
        return
    end

    if item.isAccount then
        Notify('Cet objet ne peut pas être utilisé')
        cb({ ok = false })
        return
    end

    TriggerServerEvent('esx_losplantos_inventory:useItem', item.name)
    cb({ ok = true })
end)

RegisterNUICallback('give', function(data, cb)
    local item = ResolveItem(data)
    local count = math.floor(tonumber(data.count) or 1)
    local target = tonumber(data.target)

    if not item or count < 1 or not target then
        cb({ ok = false })
        return
    end

    if item.canRemove == false then
        Notify('Cet objet ne peut pas être donné')
        cb({ ok = false })
        return
    end

    TriggerServerEvent('esx_losplantos_inventory:giveItem', target, item.name, count, item.isAccount == true)
    cb({ ok = true })
end)

RegisterNUICallback('trade', function(data, cb)
    -- Échanger = donner à un joueur proche (sélectionné)
    local item = ResolveItem(data)
    local count = math.floor(tonumber(data.count) or 1)
    local target = tonumber(data.target)

    if not item or count < 1 or not target then
        cb({ ok = false })
        return
    end

    if item.canRemove == false then
        Notify('Cet objet ne peut pas être échangé')
        cb({ ok = false })
        return
    end

    TriggerServerEvent('esx_losplantos_inventory:giveItem', target, item.name, count, item.isAccount == true)
    cb({ ok = true })
end)

RegisterNUICallback('drop', function(data, cb)
    local item = ResolveItem(data)
    local count = math.floor(tonumber(data.count) or 1)

    if not item or count < 1 then
        cb({ ok = false })
        return
    end

    if item.canRemove == false then
        Notify('Cet objet ne peut pas être jeté')
        cb({ ok = false })
        return
    end

    TriggerServerEvent('esx_losplantos_inventory:dropItem', item.name, count, item.isAccount == true)
    cb({ ok = true })
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

RegisterNetEvent('esx:setAccountMoney', function()
    Wait(50)
    RefreshIfOpen()
end)

RegisterNetEvent('esx_losplantos_inventory:refresh', function()
    RefreshIfOpen()
end)

RegisterNetEvent('esx_losplantos_inventory:notify', function(msg)
    Notify(msg)
end)

CreateThread(function()
    while true do
        if InventoryOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 106, true)

            if IsDisabledControlJustPressed(0, 172) then
                SendNUIMessage({ action = 'key', key = 'up' })
            elseif IsDisabledControlJustPressed(0, 173) then
                SendNUIMessage({ action = 'key', key = 'down' })
            elseif IsDisabledControlJustPressed(0, 191) then
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

exports('OpenInventory', OpenInventory)
exports('CloseInventory', CloseInventory)
exports('IsInventoryOpen', function()
    return InventoryOpen
end)
