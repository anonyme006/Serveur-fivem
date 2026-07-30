ClientCore = ClientCore or {}
ClientCore.Cache = ClientCore.Cache or {}
ClientCore.Entities = ClientCore.Entities or { peds = {}, blips = {}, zones = {} }
ClientCore.UiOpen = false

local callbackId = 0
local pending = {}

function ClientCore.Callback(name, payload, cb)
    if CoreUtils.ResourceStarted('ox_lib') and lib and lib.callback then
        lib.callback(name, false, function(result)
            if cb then cb(result) end
        end, payload)
        return
    end

    callbackId = callbackId + 1
    local id = callbackId
    pending[id] = cb
    TriggerServerEvent(name .. ':request', id, payload)
end

local CALLBACKS = {
    'core_creator:getBootstrap',
    'core_creator:list',
    'core_creator:get',
    'core_creator:create',
    'core_creator:update',
    'core_creator:delete',
    'core_creator:toggle',
    'core_creator:duplicate',
    'core_creator:exportOne',
    'core_creator:importOne',
}

for i = 1, #CALLBACKS do
    RegisterNetEvent(CALLBACKS[i] .. ':response', function(requestId, result)
        local cb = pending[requestId]
        if cb then pending[requestId] = nil cb(result) end
    end)
end

RegisterNetEvent('core_creator:notify', function(message, nType, duration)
    Bridge.Notify(message, nType, duration)
end)

function ClientCore.ClearEntities(kind)
    if kind == 'peds' or not kind then
        for _, ped in pairs(ClientCore.Entities.peds) do
            if DoesEntityExist(ped) then
                DeleteEntity(ped)
            end
        end
        ClientCore.Entities.peds = {}
    end
    if kind == 'blips' or not kind then
        for _, blip in pairs(ClientCore.Entities.blips) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end
        ClientCore.Entities.blips = {}
    end
end

function ClientCore.SpawnPed(key, model, coords, heading, scenario)
    if ClientCore.Entities.peds[key] and DoesEntityExist(ClientCore.Entities.peds[key]) then
        DeleteEntity(ClientCore.Entities.peds[key])
    end
    local hash = joaat(model or Config.Defaults.ped.model)
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(10) end
    if not HasModelLoaded(hash) then return nil end

    local ped = CreatePed(0, hash, coords.x, coords.y, coords.z - 1.0, heading or 0.0, false, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    if scenario and scenario ~= '' then
        TaskStartScenarioInPlace(ped, scenario, 0, true)
    end
    SetModelAsNoLongerNeeded(hash)
    ClientCore.Entities.peds[key] = ped
    return ped
end

function ClientCore.CreateBlip(key, coords, data, label)
    if ClientCore.Entities.blips[key] and DoesBlipExist(ClientCore.Entities.blips[key]) then
        RemoveBlip(ClientCore.Entities.blips[key])
    end
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, tonumber(data.sprite) or Config.Defaults.blip.sprite)
    SetBlipDisplay(blip, tonumber(data.display) or Config.Defaults.blip.display)
    SetBlipScale(blip, tonumber(data.scale) or Config.Defaults.blip.scale)
    SetBlipColour(blip, tonumber(data.colour) or Config.Defaults.blip.colour)
    SetBlipAsShortRange(blip, data.shortRange ~= false)
    if data.rotation then SetBlipRotation(blip, tonumber(data.rotation) or 0) end
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(label or data.label or 'Blip')
    EndTextCommandSetBlipName(blip)
    ClientCore.Entities.blips[key] = blip
    return blip
end

function ClientCore.DrawMarkerAt(coords, marker)
    marker = marker or Config.Defaults.marker
    DrawMarker(
        marker.type or 1,
        coords.x, coords.y, coords.z - 1.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        (marker.size and marker.size.x) or 1.0,
        (marker.size and marker.size.y) or 1.0,
        (marker.size and marker.size.z) or 0.6,
        (marker.color and marker.color.r) or 66,
        (marker.color and marker.color.g) or 135,
        (marker.color and marker.color.b) or 245,
        (marker.color and marker.color.a) or 140,
        marker.bobUpAndDown or false,
        marker.faceCamera or false,
        2,
        marker.rotate or false,
        nil, nil, false
    )
end

function ClientCore.HelpNotify(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

RegisterCommand(Config.Commands.open, function()
    TriggerEvent('core_creator:client:open')
end, false)

RegisterCommand(Config.Commands.teleport, function(_, args)
    local id = tonumber(args[1])
    local moduleName = args[2] or 'shops'
    if not id then return end
    ClientCore.Callback('core_creator:get', { module = moduleName, id = id }, function(result)
        if not result or not result.ok or not result.data or not result.data.coords then
            Bridge.Notify('Introuvable', 'error')
            return
        end
        local c = result.data.coords
        local ped = PlayerPedId()
        SetEntityCoords(ped, c.x, c.y, c.z, false, false, false, false)
        if c.w then SetEntityHeading(ped, c.w + 0.0) end
    end)
end, false)

AddEventHandler('onResourceStop', function(res)
    if res ~= CoreUtils.ResourceName() then return end
    ClientCore.ClearEntities()
    SetNuiFocus(false, false)
end)

CreateThread(function()
    Wait(800)
    TriggerServerEvent('core_creator:shops:requestSync')
    TriggerServerEvent('core_creator:blips:requestSync')
    TriggerServerEvent('core_creator:farms:requestSync')
    TriggerServerEvent('core_creator:jobs:requestSync')
    TriggerServerEvent('core_creator:garages:requestSync')
    TriggerServerEvent('core_creator:gangs:requestSync')
    TriggerServerEvent('core_creator:apartments:requestSync')
    TriggerServerEvent('core_creator:robberies:requestSync')
end)
