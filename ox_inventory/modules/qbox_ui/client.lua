if not lib then return end

local Config = lib.load('modules.qbox_ui.config')

local inventoryOpen = false
local statusThreadActive = false

---@param value number
---@return number
local function clampPercent(value)
    if type(value) ~= 'number' then return 0 end
    if value > 100 or value < -100 then
        value = value * 0.0001
    end
    return lib.math.clamp(math.floor(value + 0.5), 0, 100)
end

local function getHealthPercent()
    local ped = cache.ped
    local health = GetEntityHealth(ped) - 100
    local maxHealth = GetEntityMaxHealth(ped) - 100

    if maxHealth > 0 then
        return clampPercent((health / maxHealth) * 100)
    end

    if QBX and QBX.PlayerData and QBX.PlayerData.metadata and QBX.PlayerData.metadata.health then
        return clampPercent(QBX.PlayerData.metadata.health)
    end

    return 0
end

local function getArmorPercent()
    local armour = GetPedArmour(cache.ped)

    if armour > 0 then
        return clampPercent(armour)
    end

    if QBX and QBX.PlayerData and QBX.PlayerData.metadata and QBX.PlayerData.metadata.armor then
        return clampPercent(QBX.PlayerData.metadata.armor)
    end

    return 0
end

local function getHungerPercent()
    local state = LocalPlayer.state

    if state.hunger ~= nil then
        return clampPercent(state.hunger)
    end

    if QBX and QBX.PlayerData and QBX.PlayerData.metadata then
        return clampPercent(QBX.PlayerData.metadata.hunger or 100)
    end

    return 100
end

local function getThirstPercent()
    local state = LocalPlayer.state

    if state.thirst ~= nil then
        return clampPercent(state.thirst)
    end

    if QBX and QBX.PlayerData and QBX.PlayerData.metadata then
        return clampPercent(QBX.PlayerData.metadata.thirst or 100)
    end

    return 100
end

local function buildStatusPayload()
    return {
        config = {
            accentColor = Config.AccentColor,
            showHunger = Config.ShowHunger,
            showThirst = Config.ShowThirst,
            showHealth = Config.ShowHealth,
            showArmor = Config.ShowArmor,
            showRemoveOutfit = Config.ShowRemoveOutfit,
        },
        hunger = getHungerPercent(),
        thirst = getThirstPercent(),
        health = getHealthPercent(),
        armor = getArmorPercent(),
    }
end

local function sendStatusUpdate()
    if not inventoryOpen then return end

    SendNUIMessage({
        action = 'updatePlayerStatus',
        data = buildStatusPayload(),
    })
end

local function startStatusThread()
    if statusThreadActive then return end
    statusThreadActive = true

    CreateThread(function()
        while statusThreadActive and inventoryOpen do
            Wait(Config.StatusUpdateInterval)
            sendStatusUpdate()
        end

        statusThreadActive = false
    end)
end

local function onInventoryOpen()
    inventoryOpen = true
    sendStatusUpdate()
    startStatusThread()
end

local function onInventoryClose()
    inventoryOpen = false
    statusThreadActive = false
end

AddStateBagChangeHandler('invOpen', ('player:%s'):format(cache.serverId), function(_, _, value)
    if value then
        onInventoryOpen()
    else
        onInventoryClose()
    end
end)

for _, key in ipairs({ 'hunger', 'thirst' }) do
    AddStateBagChangeHandler(key, ('player:%s'):format(cache.serverId), function()
        sendStatusUpdate()
    end)
end

RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    if data and data.metadata and inventoryOpen then
        sendStatusUpdate()
    end
end)

RegisterNetEvent('qbx_core:client:onSetMetaData', function(metadata)
    if inventoryOpen and (metadata == 'hunger' or metadata == 'thirst' or metadata == 'health' or metadata == 'armor') then
        sendStatusUpdate()
    end
end)

AddEventHandler('gameEventTriggered', function(name, args)
    if not inventoryOpen then return end

    if name == 'CEventNetworkEntityDamage' and args[1] == cache.ped then
        sendStatusUpdate()
    end
end)

RegisterNUICallback('qboxUi:removeOutfit', function(_, cb)
    local ped = cache.ped

    for i = 0, 11 do
        if i ~= 2 then
            SetPedComponentVariation(ped, i, 0, 0, 0)
        end
    end

    for i = 0, 7 do
        ClearPedProp(ped, i)
    end

    if GetResourceState('rcore_clothing') == 'started' then
        TriggerEvent('rcore_clothing:saveCurrentSkin')
    end

    cb({})
end)

RegisterNUICallback('qboxUi:requestInit', function(_, cb)
    cb(buildStatusPayload())
end)

SendNUIMessage({
    action = 'initQboxUi',
    data = buildStatusPayload(),
})

if LocalPlayer.state.invOpen then
    onInventoryOpen()
end
