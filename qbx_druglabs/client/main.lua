ClientLabs = {
    list = {}, ---@type table<number, table>
    byId = {},
    insideLabId = nil,
    interiorZones = {},
    blips = {},
}

local function indexLabs(labs)
    ClientLabs.list = labs or {}
    ClientLabs.byId = {}
    for i = 1, #ClientLabs.list do
        local lab = ClientLabs.list[i]
        ClientLabs.byId[lab.id] = lab
    end
end

function ClientLabs.Get(labId)
    return ClientLabs.byId[labId]
end

function ClientLabs.Set(lab)
    if not lab or not lab.id then return end
    if lab.deleted then
        ClientLabs.byId[lab.id] = nil
        for i = #ClientLabs.list, 1, -1 do
            if ClientLabs.list[i].id == lab.id then
                table.remove(ClientLabs.list, i)
                break
            end
        end
        return
    end
    ClientLabs.byId[lab.id] = lab
    local found = false
    for i = 1, #ClientLabs.list do
        if ClientLabs.list[i].id == lab.id then
            ClientLabs.list[i] = lab
            found = true
            break
        end
    end
    if not found then
        ClientLabs.list[#ClientLabs.list + 1] = lab
    end
end

RegisterNetEvent(DrugLabs.Events.client.syncLabs, function(labs)
    indexLabs(labs)
    Targets.RefreshAll()
    Blips.RefreshAll()
end)

RegisterNetEvent(DrugLabs.Events.client.refreshLab, function(lab)
    ClientLabs.Set(lab)
    Targets.RefreshLab(lab and lab.id)
    Blips.RefreshLab(lab and lab.id)
    if ClientLabs.insideLabId and lab and lab.id == ClientLabs.insideLabId then
        if lab.deleted or lab.sealed then
            Interiors.Leave(true)
        else
            Interiors.RebuildInteriorTargets(lab)
        end
    end
end)

CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do
        Wait(500)
    end
    Wait(1000)
    local result = lib.callback.await('qbx_druglabs:server:getLabs', false)
    if result and result.ok then
        indexLabs(result.data)
        Targets.RefreshAll()
        Blips.RefreshAll()
    end
end)

-- Fallback login detection for Qbox
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    SetTimeout(1000, function()
        local result = lib.callback.await('qbx_druglabs:server:getLabs', false)
        if result and result.ok then
            indexLabs(result.data)
            Targets.RefreshAll()
            Blips.RefreshAll()
        end
    end)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= DrugLabs.Resource then return end
    Targets.ClearAll()
    Blips.ClearAll()
    if ClientLabs.insideLabId then
        DoScreenFadeIn(0)
        local ped = cache.ped or PlayerPedId()
        -- leave bucket cleanup is server-side; teleport safety
        FreezeEntityPosition(ped, false)
    end
    lib.hideTextUI()
end)

Blips = Blips or {}
local blipHandles = {}

function Blips.ClearAll()
    for id, blip in pairs(blipHandles) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
        blipHandles[id] = nil
    end
end

function Blips.RefreshAll()
    Blips.ClearAll()
    for i = 1, #ClientLabs.list do
        Blips.RefreshLab(ClientLabs.list[i].id)
    end
end

function Blips.RefreshLab(labId)
    if blipHandles[labId] and DoesBlipExist(blipHandles[labId]) then
        RemoveBlip(blipHandles[labId])
        blipHandles[labId] = nil
    end
    local lab = ClientLabs.Get(labId)
    if not lab or lab.deleted then return end
    local blipData = lab.blip or {}
    if blipData.enabled ~= true then return end
    local e = lab.entrance
    if not e then return end
    local blip = AddBlipForCoord(e.x, e.y, e.z)
    SetBlipSprite(blip, blipData.sprite or 499)
    SetBlipColour(blip, blipData.color or 1)
    SetBlipScale(blip, blipData.scale or 0.7)
    SetBlipAsShortRange(blip, blipData.shortRange ~= false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(lab.label or 'Laboratory')
    EndTextCommandSetBlipName(blip)
    blipHandles[labId] = blip
end
