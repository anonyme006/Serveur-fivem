local isOpen = false
local previewVehicle = nil
local previewCam = nil
local currentZone = nil
local nearbyZone = nil

local function notify(msg)
    if ESX and ESX.ShowNotification then
        ESX.ShowNotification(msg)
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(msg)
        EndTextCommandThefeedPostTicker(false, true)
    end
end

--- Safe interact prompt (avoids EndTextCommandDisplayHelp crash on build 3570+)
local function showHelp(msg)
    SetTextFont(4)
    SetTextScale(0.42, 0.42)
    SetTextColour(255, 255, 255, 230)
    SetTextCentre(true)
    SetTextDropshadow(1, 0, 0, 0, 200)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayText(0.5, 0.90)
end

local function formatMoney(amount)
    local n = tonumber(amount) or 0
    if ESX and ESX.Math and ESX.Math.GroupDigits then
        return ESX.Math.GroupDigits(n)
    end
    local s = tostring(math.floor(n))
    local left, num, right = string.match(s, '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

local function deletePreview()
    if previewVehicle and DoesEntityExist(previewVehicle) then
        SetEntityAsMissionEntity(previewVehicle, true, true)
        DeleteVehicle(previewVehicle)
    end
    previewVehicle = nil
end

local function destroyCamera()
    if previewCam then
        RenderScriptCams(false, true, 400, true, true)
        DestroyCam(previewCam, false)
        previewCam = nil
    end
end

local function createCamera()
    destroyCamera()
    local cam = Config.Preview.camera
    previewCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(previewCam, cam.coords.x, cam.coords.y, cam.coords.z)
    PointCamAtCoord(previewCam, cam.pointAt.x, cam.pointAt.y, cam.pointAt.z)
    SetCamFov(previewCam, cam.fov or 45.0)
    SetCamActive(previewCam, true)
    RenderScriptCams(true, true, 500, true, true)
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
    previewVehicle = CreateVehicle(hash, c.x, c.y, c.z, Config.Preview.heading, false, false)
    SetVehicleOnGroundProperly(previewVehicle)
    SetEntityInvincible(previewVehicle, true)
    SetVehicleDoorsLocked(previewVehicle, 2)
    FreezeEntityPosition(previewVehicle, true)
    SetVehicleNumberPlateText(previewVehicle, 'PREVIEW')
    SetModelAsNoLongerNeeded(hash)
end

local function setNuiFocus(state)
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(false)
end

local function closeShop()
    if not isOpen then return end
    isOpen = false
    setNuiFocus(false)
    SendNUIMessage({ action = 'close' })
    deletePreview()
    destroyCamera()
    DisplayRadar(true)
end

local function openShop()
    if isOpen then return end
    isOpen = true
    DisplayRadar(false)
    createCamera()

    local categoryLabels = {}
    for _, cat in ipairs(Config.Categories) do
        categoryLabels[cat.id] = cat.label
    end

    local vehicles = {}
    for _, v in ipairs(Config.Vehicles) do
        vehicles[#vehicles + 1] = {
            model = v.model,
            name = v.name,
            category = v.category,
            categoryLabel = categoryLabels[v.category] or v.category,
            price = v.price,
        }
    end

    setNuiFocus(true)
    SendNUIMessage({
        action = 'open',
        categories = Config.Categories,
        vehicles = vehicles,
        locale = {
            title = Translate('shop_title'),
            search = Translate('search_placeholder'),
            buy = Translate('buy'),
            cancel = Translate('cancel'),
            confirm = Translate('confirm_buy'),
            empty = Translate('no_vehicles'),
            close = Translate('close'),
        },
    })

    if #vehicles > 0 then
        spawnPreview(vehicles[1].model)
    end
end

-- Blips
CreateThread(function()
    for _, zone in ipairs(Config.Zones) do
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

-- Markers / interaction
CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        nearbyZone = nil

        if not isOpen then
            for _, zone in ipairs(Config.Zones) do
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
                        nearbyZone = zone
                        showHelp(Translate('press_open'))

                        if IsControlJustReleased(0, 38) then -- E
                            currentZone = zone
                            openShop()
                        end
                    end
                end
            end
        else
            sleep = 200
        end

        Wait(sleep)
    end
end)

-- Disable controls while NUI open
CreateThread(function()
    while true do
        if isOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 257, true)
            DisableControlAction(0, 263, true)
            DisableControlAction(0, 264, true)
            DisableControlAction(0, 30, true)
            DisableControlAction(0, 31, true)
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 23, true)
            DisableControlAction(0, 75, true)
            Wait(0)
        else
            Wait(400)
        end
    end
end)

RegisterNUICallback('close', function(_, cb)
    closeShop()
    cb('ok')
end)

RegisterNUICallback('preview', function(data, cb)
    if data and data.model then
        spawnPreview(data.model)
    end
    cb('ok')
end)

RegisterNUICallback('buy', function(data, cb)
    if not data or not data.model then
        cb({ ok = false })
        return
    end

    ESX.TriggerServerCallback('esx_concessionnaire:buyVehicle', function(result)
        if result and result.ok then
            closeShop()
            notify(Translate('purchase_success', result.name, formatMoney(result.price)))
            notify(Translate('vehicle_out'))
        else
            local reason = result and result.reason or 'purchase_failed'
            if reason == 'money' then
                notify(Translate('not_enough_money'))
            else
                notify(Translate(reason) ~= reason and Translate(reason) or Translate('purchase_failed'))
            end
        end
        cb(result or { ok = false })
    end, data.model)
end)

-- Commande admin / test
RegisterNetEvent('esx_concessionnaire:spawnPurchased', function(data)
    if not data or not data.model then return end

    local hash = joaat(data.model)
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(10)
    end
    if not HasModelLoaded(hash) then return end

    local c = data.coords
    local vehicle = CreateVehicle(hash, c.x, c.y, c.z, data.heading or 0.0, true, false)
    SetVehicleNumberPlateText(vehicle, data.plate or '')
    SetVehicleOnGroundProperly(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetModelAsNoLongerNeeded(hash)

    local ped = PlayerPedId()
    TaskWarpPedIntoVehicle(ped, vehicle, -1)

    TriggerEvent('esx_concessionnaire:vehiclePurchased', vehicle, data.plate, data.model)
end)

RegisterCommand('concessionnaire', function()
    openShop()
end, false)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if isOpen then
        setNuiFocus(false)
    end
    deletePreview()
    destroyCamera()
end)

exports('OpenDealership', openShop)
exports('CloseDealership', closeShop)
