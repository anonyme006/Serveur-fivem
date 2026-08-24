local previewVehicle = nil
local previewCam = nil
local previewActive = false
local uiOpen = false
local showingTextUI = false
local currentZone = nil

local function notify(description, nType)
    lib.notify({
        title = Translate('shop_title'),
        description = description,
        type = nType or 'inform',
    })
end

local function formatMoney(n)
    n = math.floor(tonumber(n) or 0)
    local s = tostring(n)
    local left, num, right = string.match(s, '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

local function drawGroundMarker(coords, style)
    if not coords or not style then return end
    local z = (coords.z or 0.0) - 0.95
    DrawMarker(
        style.type or 25,
        coords.x + 0.0, coords.y + 0.0, z,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        (style.size and style.size.x) or 2.5,
        (style.size and style.size.y) or 2.5,
        (style.size and style.size.z) or 0.15,
        style.color.r, style.color.g, style.color.b, style.color.a,
        false, false, 2, false, nil, nil, false
    )
end

local function isSpawnClear(coords, radius)
    radius = radius or 2.6
    return not IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, radius)
end

local function findFreePark(zone)
    local parks = zone and zone.parks or {}
    for i = 1, #parks do
        if isSpawnClear(parks[i]) then
            return parks[i]
        end
    end
    return parks[1]
end

local function destroyPreview()
    if previewCam then
        RenderScriptCams(false, true, 350, true, true)
        DestroyCam(previewCam, false)
        previewCam = nil
    end

    if previewVehicle and DoesEntityExist(previewVehicle) then
        SetEntityAsMissionEntity(previewVehicle, true, true)
        DeleteVehicle(previewVehicle)
    end

    previewVehicle = nil
    previewActive = false
end

local function createPreviewCamera(vehicle, zone)
    if previewCam then
        DestroyCam(previewCam, false)
        previewCam = nil
    end

    local preview = (zone and zone.preview) or Config.Preview
    local offset = preview.camera and preview.camera.offset or vector3(-4.8, -3.6, 1.6)
    local fov = preview.camera and preview.camera.fov or 50.0
    local camCoords = GetOffsetFromEntityInWorldCoords(vehicle, offset.x, offset.y, offset.z)

    previewCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(previewCam, camCoords.x, camCoords.y, camCoords.z)
    PointCamAtEntity(previewCam, vehicle, 0.0, 0.0, 0.5, true)
    SetCamFov(previewCam, fov)
    SetCamActive(previewCam, true)
    RenderScriptCams(true, true, 450, true, true)
end

local function spawnPreviewVehicle(model, zone)
    destroyPreview()

    local hash = joaat(model)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        notify(Translate('invalid_model'), 'error')
        return
    end

    lib.requestModel(hash, 5000)

    local preview = (zone and zone.preview) or Config.Preview
    local coords = preview.coords
    local heading = preview.heading or 0.0

    previewVehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, false, false)
    SetModelAsNoLongerNeeded(hash)

    if not previewVehicle or previewVehicle == 0 then
        notify(Translate('preview_failed'), 'error')
        return
    end

    SetEntityAsMissionEntity(previewVehicle, true, true)
    SetVehicleOnGroundProperly(previewVehicle)
    SetEntityCollision(previewVehicle, false, false)
    SetEntityInvincible(previewVehicle, true)
    FreezeEntityPosition(previewVehicle, true)
    SetVehicleDoorsLocked(previewVehicle, 2)
    SetVehicleEngineOn(previewVehicle, false, true, true)
    SetVehicleDirtLevel(previewVehicle, 0.0)

    createPreviewCamera(previewVehicle, zone)
    previewActive = true
end

local function closeUi()
    uiOpen = false
    lib.hideContext(false)
    if showingTextUI then
        lib.hideTextUI()
        showingTextUI = false
    end
    destroyPreview()
end

