local Blips = {}
local cache = { serverId = GetPlayerServerId(PlayerId()) }

CreateThread(function()
    while cache.serverId == 0 do
        cache.serverId = GetPlayerServerId(PlayerId())
        Wait(500)
    end
end)

---@param blip number
---@param data table|nil
local function applyBlipStyle(blip, data)
    if not blip or not data then return end

    local style = data.blip or {}
    local coords = data.coords

    if coords and coords.x then
        SetBlipCoords(blip, coords.x, coords.y, coords.z)
    end

    SetBlipSprite(blip, style.sprite or 1)
    SetBlipColour(blip, style.color or 1)
    SetBlipScale(blip, style.scale or 0.65)
    SetBlipAsShortRange(blip, Config.Blips and Config.Blips.shortRange == true)

    if data.blipName then
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(data.blipName)
        EndTextCommandSetBlipName(blip)
    end
end

---@param serverId number
---@param data table
local function createBlip(serverId, data)
    if Blips[serverId] then return end
    if not data.coords or not data.coords.x then return end

    local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
    SetBlipDisplay(blip, 4)
    SetBlipCategory(blip, 7)
    Blips[serverId] = blip
    applyBlipStyle(blip, data)
end

---@param serverId number
local function removeBlip(serverId)
    local blip = Blips[serverId]
    if blip then
        RemoveBlip(blip)
        Blips[serverId] = nil
    end
end

local function clearAllBlips()
    for serverId in pairs(Blips) do
        removeBlip(serverId)
    end
end

---@param employees table<number, table>
local function syncBlips(employees)
    local seen = {}

    for serverId, data in pairs(employees or {}) do
        serverId = tonumber(serverId)
        if serverId and serverId ~= cache.serverId then
            seen[serverId] = true
            if Blips[serverId] then
                applyBlipStyle(Blips[serverId], data)
            else
                createBlip(serverId, data)
            end
        end
    end

    for serverId in pairs(Blips) do
        if not seen[serverId] then
            removeBlip(serverId)
        end
    end
end

RegisterNetEvent('qbx-duty:client:updateBlips', function(employees)
    syncBlips(employees)
end)

RegisterNetEvent('qbx-duty:client:updateCoords', function(coordsMap)
    for serverId, coords in pairs(coordsMap or {}) do
        serverId = tonumber(serverId)
        local blip = serverId and Blips[serverId]
        if blip and coords and coords.x then
            SetBlipCoords(blip, coords.x, coords.y, coords.z)
        end
    end
end)

RegisterNetEvent('qbx-duty:client:removeBlip', function(serverId)
    removeBlip(tonumber(serverId))
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    clearAllBlips()
end)

exports('RefreshBlips', function()
    TriggerServerEvent('qbx-duty:server:requestBlipSync')
end)
