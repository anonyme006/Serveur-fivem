--[[
    esx_dynasty — Client
    Panel entreprise + panel logements + portes / garage
]]

local isOpen = false
local openView = nil -- 'company' | 'housing'
local Properties = {}
local PropertyBlips = {}
local currentInside = nil -- { id, entrance, ipls }
local companyVehicle = nil
local textUIShown = false
local placingPoint = nil -- { type, draft, propertyId, resumeView }
local loadedIpls = {}

local function notify(msg, nType)
    if lib and lib.notify then
        lib.notify({
            title = 'Dynasty 8',
            description = msg,
            type = nType or 'inform',
        })
        return
    end
    if ESX and ESX.ShowNotification then
        ESX.ShowNotification(msg)
    end
end

RegisterNetEvent('esx_dynasty:notify', function(msg, nType)
    notify(msg, nType)
end)

local function hideTextUI()
    if textUIShown and lib and lib.hideTextUI then
        lib.hideTextUI()
        textUIShown = false
    end
end

local function showTextUI(text)
    if lib and lib.showTextUI then
        lib.showTextUI(text)
        textUIShown = true
    end
end

local function loadInteriorIpls(ipls)
    if type(ipls) == 'string' then ipls = { ipls } end
    if type(ipls) ~= 'table' then return {} end
    local loaded = {}
    for i = 1, #ipls do
        local name = ipls[i]
        if name and name ~= '' then
            RequestIpl(name)
            loaded[#loaded + 1] = name
        end
    end
    return loaded
end

local function unloadInteriorIpls(ipls)
    if type(ipls) ~= 'table' then return end
    for i = 1, #ipls do
        if ipls[i] then RemoveIpl(ipls[i]) end
    end
end

local function getPlayerPoint()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    return {
        x = coords.x + 0.0,
        y = coords.y + 0.0,
        z = coords.z + 0.0,
        h = heading + 0.0,
    }
end

local function closeUI()
    if not isOpen then return end
    isOpen = false
    openView = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    hideTextUI()
end

local function openUI(view, extra)
    if isOpen then return end
    local cbName = view == 'housing' and 'esx_dynasty:getHousingData' or 'esx_dynasty:getCompanyData'

    ESX.TriggerServerCallback(cbName, function(data)
        if not data then
            notify(Translate('not_employee'), 'error')
            return
        end

        isOpen = true
        openView = view
        SetNuiFocus(true, true)

        local pos = getPlayerPoint()
        local payload = {
            action = 'open',
            view = view,
            data = data,
            locale = Locales[Config.Locale] or Locales['fr'],
            currency = Config.Currency,
            playerPos = pos,
            statuses = Config.Statuses,
        }
        if extra then
            for k, v in pairs(extra) do
                payload[k] = v
            end
        end
        SendNUIMessage(payload)
    end)
end

local function resumeAfterPlacement(point, cancelled)
    local ctx = placingPoint
    placingPoint = nil
    hideTextUI()

    if cancelled or not ctx then
        if ctx and ctx.resumeView then
            openUI(ctx.resumeView or 'housing', {
                resumeDraft = ctx.draft,
                resumePropertyId = ctx.propertyId,
                placedPoint = nil,
                placedPointType = ctx.type,
                placementCancelled = true,
            })
        end
        return
    end

    -- Mise à jour immédiate d'un bien existant
    if ctx.propertyId and not cancelled then
        local payload = { id = ctx.propertyId }
        if ctx.type == 'entrance' then
            payload.entrance = point
        elseif ctx.type == 'garage' then
            payload.garage = point
        elseif ctx.type == 'clear_garage' then
            payload.clear_garage = true
        end

        ESX.TriggerServerCallback('esx_dynasty:updatePoints', function(result)
            if result and result.ok then
                notify(result.message or Translate('points_updated'), 'success')
            elseif result and result.error then
                notify(result.error, 'error')
            end
            openUI('housing', {
                resumeDraft = ctx.draft,
                resumePropertyId = ctx.propertyId,
                placedPoint = point,
                placedPointType = ctx.type,
            })
        end, payload)
        return
    end

    -- Reprise du formulaire création / édition
    openUI(ctx.resumeView or 'housing', {
        resumeDraft = ctx.draft,
        resumePropertyId = ctx.propertyId,
        placedPoint = point,
        placedPointType = ctx.type,
    })
end

local function startPointPlacement(pointType, draft, propertyId)
    if placingPoint then return end

    closeUI()
    Wait(150)

    placingPoint = {
        type = pointType,
        draft = draft,
        propertyId = propertyId,
        resumeView = 'housing',
        startedAt = GetGameTimer(),
    }

    local label = pointType == 'garage'
        and Translate('place_garage_help')
        or Translate('place_entrance_help')
    showTextUI(label)
    notify(label, 'inform')
end

CreateThread(function()
    while true do
        if placingPoint then
            Wait(0)
            local cfg = Config.PointPlacement or {}
            local timeout = cfg.timeoutMs or 120000
            local helpKey = cfg.helpKey or 38
            local cancelKey = cfg.cancelKey or 177

            showTextUI(
                placingPoint.type == 'garage'
                    and Translate('place_garage_help')
                    or Translate('place_entrance_help')
            )

            if (GetGameTimer() - placingPoint.startedAt) > timeout then
                notify(Translate('place_cancelled'), 'error')
                resumeAfterPlacement(nil, true)
            elseif IsControlJustReleased(0, cancelKey) then
                notify(Translate('place_cancelled'), 'inform')
                resumeAfterPlacement(nil, true)
            elseif IsControlJustReleased(0, helpKey) then
                local point = getPlayerPoint()
                notify(Translate('place_saved'), 'success')
                resumeAfterPlacement(point, false)
            end
        else
            Wait(400)
        end
    end
end)

local function isDynasty()
    local data = ESX.GetPlayerData()
    return data and data.job and data.job.name == Config.JobName
end

-- ─── Property blips ──────────────────────────────────────────

local function clearPropertyBlips()
    for id, blip in pairs(PropertyBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
        PropertyBlips[id] = nil
    end
end

local function refreshPropertyBlips()
    clearPropertyBlips()
    if not Config.ShowPropertyBlips or not isDynasty() then return end

    for id, prop in pairs(Properties) do
        local style = Config.PropertyBlip.free
        if prop.status == 'vente' then
            style = Config.PropertyBlip.sale
        elseif prop.status == 'location' then
            style = Config.PropertyBlip.rent
        elseif prop.status == 'occupe' or prop.owner then
            style = Config.PropertyBlip.owned
        end

        local blip = AddBlipForCoord(prop.entrance.x, prop.entrance.y, prop.entrance.z)
        SetBlipSprite(blip, style.sprite)
        SetBlipColour(blip, style.colour)
        SetBlipScale(blip, 0.55)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(prop.label or 'Logement')
        EndTextCommandSetBlipName(blip)
        PropertyBlips[id] = blip
    end
end

RegisterNetEvent('esx_dynasty:syncProperties', function(list)
    Properties = list or {}
    refreshPropertyBlips()
end)

RegisterNetEvent('esx:playerLoaded', function()
    Wait(1500)
    refreshPropertyBlips()
end)

RegisterNetEvent('esx:setJob', function()
    Wait(200)
    refreshPropertyBlips()
end)

-- ─── Enter / Exit housing ────────────────────────────────────

local function enterProperty(id)
    ESX.TriggerServerCallback('esx_dynasty:canEnter', function(result)
        if not result then return end
        if result.mlo then
            notify('Ce bien est un MLO — utilisez la porte locale.', 'inform')
            return
        end
        if not result.ok then
            notify(result.error or Translate('enter_denied'), 'error')
            return
        end

        local prop = Properties[id]
        local interior = result.interior
        if not interior or not interior.entry then
            notify(Translate('enter_denied'), 'error')
            return
        end

        local ped = PlayerPedId()

        DoScreenFadeOut(400)
        while not IsScreenFadedOut() do Wait(0) end

        local ipls = loadInteriorIpls(interior.ipl)
        loadedIpls = ipls
        Wait(100)

        TriggerServerEvent('esx_dynasty:setBucket', result.bucket)
        SetEntityCoords(ped, interior.entry.x, interior.entry.y, interior.entry.z, false, false, false, false)
        SetEntityHeading(ped, interior.heading or 0.0)

        currentInside = {
            id = id,
            entrance = prop.entrance,
            exit = {
                x = interior.entry.x,
                y = interior.entry.y,
                z = interior.entry.z,
            },
            ipls = ipls,
        }

        Wait(300)
        DoScreenFadeIn(400)
    end, id)
end

local function exitProperty()
    if not currentInside then return end
    local ped = PlayerPedId()
    local entrance = currentInside.entrance

    DoScreenFadeOut(400)
    while not IsScreenFadedOut() do Wait(0) end

    unloadInteriorIpls(currentInside.ipls or loadedIpls)
    loadedIpls = {}

    TriggerServerEvent('esx_dynasty:setBucket', 0)
    SetEntityCoords(ped, entrance.x, entrance.y, entrance.z, false, false, false, false)
    SetEntityHeading(ped, entrance.h or 0.0)
    currentInside = nil

    Wait(300)
    DoScreenFadeIn(400)
end

-- ─── NUI Callbacks ───────────────────────────────────────────

RegisterNUICallback('close', function(_, cb)
    closeUI()
    cb('ok')
end)

RegisterNUICallback('getPlayerPos', function(_, cb)
    cb(getPlayerPoint())
end)

RegisterNUICallback('placePoint', function(data, cb)
    local pointType = data and data.type or 'entrance'
    if pointType ~= 'entrance' and pointType ~= 'garage' then
        cb({ ok = false })
        return
    end
    cb({ ok = true })
    CreateThread(function()
        Wait(50)
        startPointPlacement(pointType, data and data.draft or nil, tonumber(data and data.propertyId))
    end)
end)

RegisterNUICallback('updatePoints', function(data, cb)
    ESX.TriggerServerCallback('esx_dynasty:updatePoints', function(result)
        cb(result or { ok = false })
        if result and result.ok then
            notify(result.message or Translate('points_updated'), 'success')
        elseif result and result.error then
            notify(result.error, 'error')
        end
    end, data)
end)

RegisterNUICallback('previewInterior', function(data, cb)
    -- Info only: interiors are applied on enter
    cb({ ok = true, id = data and data.id })
end)

RegisterNUICallback('switchView', function(data, cb)
    local view = data and data.view or 'company'
    openView = view
    ESX.TriggerServerCallback('esx_dynasty:refresh', function(payload)
        cb(payload or {})
    end)
end)

RegisterNUICallback('refresh', function(_, cb)
    ESX.TriggerServerCallback('esx_dynasty:refresh', function(payload)
        cb(payload or {})
    end)
end)

RegisterNUICallback('createProperty', function(data, cb)
    ESX.TriggerServerCallback('esx_dynasty:createProperty', function(result)
        cb(result or { ok = false })
        if result and result.ok then
            notify(result.message or Translate('property_created'), 'success')
        elseif result and result.error then
            notify(result.error, 'error')
        end
    end, data)
end)

RegisterNUICallback('updateProperty', function(data, cb)
    ESX.TriggerServerCallback('esx_dynasty:updateProperty', function(result)
        cb(result or { ok = false })
        if result and result.ok then
            notify(result.message or Translate('property_updated'), 'success')
        elseif result and result.error then
            notify(result.error, 'error')
        end
    end, data)
end)

RegisterNUICallback('deleteProperty', function(data, cb)
    ESX.TriggerServerCallback('esx_dynasty:deleteProperty', function(result)
        cb(result or { ok = false })
        if result and result.ok then
            notify(result.message or Translate('property_deleted'), 'success')
        elseif result and result.error then
            notify(result.error, 'error')
        end
    end, data)
end)

RegisterNUICallback('sellProperty', function(data, cb)
    ESX.TriggerServerCallback('esx_dynasty:sellProperty', function(result)
        cb(result or { ok = false })
        if result and result.ok then
            notify(result.message or Translate('property_sold', ''), 'success')
        elseif result and result.error then
            notify(result.error, 'error')
        end
    end, data)
end)

RegisterNUICallback('rentProperty', function(data, cb)
    ESX.TriggerServerCallback('esx_dynasty:rentProperty', function(result)
        cb(result or { ok = false })
        if result and result.ok then
            notify(result.message or Translate('property_rented', ''), 'success')
        elseif result and result.error then
            notify(result.error, 'error')
        end
    end, data)
end)

RegisterNUICallback('revokeProperty', function(data, cb)
    ESX.TriggerServerCallback('esx_dynasty:revokeProperty', function(result)
        cb(result or { ok = false })
        if result and result.ok then
            notify(result.message or Translate('property_revoked'), 'success')
        elseif result and result.error then
            notify(result.error, 'error')
        end
    end, data)
end)

RegisterNUICallback('giveKeys', function(data, cb)
    ESX.TriggerServerCallback('esx_dynasty:giveKeys', function(result)
        cb(result or { ok = false })
        if result and result.ok then
            notify(result.message or Translate('keys_given'), 'success')
        elseif result and result.error then
            notify(result.error, 'error')
        end
    end, data)
end)

RegisterNUICallback('removeKeys', function(data, cb)
    ESX.TriggerServerCallback('esx_dynasty:removeKeys', function(result)
        cb(result or { ok = false })
    end, data)
end)

RegisterNUICallback('toggleLock', function(data, cb)
    ESX.TriggerServerCallback('esx_dynasty:toggleLock', function(result)
        cb(result or { ok = false })
    end, data)
end)

RegisterNUICallback('postNews', function(data, cb)
    ESX.TriggerServerCallback('esx_dynasty:postNews', function(result)
        cb(result or { ok = false })
        if result and result.ok then
            notify(result.message or Translate('news_posted'), 'success')
        elseif result and result.error then
            notify(result.error, 'error')
        end
    end, data)
end)

RegisterNUICallback('saveBillboard', function(data, cb)
    ESX.TriggerServerCallback('esx_dynasty:saveBillboard', function(result)
        cb(result or { ok = false })
        if result and result.ok then
            notify(result.message or Translate('billboard_saved'), 'success')
        elseif result and result.error then
            notify(result.error, 'error')
        end
    end, data)
end)

RegisterNUICallback('hireNearby', function(_, cb)
    ESX.TriggerServerCallback('esx_dynasty:hireNearby', function(result)
        cb(result or { ok = false })
        if result and result.ok then
            notify(result.message or Translate('employee_hired'), 'success')
        elseif result and result.error then
            notify(result.error, 'error')
        end
    end)
end)

RegisterNUICallback('setEmployeeGrade', function(data, cb)
    ESX.TriggerServerCallback('esx_dynasty:setEmployeeGrade', function(result)
        cb(result or { ok = false })
        if result and result.ok then
            notify(result.message or Translate('grade_updated'), 'success')
        elseif result and result.error then
            notify(result.error, 'error')
        end
    end, data)
end)

RegisterNUICallback('fireEmployee', function(data, cb)
    ESX.TriggerServerCallback('esx_dynasty:fireEmployee', function(result)
        cb(result or { ok = false })
        if result and result.ok then
            notify(result.message or Translate('employee_fired'), 'success')
        elseif result and result.error then
            notify(result.error, 'error')
        end
    end, data)
end)

RegisterNUICallback('spawnVehicle', function(data, cb)
    local model = data and data.model
    if not model then
        cb({ ok = false })
        return
    end

    ESX.TriggerServerCallback('esx_dynasty:canSpawnVehicle', function(result)
        if not result or not result.ok then
            notify((result and result.error) or Translate('no_permission'), 'error')
            cb(result or { ok = false })
            return
        end

        if companyVehicle and DoesEntityExist(companyVehicle) then
            DeleteEntity(companyVehicle)
            companyVehicle = nil
        end

        local spawn = Config.Garage.spawn
        local hash = joaat(model)
        RequestModel(hash)
        local timeout = GetGameTimer() + 5000
        while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(10) end

        if not HasModelLoaded(hash) then
            cb({ ok = false, error = 'Model load failed' })
            return
        end

        companyVehicle = CreateVehicle(hash, spawn.coords.x, spawn.coords.y, spawn.coords.z, spawn.heading, true, false)
        SetVehicleOnGroundProperly(companyVehicle)
        SetVehicleNumberPlateText(companyVehicle, 'DYNASTY')
        SetEntityAsMissionEntity(companyVehicle, true, true)
        TaskWarpPedIntoVehicle(PlayerPedId(), companyVehicle, -1)
        SetModelAsNoLongerNeeded(hash)

        notify(Translate('vehicle_spawned'), 'success')
        closeUI()
        cb({ ok = true })
    end, model)
end)

RegisterNUICallback('storeVehicle', function(_, cb)
    if companyVehicle and DoesEntityExist(companyVehicle) then
        DeleteEntity(companyVehicle)
        companyVehicle = nil
        notify(Translate('vehicle_stored'), 'success')
        cb({ ok = true })
        return
    end

    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        local plate = GetVehicleNumberPlateText(veh)
        if plate and plate:find('DYNASTY') then
            DeleteEntity(veh)
            notify(Translate('vehicle_stored'), 'success')
            cb({ ok = true })
            return
        end
    end
    cb({ ok = false })
end)

-- ─── Commands ────────────────────────────────────────────────

RegisterCommand(Config.Commands.openPanel, function()
    if not isDynasty() then
        notify(Translate('not_employee'), 'error')
        return
    end
    openUI('company')
end, false)

RegisterCommand(Config.Commands.openHousing, function()
    if not isDynasty() then
        notify(Translate('not_employee'), 'error')
        return
    end
    openUI('housing')
end, false)

RegisterCommand(Config.Commands.giveKeys, function(_, args)
    local id = tonumber(args[1])
    if not id then return end
    ESX.TriggerServerCallback('esx_dynasty:giveKeys', function(result)
        if result and result.ok then
            notify(result.message or Translate('keys_given'), 'success')
        elseif result and result.error then
            notify(result.error, 'error')
        end
    end, { id = id })
end, false)

if Config.CloseWithEscape then
    RegisterNUICallback('escape', function(_, cb)
        closeUI()
        cb('ok')
    end)
end

-- ─── Office blip ─────────────────────────────────────────────

CreateThread(function()
    local office = Config.Office
    if office.blip and office.blip.enabled then
        local blip = AddBlipForCoord(office.coords.x, office.coords.y, office.coords.z)
        SetBlipSprite(blip, office.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, office.blip.scale or 0.85)
        SetBlipColour(blip, office.blip.colour)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(office.blip.label or 'Dynasty 8')
        EndTextCommandSetBlipName(blip)
    end
end)

-- ─── Interaction loop ────────────────────────────────────────

local function drawMarkerAt(coords, marker)
    DrawMarker(
        marker.type,
        coords.x, coords.y, coords.z - 1.0,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        marker.size.x, marker.size.y, marker.size.z,
        marker.color.r, marker.color.g, marker.color.b, marker.color.a,
        false, false, 2, false, nil, nil, false
    )
end

CreateThread(function()
    while true do
        if placingPoint then
            Wait(400)
            goto continue
        end

        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local showing = false

        if currentInside then
            sleep = 0
            local exitPos = currentInside.exit
            local dist = #(coords - vector3(exitPos.x, exitPos.y, exitPos.z))
            if dist < 15.0 then
                DrawMarker(1, exitPos.x, exitPos.y, exitPos.z - 1.0, 0, 0, 0, 0, 0, 0, 1.2, 1.2, 0.4, 80, 160, 255, 140, false, false, 2, false, nil, nil, false)
                if dist < 1.8 then
                    showTextUI(Translate('interact_exit'))
                    showing = true
                    if IsControlJustReleased(0, 38) then
                        exitProperty()
                    end
                end
            end
        else
            -- Office
            local office = Config.Office
            local odist = #(coords - office.coords)
            if odist < office.drawDistance then
                sleep = 0
                drawMarkerAt(office.coords, office.marker)
                if odist < office.interactDistance and isDynasty() then
                    showTextUI(Translate('interact_office'))
                    showing = true
                    if IsControlJustReleased(0, 38) then
                        openUI('company')
                    end
                end
            end

            -- Garage store
            local gdist = #(coords - Config.Garage.coords)
            if gdist < 12.0 and isDynasty() then
                sleep = 0
                if gdist < 2.5 then
                    showTextUI('[E] ' .. Translate('store_vehicle'))
                    showing = true
                    if IsControlJustReleased(0, 38) then
                        if companyVehicle and DoesEntityExist(companyVehicle) then
                            DeleteEntity(companyVehicle)
                            companyVehicle = nil
                            notify(Translate('vehicle_stored'), 'success')
                        else
                            local veh = GetVehiclePedIsIn(ped, false)
                            if veh ~= 0 then
                                DeleteEntity(veh)
                                notify(Translate('vehicle_stored'), 'success')
                            end
                        end
                    end
                end
            end

            -- Property doors
            for id, prop in pairs(Properties) do
                local pcoords = vector3(prop.entrance.x, prop.entrance.y, prop.entrance.z)
                local dist = #(coords - pcoords)
                if dist < 25.0 then
                    sleep = 0
                    DrawMarker(20, pcoords.x, pcoords.y, pcoords.z + 0.15, 0, 0, 0, 0, 0, 0, 0.35, 0.35, 0.35, 70, 180, 120, 160, false, true, 2, false, nil, nil, false)
                    if dist < 1.6 then
                        showTextUI(Translate('interact_door', prop.label))
                        showing = true
                        if IsControlJustReleased(0, 38) then
                            enterProperty(id)
                        elseif IsControlJustReleased(0, 47) then -- G lock toggle
                            ESX.TriggerServerCallback('esx_dynasty:toggleLock', function(result)
                                if result and result.ok then
                                    notify(result.locked and Translate('locked') or Translate('unlocked'), 'inform')
                                elseif result and result.error then
                                    notify(result.error, 'error')
                                end
                            end, { id = id })
                        end
                    end
                end
            end
        end

        if not showing then
            hideTextUI()
        end

        Wait(sleep)
        ::continue::
    end
end)

-- ESC safety
CreateThread(function()
    while true do
        if isOpen then
            Wait(0)
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            if IsControlJustReleased(0, 322) then -- ESC
                closeUI()
            end
        else
            Wait(400)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if currentInside then
        unloadInteriorIpls(currentInside.ipls or loadedIpls)
        TriggerServerEvent('esx_dynasty:setBucket', 0)
    end
    clearPropertyBlips()
    closeUI()
end)
