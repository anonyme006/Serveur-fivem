Client = Client or {}
Client.npcPeds = Client.npcPeds or {}

local SPAWN_DISTANCE = Config.Sync.managementRadius or 80.0
local DESPAWN_DISTANCE = SPAWN_DISTANCE + 15.0

local function L(key)
    local locale = Locales[Config.Locale] or Locales.fr or {}
    return locale[key] or key
end

---@param shop table
---@return boolean
local function isNpcEnabledForShop(shop)
    local npc = shop.npc or {}
    if npc.enabled == true or npc.enabled == 1 then
        return true
    end
    if Config.Npc.enabled then
        return npc.enabled ~= false and npc.enabled ~= 0
    end
    return false
end

---@param shop table
---@return table|nil
local function getNpcCoords(shop)
    local npc = shop.npc or {}
    if npc.x and npc.y and npc.z then
        return {
            x = npc.x,
            y = npc.y,
            z = npc.z,
            w = npc.w or 0.0,
        }
    end

    local customer = Client.GetShopLocation(shop, ShopCreator.LocationTypes.customer)
    if customer then
        return customer
    end

    return Client.GetPrimaryCoords(shop)
end

---@param shopId number
local function removeNpcPed(shopId)
    local ped = Client.npcPeds[shopId]
    if not ped then return end

    if DoesEntityExist(ped) then
        exports.ox_target:removeLocalEntity(ped)
        SetEntityAsMissionEntity(ped, true, true)
        DeleteEntity(ped)
    end

    Client.npcPeds[shopId] = nil
end

---@param model string
---@return number|nil
local function loadModel(model)
    local hash = joaat(model)
    if not IsModelInCdimage(hash) then return nil end

    RequestModel(hash)
    local timeout = GetGameTimer() + 10000
    while not HasModelLoaded(hash) do
        if GetGameTimer() > timeout then
            return nil
        end
        Wait(0)
    end

    return hash
end

---@param shop table
local function spawnNpcPed(shop)
    local shopId = shop.id
    if Client.npcPeds[shopId] and DoesEntityExist(Client.npcPeds[shopId]) then
        return
    end

    if not isNpcEnabledForShop(shop) then
        removeNpcPed(shopId)
        return
    end

    local coords = getNpcCoords(shop)
    if not coords then return end

    local npc = shop.npc or {}
    local model = npc.model or Config.Npc.model or 'mp_m_shopkeep_01'
    local hash = loadModel(model)
    if not hash then return end

    local ped = CreatePed(0, hash, coords.x, coords.y, coords.z - 1.0, coords.w or 0.0, false, false)
    SetModelAsNoLongerNeeded(hash)

    if not DoesEntityExist(ped) then return end

    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)

    local scenario = npc.scenario or Config.Npc.scenario
    if scenario and scenario ~= '' then
        TaskStartScenarioInPlace(ped, scenario, 0, true)
    end

    exports.ox_target:addLocalEntity(ped, {
        {
            name = ('shopcreator_npc_%s'):format(shopId),
            icon = Config.Target.icon,
            label = L('open_shop'),
            distance = Config.Target.distance or 2.0,
            canInteract = function()
                return shop.enabled and Client.IsShopOpenLocal(shop)
            end,
            onSelect = function()
                Client.OpenStorefront(shopId, 'storefront')
            end,
        },
    })

    Client.npcPeds[shopId] = ped
end

---@param shop table
local function refreshNpcForShop(shop)
    removeNpcPed(shop.id)
    if not shop.enabled or shop.enabled == 0 or shop.enabled == false then
        return
    end
    if not isNpcEnabledForShop(shop) then
        return
    end

    local coords = getNpcCoords(shop)
    if not coords then return end

    local playerCoords = GetEntityCoords(cache.ped or PlayerPedId())
    local dist = ShopCreator.Distance(playerCoords, coords)
    if dist <= SPAWN_DISTANCE then
        spawnNpcPed(shop)
    end
end

function Client.RebuildNpc(shopId)
    local shop = Client.GetShop(shopId)
    if shop then
        refreshNpcForShop(shop)
    else
        removeNpcPed(shopId)
    end
end

function Client.RebuildAllNpcs()
    for shopId in pairs(Client.npcPeds) do
        removeNpcPed(shopId)
    end

    for _, shop in pairs(Client.shops) do
        refreshNpcForShop(shop)
    end
end

function Client.CleanupNpcs()
    for shopId in pairs(Client.npcPeds) do
        removeNpcPed(shopId)
    end
end

AddEventHandler('qbx_shopcreator:internal:shopUpdated', function(shopId)
    Client.RebuildNpc(shopId)
end)

AddEventHandler('qbx_shopcreator:internal:shopRemoved', function(shopId)
    removeNpcPed(shopId)
end)

AddEventHandler('qbx_shopcreator:internal:shopsSynced', function()
    Client.RebuildAllNpcs()
end)

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(500)
    end

    while true do
        local waitMs = 1500
        local playerCoords = GetEntityCoords(cache.ped or PlayerPedId())

        for _, shop in pairs(Client.shops) do
            if not shop.enabled or shop.enabled == 0 or shop.enabled == false then
                removeNpcPed(shop.id)
                goto continue
            end

            if not isNpcEnabledForShop(shop) then
                removeNpcPed(shop.id)
                goto continue
            end

            local coords = getNpcCoords(shop)
            if not coords then
                goto continue
            end

            local dist = ShopCreator.Distance(playerCoords, coords)
            local ped = Client.npcPeds[shop.id]

            if dist <= SPAWN_DISTANCE then
                if not ped or not DoesEntityExist(ped) then
                    spawnNpcPed(shop)
                end
            elseif dist >= DESPAWN_DISTANCE then
                if ped then
                    removeNpcPed(shop.id)
                end
            end

            ::continue::
        end

        Wait(waitMs)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= ShopCreator.Resource then return end
    Client.CleanupNpcs()
end)
