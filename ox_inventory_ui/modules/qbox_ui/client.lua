if not lib then return end

local Config = lib.load('modules.qbox_ui.config')

---@type table<string, { label: string, icon: string, kind: 'component' | 'prop', id: number }>
local SLOT_DEFINITIONS = {
    mask = { label = 'Masque', icon = 'mask', kind = 'component', id = 1 },
    hat = { label = 'Chapeau', icon = 'hat', kind = 'prop', id = 0 },
    glasses = { label = 'Lunettes', icon = 'glasses', kind = 'prop', id = 1 },
    top = { label = 'Haut', icon = 'top', kind = 'component', id = 11 },
    vest = { label = 'Veste', icon = 'vest', kind = 'component', id = 9 },
    pants = { label = 'Pantalon', icon = 'pants', kind = 'component', id = 4 },
    shoes = { label = 'Chaussures', icon = 'shoes', kind = 'component', id = 6 },
    chain = { label = 'Chaînes', icon = 'chain', kind = 'component', id = 7 },
    ears = { label = 'Boucles d\'oreilles', icon = 'earrings', kind = 'prop', id = 2 },
    bag = { label = 'Sac', icon = 'bag', kind = 'component', id = 5 },
    belt = { label = 'Ceinture', icon = 'belt', kind = 'component', id = 8 },
    watch = { label = 'Montre', icon = 'watch', kind = 'prop', id = 6 },
    bracelet = { label = 'Bracelet', icon = 'bracelet', kind = 'prop', id = 7 },
    decals = { label = 'Décalque', icon = 'decals', kind = 'component', id = 10 },
    arms = { label = 'Bras/Gants', icon = 'arms', kind = 'component', id = 3 },
}

local LEFT_SLOTS = { 'mask', 'hat', 'glasses', 'top', 'vest', 'pants', 'shoes' }
local RIGHT_SLOTS = { 'chain', 'ears', 'bag', 'belt', 'watch', 'bracelet', 'decals', 'arms' }

local previewPed
local previewActive = false
local previewHeading = 0.0
local previewZoom = 1.0
local inventoryOpen = false
local statusThreadActive = false
local renderThread

local FE_MENU_VERSION_EMPTY = `FE_MENU_VERSION_EMPTY`
local FE_MENU_VERSION_EMPTY_NO_BACKGROUND = `FE_MENU_VERSION_EMPTY_NO_BACKGROUND`

local function readSlot(slotId)
    local def = SLOT_DEFINITIONS[slotId]
    if not def then return nil end

    local ped = cache.ped
    local drawable, texture, equipped

    if def.kind == 'prop' then
        drawable = GetPedPropIndex(ped, def.id)
        texture = drawable >= 0 and GetPedPropTextureIndex(ped, def.id) or 0
        equipped = drawable >= 0
    else
        drawable = GetPedDrawableVariation(ped, def.id)
        texture = GetPedTextureVariation(ped, def.id)
        equipped = drawable > 0
    end

    return {
        id = slotId,
        label = def.label,
        icon = def.icon,
        equipped = equipped,
        drawable = drawable,
        texture = texture,
        quantity = equipped and 1 or 0,
    }
end

local function getClothingSlotsPayload()
    local left, right = {}, {}

    for i = 1, #LEFT_SLOTS do
        left[i] = readSlot(LEFT_SLOTS[i])
    end

    for i = 1, #RIGHT_SLOTS do
        right[i] = readSlot(RIGHT_SLOTS[i])
    end

    return { left = left, right = right }
end

local function handleClothingSlot(slotId)
    local def = SLOT_DEFINITIONS[slotId]
    if not def then return end

    local ped = cache.ped
    local equipped

    if def.kind == 'prop' then
        equipped = GetPedPropIndex(ped, def.id) >= 0
    else
        equipped = GetPedDrawableVariation(ped, def.id) > 0
    end

    if equipped then
        if def.kind == 'prop' then
            ClearPedProp(ped, def.id)
        else
            SetPedComponentVariation(ped, def.id, 0, 0, 0)
        end

        if GetResourceState('rcore_clothing') == 'started' then
            TriggerEvent('rcore_clothing:saveCurrentSkin')
        end
    elseif GetResourceState('rcore_clothing') == 'started' then
        TriggerEvent('rcore_clothing:openChangingRoom')
    else
        lib.notify({
            type = 'inform',
            description = ('Aucun %s équipé. Utilisez un item vêtement de l\'inventaire.'):format(def.label),
        })
    end
end

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
            showCharacter = Config.ShowCharacter,
            showClothing = Config.ShowClothing,
            enableCharacterRotation = Config.EnableCharacterRotation,
            enableCharacterZoom = Config.EnableCharacterZoom,
            characterBackground = Config.CharacterBackground,
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

local function sendClothingUpdate()
    if not inventoryOpen or not Config.ShowClothing then return end
    SendNUIMessage({
        action = 'updateClothingSlots',
        data = getClothingSlotsPayload(),
    })
end

local function destroyPreviewPed()
    if previewPed and DoesEntityExist(previewPed) then
        DeleteEntity(previewPed)
    end
    previewPed = nil
end

local function cleanupPreview()
    previewActive = false
    SetFrontendActive(false)
    ReplaceHudColourWithRgba(117, 0, 0, 0, 186)
    destroyPreviewPed()
end

