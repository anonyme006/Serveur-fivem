--[[--------------------------------------------------------------------------
    core_garage — zones, blips, markers, ox_target garage
---------------------------------------------------------------------------]]

local markerThread = false

local function removeBlips()
    for _, blip in pairs(CoreGarage.blips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    CoreGarage.blips = {}
end

local function removeZones()
    for name, zoneId in pairs(CoreGarage.zones) do
        pcall(function()
            exports.ox_target:removeZone(zoneId)
        end)
    end
    CoreGarage.zones = {}
end

local function createBlip(garage)
    local blipCfg = garage.blip
    if type(blipCfg) ~= 'table' then blipCfg = {} end
    if blipCfg.enabled == false then return end

    local defaults = Config.DefaultBlips[garage.type] or Config.DefaultBlips.public
    local sprite = blipCfg.sprite or defaults.sprite
    local color = blipCfg.color or defaults.color
    local scale = blipCfg.scale or defaults.scale
    local coords = GarageUtils.ToVec3(garage.coords)
    if not coords then return end

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipDisplay(blip, blipCfg.display or defaults.display or 4)
    SetBlipScale(blip, scale)
    SetBlipColour(blip, color)
    SetBlipAsShortRange(blip, blipCfg.shortRange ~= false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(garage.label or _('garage'))
    EndTextCommandSetBlipName(blip)
    CoreGarage.blips[garage.name] = blip
end

local function openGarage(name)
    local garage = CoreGarage.GetGarage(name)
    if not garage then return end
    if not CoreGarage.CanAccess(garage) then
        CoreGarage.Notify(_('no_permission'), 'error')
        return
    end

    local result = lib.callback.await('core_garage:openGarage', false, name)
    if not result or not result.ok then
        CoreGarage.Notify(_(result and result.error or 'error'), 'error')
        return
    end

    CoreGarage.currentGarage = name
    CoreGarage.OpenNui(result.data)
end

local function createTargetZone(garage)
    local coords = GarageUtils.ToVec3(garage.coords)
    if not coords then return end

    local marker = garage.marker or {}
    local radius = (marker.interactDistance or Config.DefaultMarkers.interactDistance or 2.0)

    local zoneId = exports.ox_target:addSphereZone({
        coords = coords,
        radius = radius,
        debug = Config.Debug,
        options = {
            {
                name = 'core_garage_open_' .. garage.name,
                icon = garage.type == 'impound' and 'fa-solid fa-warehouse' or 'fa-solid fa-car',
                label = garage.type == 'impound' and _('impound') or (garage.label or _('garage')),
                distance = radius + 0.5,
                canInteract = function()
                    return CoreGarage.CanAccess(garage)
                end,
                onSelect = function()
                    openGarage(garage.name)
                end,
            },
        },
    })
    CoreGarage.zones[garage.name] = zoneId
end

function CoreGarage.Rebuild(list)
    removeZones()
    removeBlips()
    CoreGarage.garages = {}

    for _, g in ipairs(list) do
        -- Normalise champs SQL / push
        local garage = {
            id = g.id,
            name = g.name,
            label = g.label,
            type = g.type,
            coords = g.coords,
            spawn = g.spawn,
            heading = g.heading,
            store = g.store,
            blip = g.blip,
            marker = g.marker,
            job = g.job,
            gang = g.gang,
            minGrade = g.minGrade or g.min_grade or 0,
            vehicleType = g.vehicleType or g.vehicle_type or 'car',
            impoundPrice = g.impoundPrice or g.impound_price,
            impoundTime = g.impoundTime or g.impound_time,
            enabled = g.enabled ~= false and g.enabled ~= 0,
        }
        CoreGarage.garages[garage.name] = garage

        if garage.enabled then
            createBlip(garage)
            createTargetZone(garage)
        end
    end

    if not markerThread then
        markerThread = true
        CreateThread(function()
            while true do
                local sleep = 1000
                local ped = PlayerPedId()
                local pcoords = GetEntityCoords(ped)

                for _, garage in pairs(CoreGarage.garages) do
                    if garage.enabled then
                        local marker = garage.marker
                        if type(marker) ~= 'table' then marker = {} end
                        if marker.enabled ~= false then
                            local coords = GarageUtils.ToVec3(garage.coords)
                            if coords then
                                local dist = #(pcoords - coords)
                                local drawDist = marker.drawDistance or Config.DefaultMarkers.drawDistance
                                if dist < drawDist then
                                    sleep = 0
                                    if CoreGarage.CanAccess(garage) then
                                        local size = marker.size or Config.DefaultMarkers.size
                                        local color = marker.color or Config.DefaultMarkers.color
                                        local mType = marker.type or Config.DefaultMarkers.type
                                        DrawMarker(
                                            mType,
                                            coords.x, coords.y, coords.z + 0.15,
                                            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                                            size.x, size.y, size.z,
                                            color.r, color.g, color.b, color.a,
                                            marker.bobUpAndDown or false,
                                            marker.faceCamera ~= false,
                                            2,
                                            marker.rotate ~= false,
                                            nil, nil, false
                                        )
                                    end
                                end
                            end
                        end
                    end
                end
                Wait(sleep)
            end
        end)
    end
end

--- Trouve le garage de rangement le plus proche accessible
function CoreGarage.GetNearestStoreGarage(vehicleType)
    local ped = PlayerPedId()
    local pcoords = GetEntityCoords(ped)
    local nearest, nearestDist

    for _, garage in pairs(CoreGarage.garages) do
        if garage.enabled and garage.type ~= 'impound' and CoreGarage.CanAccess(garage) then
            local store = GarageUtils.ToVec3(garage.store or garage.coords)
            if store then
                local dist = #(pcoords - store)
                local maxDist = Config.General.maxDistance + 10.0
                if dist < maxDist and (not nearestDist or dist < nearestDist) then
                    -- Type check soft
                    local gType = garage.vehicleType or 'car'
                    if not vehicleType or vehicleType == gType or garage.type == 'public' or garage.type == 'personal' or garage.type == 'company' or garage.type == 'job' then
                        nearest = garage
                        nearestDist = dist
                    end
                end
            end
        end
    end
    return nearest, nearestDist
end

exports('OpenGarage', openGarage)
exports('GetGarages', function() return CoreGarage.garages end)
