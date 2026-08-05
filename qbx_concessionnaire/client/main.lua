local isOpen = false
local previewVehicle = nil
local previewCam = nil
local currentZone = nil
local selectedCategory = nil
local isClosing = false

local function notify(msg, nType)
    lib.notify({
        title = Translate('shop_title'),
        description = msg,
        type = nType or 'inform',
    })
end

local function formatMoney(amount)
    local n = math.floor(tonumber(amount) or 0)
    local s = tostring(n)
    local left, num, right = string.match(s, '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

local function deletePreview()
    if previewVehicle then
        if DoesEntityExist(previewVehicle) then
            SetEntityAsMissionEntity(previewVehicle, true, true)
            SetEntityCollision(previewVehicle, false, false)
            DeleteVehicle(previewVehicle)
            if DoesEntityExist(previewVehicle) then
                DeleteEntity(previewVehicle)
            end
        end
        previewVehicle = nil
    end
end

local function destroyCamera()
    if previewCam then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(previewCam, false)
        previewCam = nil
    end
    ClearFocus()
    RenderScriptCams(false, false, 0, true, true)
end

local function updateCameraToVehicle()
    local vehCoords = Config.Preview.coords
    if previewVehicle and DoesEntityExist(previewVehicle) then
        vehCoords = GetEntityCoords(previewVehicle)
    end

    local offset = (Config.Preview.camera and Config.Preview.camera.offset) or vector3(-4.8, -3.6, 1.6)
    local camPos = vector3(
        vehCoords.x + offset.x,
        vehCoords.y + offset.y,
        vehCoords.z + offset.z
    )
    local lookAt = vector3(vehCoords.x, vehCoords.y, vehCoords.z + 0.55)
    local fov = (Config.Preview.camera and Config.Preview.camera.fov) or 50.0

    if not previewCam then
        previewCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    end

    SetCamCoord(previewCam, camPos.x, camPos.y, camPos.z)
    PointCamAtCoord(previewCam, lookAt.x, lookAt.y, lookAt.z)
    SetCamFov(previewCam, fov)
    SetCamActive(previewCam, true)
    RenderScriptCams(true, true, 400, true, true)
end

local function createCamera()
    destroyCamera()
    updateCameraToVehicle()
end

local function spawnPreview(model)
    deletePreview()

    local hash = joaat(model)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        return
    end

    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(10)
    end

    if not HasModelLoaded(hash) then
        return
    end

    local c = Config.Preview.coords
    previewVehicle = CreateVehicle(hash, c.x + 0.0, c.y + 0.0, c.z + 0.0, Config.Preview.heading + 0.0, false, false)
    SetEntityAsMissionEntity(previewVehicle, true, true)
    SetVehicleOnGroundProperly(previewVehicle)
    SetEntityInvincible(previewVehicle, true)
    SetVehicleDoorsLocked(previewVehicle, 2)
    FreezeEntityPosition(previewVehicle, true)
    SetEntityCollision(previewVehicle, false, false)
    SetEntityAlpha(previewVehicle, 230, false)
    SetVehicleNumberPlateText(previewVehicle, 'PREVIEW')
    SetModelAsNoLongerNeeded(hash)

    updateCameraToVehicle()
end

local function releasePlayer()
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    ClearPedTasksImmediately(ped)
    SetPlayerControl(PlayerId(), true, 0)
    SetEveryoneIgnorePlayer(PlayerId(), false)
    DisplayRadar(true)
end

local function closeShop()
    if isClosing then return end
    isClosing = true

    isOpen = false
    selectedCategory = nil

    pcall(function() lib.hideContext() end)
    pcall(function() lib.hideTextUI() end)

    deletePreview()
    destroyCamera()
    releasePlayer()

    isClosing = false
end

local function getCategoryLabel(categoryId)
    for i = 1, #Config.Categories do
        if Config.Categories[i].id == categoryId then
            return Config.Categories[i].label
        end
    end
    return categoryId
end

local function getVehiclesByCategory(categoryId, search)
    local list = {}
    local q = search and search:lower() or nil
    for i = 1, #Config.Vehicles do
        local v = Config.Vehicles[i]
        local catOk = not categoryId or v.category == categoryId
        local searchOk = not q
            or (v.name and v.name:lower():find(q, 1, true))
            or (v.model and v.model:lower():find(q, 1, true))
        if catOk and searchOk then
            list[#list + 1] = v
        end
    end
    return list
end

local openCategoriesMenu, openVehicleList, openVehicleActions

local function buyVehicle(vehicle)
    local confirm = lib.alertDialog({
        header = Translate('shop_title'),
        content = Translate('confirm_buy', vehicle.name, formatMoney(vehicle.price)),
        centered = true,
        cancel = true,
        labels = {
            confirm = Translate('buy'),
            cancel = Translate('cancel'),
        },
    })

    if confirm ~= 'confirm' then
        openVehicleActions(vehicle)
        return
    end

    local result = lib.callback.await('qbx_concessionnaire:buyVehicle', false, vehicle.model)
    if result and result.ok then
        closeShop()
        notify(Translate('purchase_success', result.name, formatMoney(result.price)), 'success')
        notify(Translate('vehicle_out'), 'inform')
    else
        local reason = result and result.reason or 'purchase_failed'
        if reason == 'money' then
            notify(Translate('not_enough_money'), 'error')
        else
            local msg = Translate(reason)
            if msg == reason then msg = Translate('purchase_failed') end
            notify(msg, 'error')
        end
        openVehicleActions(vehicle)
    end
end

openVehicleActions = function(vehicle)
    spawnPreview(vehicle.model)

    lib.registerContext({
        id = 'qbx_concessionnaire_vehicle',
        title = vehicle.name,
        menu = 'qbx_concessionnaire_list',
        onExit = closeShop,
        options = {
            {
                title = Translate('buy'),
                description = ('$%s'):format(formatMoney(vehicle.price)),
                icon = 'cart-shopping',
                iconColor = '#3dde6a',
                onSelect = function()
                    buyVehicle(vehicle)
                end,
            },
            {
                title = 'Prévisualiser',
                description = vehicle.model,
                icon = 'eye',
                onSelect = function()
                    spawnPreview(vehicle.model)
                    openVehicleActions(vehicle)
                end,
            },
            {
                title = 'Retour',
                icon = 'arrow-left',
                onSelect = function()
                    openVehicleList(selectedCategory)
                end,
            },
        },
    })

    lib.showContext('qbx_concessionnaire_vehicle')
end

openVehicleList = function(categoryId, search)
    selectedCategory = categoryId
    local vehicles = getVehiclesByCategory(categoryId, search)
    local options = {}

    if #vehicles == 0 then
        options[#options + 1] = {
            title = Translate('no_vehicles'),
            icon = 'circle-xmark',
            disabled = true,
        }
    else
        for i = 1, #vehicles do
            local v = vehicles[i]
            options[#options + 1] = {
                title = v.name,
                description = ('%s — $%s'):format(getCategoryLabel(v.category), formatMoney(v.price)),
                icon = 'car',
                metadata = {
                    { label = 'Prix', value = ('$%s'):format(formatMoney(v.price)) },
                    { label = 'Modèle', value = v.model },
                },
                onSelect = function()
                    openVehicleActions(v)
                end,
            }
        end
    end

    lib.registerContext({
        id = 'qbx_concessionnaire_list',
        title = categoryId and getCategoryLabel(categoryId) or 'Résultats',
        menu = 'qbx_concessionnaire_main',
        onExit = closeShop,
        options = options,
    })

    lib.showContext('qbx_concessionnaire_list')

    if vehicles[1] then
        spawnPreview(vehicles[1].model)
    end
end

openCategoriesMenu = function()
    local options = {
        {
            title = 'Rechercher',
            description = Translate('search_placeholder'),
            icon = 'magnifying-glass',
            onSelect = function()
                local input = lib.inputDialog(Translate('shop_title'), {
                    {
                        type = 'input',
                        label = 'Recherche',
                        placeholder = Translate('search_placeholder'),
                        required = true,
                        min = 1,
                        max = 40,
                    },
                })
                if input and input[1] then
                    openVehicleList(nil, input[1])
                else
                    openCategoriesMenu()
                end
            end,
        },
    }

    for i = 1, #Config.Categories do
        local cat = Config.Categories[i]
        local count = #getVehiclesByCategory(cat.id)
        options[#options + 1] = {
            title = cat.label,
            description = ('%s véhicules'):format(count),
            icon = 'tags',
            arrow = true,
            onSelect = function()
                openVehicleList(cat.id)
            end,
        }
    end

    options[#options + 1] = {
        title = Translate('close'),
        icon = 'xmark',
        iconColor = '#ef4444',
        onSelect = function()
            closeShop()
        end,
    }

    lib.registerContext({
        id = 'qbx_concessionnaire_main',
        title = Translate('shop_title'),
        options = options,
        onExit = closeShop,
    })

    lib.showContext('qbx_concessionnaire_main')
end

local function openShop()
    if isOpen then return end
    if GetResourceState('ox_lib') ~= 'started' then
        notify('ox_lib est requis pour ce concessionnaire', 'error')
        return
    end

    isOpen = true
    DisplayRadar(false)
    createCamera()
    openCategoriesMenu()

    local first = Config.Vehicles[1]
    if first then
        spawnPreview(first.model)
    end
end

CreateThread(function()
    for i = 1, #Config.Zones do
        local zone = Config.Zones[i]
        if zone.blip and zone.blip.enabled then
            local blip = AddBlipForCoord(zone.coords.x, zone.coords.y, zone.coords.z)
            SetBlipSprite(blip, zone.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, zone.blip.scale)
            SetBlipColour(blip, zone.blip.colour)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(zone.blip.label or Translate('blip_label'))
            EndTextCommandSetBlipName(blip)
        end
    end
end)

CreateThread(function()
    local showingTextUI = false

    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local near = false

        if not isOpen then
            for i = 1, #Config.Zones do
                local zone = Config.Zones[i]
                local dist = #(coords - zone.coords)
                if dist < zone.drawDistance then
                    sleep = 0
                    local m = zone.marker
                    DrawMarker(
                        m.type,
                        zone.coords.x + 0.0, zone.coords.y + 0.0, zone.coords.z - 1.0,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        m.size.x + 0.0, m.size.y + 0.0, m.size.z + 0.0,
                        m.color.r, m.color.g, m.color.b, m.color.a,
                        m.bobUpAndDown == true, m.faceCamera == true, 2, m.rotate == true, nil, nil, false
                    )

                    if dist < zone.interactDistance then
                        near = true
                        currentZone = zone
                        if not showingTextUI then
                            lib.showTextUI(Translate('press_open'), {
                                position = 'right-center',
                                icon = 'car',
                            })
                            showingTextUI = true
                        end

                        if IsControlJustReleased(0, 38) then
                            lib.hideTextUI()
                            showingTextUI = false
                            openShop()
                        end
                    end
                end
            end
        else
            sleep = 200
        end

        if showingTextUI and not near then
            lib.hideTextUI()
            showingTextUI = false
        end

        Wait(sleep)
    end
end)

RegisterNetEvent('qbx_concessionnaire:client:spawnPurchased', function(data)
    if not data or not data.model then return end

    closeShop()
    Wait(100)

    local hash = joaat(data.model)
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(10)
    end
    if not HasModelLoaded(hash) then return end

    local c = data.coords
    local vehicle = CreateVehicle(hash, c.x + 0.0, c.y + 0.0, c.z + 0.0, data.heading or 0.0, true, false)
    SetVehicleNumberPlateText(vehicle, data.plate or '')
    SetVehicleOnGroundProperly(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehicleDoorsLocked(vehicle, 1)
    SetVehicleEngineOn(vehicle, false, true, false)
    SetModelAsNoLongerNeeded(hash)

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    TriggerEvent('qbx_concessionnaire:vehiclePurchased', vehicle, data.plate, data.model)
    TriggerServerEvent('qbx_concessionnaire:server:vehicleSpawned', data.plate, netId)
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

RegisterCommand('concessionnaire', function()
    openShop()
end, false)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if isOpen then
        lib.hideContext()
        lib.hideTextUI()
    end
    deletePreview()
    destroyCamera()
end)

exports('OpenDealership', openShop)
exports('CloseDealership', closeShop)