local function renderPreviewFrame()
    while previewActive do
        Wait(0)

        if GetCurrentFrontendMenuVersion() == FE_MENU_VERSION_EMPTY_NO_BACKGROUND then
            SetScriptGfxDrawBehindPausemenu(true)

            if Config.CharacterBackground == 'dark' then
                DrawRect(0.5, 0.5, 1.0, 1.0, 8, 8, 12, 180)
            end

            BeginScaleformMovieMethodOnFrontend('INSTRUCTIONAL_BUTTONS')
            ScaleformMovieMethodAddParamPlayerNameString('SET_DATA_SLOT_EMPTY')
            EndScaleformMovieMethod()

            BeginScaleformMovieMethodOnFrontendHeader('SHOW_MENU')
            ScaleformMovieMethodAddParamBool(false)
            EndScaleformMovieMethod()

            BeginScaleformMovieMethodOnFrontendHeader('SHOW_HEADING_DETAILS')
            ScaleformMovieMethodAddParamBool(false)
            EndScaleformMovieMethod()

            SetScriptGfxDrawBehindPausemenu(false)
        end

        if previewPed and DoesEntityExist(previewPed) then
            SetEntityHeading(previewPed, previewHeading)
        end
    end

    ResetScriptGfxAlign()
end

local function createPreviewPed()
    destroyPreviewPed()

    previewHeading = GetEntityHeading(cache.ped)
    previewPed = ClonePed(cache.ped, previewHeading, false, false)

    if not previewPed or not DoesEntityExist(previewPed) then
        return false
    end

    local x, y, z = table.unpack(GetEntityCoords(previewPed))
    SetEntityCoords(previewPed, x, y, z - (10.0 * previewZoom), false, false, false, false)
    FreezeEntityPosition(previewPed, true)
    SetEntityVisible(previewPed, false, false)
    SetEntityInvincible(previewPed, true)
    SetBlockingOfNonTemporaryEvents(previewPed, true)
    SetPedAsNoLongerNeeded(previewPed)

    if GetResourceState('rcore_clothing') == 'started' then
        local ok, skin = pcall(function()
            return exports.rcore_clothing:getPlayerSkin(true)
        end)

        if ok and skin then
            pcall(function()
                exports.rcore_clothing:setPedSkin(previewPed, skin)
            end)
        end
    end

    FinalizeHeadBlend(previewPed)
    return true
end

local function openPreview()
    if not Config.ShowCharacter or previewActive then return end

    previewActive = true
    previewZoom = 1.0

    SetFrontendActive(true)
    ActivateFrontendMenu(FE_MENU_VERSION_EMPTY, false, -1)
    Wait(100)

    N_0x98215325a695e78a(false)

    if not createPreviewPed() then
        previewActive = false
        SetFrontendActive(false)
        return
    end

    GivePedToPauseMenu(previewPed, Config.CharacterPedSlot)
    SetPauseMenuPedLighting(true)
    SetPauseMenuPedSleepState(true)
    ReplaceHudColourWithRgba(117, 0, 0, 0, 0)

    if renderThread then return end

    renderThread = CreateThread(function()
        renderPreviewFrame()
        renderThread = nil
    end)
end

local function closePreview()
    if not previewActive then return end
    cleanupPreview()
end

local function refreshPreviewPed()
    if not previewActive then return end
    if not createPreviewPed() then return end
    GivePedToPauseMenu(previewPed, Config.CharacterPedSlot)
    SetPauseMenuPedLighting(true)
    SetPauseMenuPedSleepState(true)
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
    sendClothingUpdate()
    openPreview()
    startStatusThread()
end

local function onInventoryClose()
    inventoryOpen = false
    statusThreadActive = false
    closePreview()
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

AddEventHandler('rcore_clothing:afterSkinLoaded', function()
    if inventoryOpen then
        refreshPreviewPed()
        sendClothingUpdate()
    end
end)

AddEventHandler('rcore_clothing:onClothingShopClosed', function()
    if inventoryOpen then
        refreshPreviewPed()
        sendClothingUpdate()
    end
end)

RegisterNUICallback('qboxUi:rotateCharacter', function(data, cb)
    if Config.EnableCharacterRotation and previewPed and DoesEntityExist(previewPed) then
        previewHeading = (previewHeading + (data.delta or 0)) % 360.0
        SetEntityHeading(previewPed, previewHeading)
    end
    cb({})
end)

RegisterNUICallback('qboxUi:zoomCharacter', function(data, cb)
    if Config.EnableCharacterZoom then
        previewZoom = lib.math.clamp((data.zoom or 1.0), 0.6, 1.6)
        refreshPreviewPed()
    end
    cb({})
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

    SetTimeout(250, function()
        if inventoryOpen then
            refreshPreviewPed()
            sendClothingUpdate()
        end
    end)

    cb({})
end)

RegisterNUICallback('qboxUi:clickClothingSlot', function(data, cb)
    local slotId = data and data.id

    if slotId and Config.ShowClothing then
        handleClothingSlot(slotId)
        SetTimeout(250, function()
            if inventoryOpen then
                refreshPreviewPed()
                sendClothingUpdate()
            end
        end)
    end

    cb({})
end)

RegisterNUICallback('qboxUi:requestInit', function(_, cb)
    cb(buildStatusPayload())
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    onInventoryClose()
end)

if LocalPlayer.state.invOpen then
    onInventoryOpen()
end

SendNUIMessage({
    action = 'initQboxUi',
    data = buildStatusPayload(),
})