local function getVehiclesByCategory(category)
    local list = {}
    for i = 1, #Config.Vehicles do
        local vehicle = Config.Vehicles[i]
        if vehicle.category == category then
            list[#list + 1] = vehicle
        end
    end

    table.sort(list, function(a, b)
        return a.price < b.price
    end)

    return list
end

local function spawnPurchasedVehicle(data)
    local hash = joaat(data.model)
    if not IsModelInCdimage(hash) then
        notify(Translate('purchase_failed'), 'error')
        return
    end

    lib.requestModel(hash, 5000)

    local c = data.coords
    local heading = data.heading or 0.0
    local vehicle = CreateVehicle(hash, c.x, c.y, c.z, heading, true, false)
    SetModelAsNoLongerNeeded(hash)

    if not vehicle or vehicle == 0 then
        notify(Translate('purchase_failed'), 'error')
        return
    end

    SetVehicleOnGroundProperly(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehicleNumberPlateText(vehicle, data.plate)
    SetVehicleEngineOn(vehicle, false, true, false)
    SetVehicleDoorsLocked(vehicle, 1)
    SetVehicleDirtLevel(vehicle, 0.0)

    if GetResourceState('ox_fuel') == 'started' then
        Entity(vehicle).state.fuel = 100
    else
        SetVehicleFuelLevel(vehicle, 100.0)
    end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    SetNetworkIdCanMigrate(netId, true)
    TriggerServerEvent('qbx_concessionnaire:server:vehicleSpawned', data.plate, netId)
    notify(Translate('vehicle_out'), 'success')
end

local function openVehicleActions(vehicle, zone)
    lib.registerContext({
        id = 'qbx_dealership_vehicle_actions',
        title = ('%s — $%s'):format(vehicle.name, formatMoney(vehicle.price)),
        menu = 'qbx_dealership_vehicles',
        options = {
            {
                title = Translate('preview'),
                description = Translate('preview_desc'),
                icon = 'eye',
                onSelect = function()
                    spawnPreviewVehicle(vehicle.model, zone)
                    openVehicleActions(vehicle, zone)
                end,
            },
            {
                title = Translate('buy'),
                description = Translate('buy_desc'),
                icon = 'cart-shopping',
                onSelect = function()
                    local alert = lib.alertDialog({
                        header = Translate('confirm_title'),
                        content = Translate('confirm_buy', vehicle.name, formatMoney(vehicle.price)),
                        centered = true,
                        cancel = true,
                    })

                    if alert ~= 'confirm' then
                        openVehicleActions(vehicle, zone)
                        return
                    end

                    local park = findFreePark(zone)
                    if not park then
                        notify(Translate('spawn_blocked'), 'error')
                        openVehicleActions(vehicle, zone)
                        return
                    end

                    if not isSpawnClear(park) then
                        notify(Translate('spawn_blocked'), 'error')
                        openVehicleActions(vehicle, zone)
                        return
                    end

                    local result = lib.callback.await('qbx_concessionnaire:buyVehicle', false, vehicle.model, {
                        x = park.x,
                        y = park.y,
                        z = park.z,
                        w = park.w,
                    })

                    if result and result.ok then
                        closeUi()
                        notify(Translate('purchase_success', result.name, formatMoney(result.price)), 'success')
                    else
                        local reason = result and result.reason or 'purchase_failed'
                        if reason == 'money' then
                            notify(Translate('not_enough_money'), 'error')
                        else
                            notify(Translate(reason), 'error')
                        end
                        openVehicleActions(vehicle, zone)
                    end
                end,
            },
            {
                title = Translate('close'),
                icon = 'xmark',
                onSelect = function()
                    closeUi()
                end,
            },
        },
    })

    lib.showContext('qbx_dealership_vehicle_actions')
end

local function openVehicleList(categoryId, categoryLabel, zone)
    local vehicles = getVehiclesByCategory(categoryId)
    if #vehicles == 0 then
        notify(Translate('no_vehicles'), 'error')
        return
    end

    local options = {}
    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        options[#options + 1] = {
            title = vehicle.name,
            description = Translate('vehicle_price', formatMoney(vehicle.price)),
            icon = 'car',
            onSelect = function()
                openVehicleActions(vehicle, zone)
            end,
        }
    end

    lib.registerContext({
        id = 'qbx_dealership_vehicles',
        title = categoryLabel,
        menu = 'qbx_dealership_categories',
        options = options,
    })

    lib.showContext('qbx_dealership_vehicles')
end

local function openSearchResults(query, zone)
    local q = query:lower()
    local options = {}

    for i = 1, #Config.Vehicles do
        local vehicle = Config.Vehicles[i]
        if vehicle.name:lower():find(q, 1, true) or vehicle.model:lower():find(q, 1, true) then
            options[#options + 1] = {
                title = vehicle.name,
                description = Translate('vehicle_price', formatMoney(vehicle.price)),
                icon = 'car',
                onSelect = function()
                    openVehicleActions(vehicle, zone)
                end,
            }
        end
    end

    if #options == 0 then
        notify(Translate('no_results'), 'error')
        return
    end

    lib.registerContext({
        id = 'qbx_dealership_search',
        title = Translate('search_results'),
        menu = 'qbx_dealership_categories',
        options = options,
    })

    lib.showContext('qbx_dealership_search')
end

local function openDealershipMenu(zone)
    if uiOpen then return end
    zone = zone or currentZone or Config.Zones[1]
    if not zone then return end

    uiOpen = true
    currentZone = zone

    local options = {
        {
            title = Translate('search'),
            description = Translate('search_desc'),
            icon = 'magnifying-glass',
            onSelect = function()
                local input = lib.inputDialog(Translate('search'), {
                    { type = 'input', label = Translate('search_placeholder'), required = true, min = 1 },
                })

                if input and input[1] then
                    openSearchResults(input[1], zone)
                else
                    uiOpen = false
                    openDealershipMenu(zone)
                end
            end,
        },
    }

    for i = 1, #Config.Categories do
        local category = Config.Categories[i]
        options[#options + 1] = {
            title = category.label,
            description = Translate('category_desc'),
            icon = 'tags',
            onSelect = function()
                openVehicleList(category.id, category.label, zone)
            end,
        }
    end

    options[#options + 1] = {
        title = Translate('close'),
        icon = 'xmark',
        onSelect = function()
            closeUi()
        end,
    }

    lib.registerContext({
        id = 'qbx_dealership_categories',
        title = zone.label or Translate('shop_title'),
        options = options,
        onExit = function()
            closeUi()
        end,
    })

    lib.showContext('qbx_dealership_categories')
end

RegisterNetEvent('qbx_concessionnaire:client:spawnPurchased', function(data)
    if type(data) ~= 'table' or not data.model or not data.plate or not data.coords then
        return
    end
    spawnPurchasedVehicle(data)
end)

RegisterNetEvent('qbx_concessionnaire:client:giveKeys', function(netId, plate)
    local vehicle = netId and NetworkGetEntityFromNetworkId(netId) or 0
    if vehicle ~= 0 and DoesEntityExist(vehicle) then
        pcall(function()
            exports.qbx_vehiclekeys:GiveKeys(vehicle)
        end)
    end
    TriggerEvent('qb-vehiclekeys:client:AddKeys', plate)
    TriggerEvent('vehiclekeys:client:SetOwner', plate)
end)

CreateThread(function()
    for i = 1, #Config.Zones do
        local zone = Config.Zones[i]
        if zone.blip and zone.blip.enabled then
            local blip = AddBlipForCoord(zone.menu.x, zone.menu.y, zone.menu.z)
            SetBlipSprite(blip, zone.blip.sprite or 326)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, zone.blip.scale or 0.85)
            SetBlipColour(blip, zone.blip.colour or 5)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(zone.blip.label or zone.label or Translate('blip_label'))
            EndTextCommandSetBlipName(blip)
        end
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local nearMenu = false
        local nearZone = nil

        for i = 1, #Config.Zones do
            local zone = Config.Zones[i]
            local menuDist = #(coords - zone.menu)
            local drawDistance = zone.drawDistance or 35.0

            if menuDist < drawDistance then
                sleep = 0

                -- Point rouge = menu
                drawGroundMarker(zone.menu, Config.Markers.menu)

                -- Points verts = places de livraison
                local parks = zone.parks or {}
                for p = 1, #parks do
                    drawGroundMarker(parks[p], Config.Markers.park)
                end

                if menuDist < (zone.interactDistance or 1.8) then
                    nearMenu = true
                    nearZone = zone
                end
            end
        end

        if nearMenu and nearZone and not uiOpen then
            currentZone = nearZone
            if not showingTextUI then
                lib.showTextUI(Translate('press_open'), { position = 'right-center', icon = 'shop' })
                showingTextUI = true
            end

            if IsControlJustReleased(0, 38) then
                if showingTextUI then
                    lib.hideTextUI()
                    showingTextUI = false
                end
                openDealershipMenu(nearZone)
            end
        elseif showingTextUI and not uiOpen then
            lib.hideTextUI()
            showingTextUI = false
        end

        if previewActive and previewVehicle and DoesEntityExist(previewVehicle) then
            sleep = 0
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 47, true)
            DisableControlAction(0, 58, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)

            if Config.CloseWithEscape and (IsControlJustReleased(0, 177) or IsControlJustReleased(0, 200)) then
                closeUi()
            end
        end

        Wait(sleep)
    end
end)

RegisterCommand('concessionnaire', function()
    openDealershipMenu(currentZone or Config.Zones[1])
end, false)

exports('OpenDealership', function(name)
    if name then
        for i = 1, #Config.Zones do
            if Config.Zones[i].name == name then
                openDealershipMenu(Config.Zones[i])
                return
            end
        end
    end
    openDealershipMenu(currentZone or Config.Zones[1])
end)

exports('CloseDealership', function()
    closeUi()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    closeUi()
end)
