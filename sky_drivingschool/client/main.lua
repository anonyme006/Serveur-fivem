SkyDS = SkyDS or {}
SkyDS.Client = SkyDS.Client or {}

local blips = {}
local peds = {}

local function loadModel(model)
    local hash = joaat(model)
    if not IsModelInCdimage(hash) then return false end
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(10)
    end
    return HasModelLoaded(hash)
end

local function spawnSchoolPed(school)
    if not school.ped or not school.reception then return end
    if not loadModel(school.ped.model) then return end
    local c = school.reception
    local ped = CreatePed(0, joaat(school.ped.model), c.x, c.y, c.z - 1.0, c.w or 0.0, false, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    if school.ped.scenario then
        TaskStartScenarioInPlace(ped, school.ped.scenario, 0, true)
    end
    peds[school.id] = ped
    SetModelAsNoLongerNeeded(joaat(school.ped.model))
end

local function createBlips()
    for _, school in ipairs(Config.Schools or {}) do
        if school.blip and school.reception then
            local b = AddBlipForCoord(school.reception.x, school.reception.y, school.reception.z)
            SetBlipSprite(b, school.blip.sprite or 408)
            SetBlipDisplay(b, 4)
            SetBlipScale(b, school.blip.scale or 0.8)
            SetBlipColour(b, school.blip.color or 3)
            SetBlipAsShortRange(b, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(school.blip.label or L('school_blip'))
            EndTextCommandSetBlipName(b)
            blips[school.id] = b
        end
    end
end

local function cleanup()
    for _, b in pairs(blips) do
        if DoesBlipExist(b) then RemoveBlip(b) end
    end
    blips = {}
    for _, ped in pairs(peds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    peds = {}
end

CreateThread(function()
    createBlips()
    for _, school in ipairs(Config.Schools or {}) do
        spawnSchoolPed(school)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    cleanup()
    if SkyDS.Client.StopPractical then SkyDS.Client.StopPractical(true) end
    SetNuiFocus(false, false)
end)

function SkyDS.Client.Notify(description, nType, title)
    lib.notify({
        title = title or 'DMV',
        description = description,
        type = nType or 'inform',
        position = Config.Notify and Config.Notify.position or 'top-right',
        duration = Config.Notify and Config.Notify.duration or 5000,
    })
end

function SkyDS.Client.GetPeds()
    return peds
end
