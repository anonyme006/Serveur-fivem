--[[
    esx_interim — Client principal
    Pôle Emploi NUI, dépôt, véhicule, menu ox_lib.
]]

local ESX
local nuiOpen = false
local currentJobId = nil
local workVehicle = nil
local depotZoneId = nil
local depotBlip = nil

local function L(key, ...)
    local str = (Locales['fr'] and Locales['fr'][key]) or key
    if select('#', ...) > 0 then
        return string.format(str, ...)
    end
    return str
end

local function Notify(msg, nType)
    lib.notify({
        title = L('agency_title'),
        description = msg,
        type = nType or 'inform',
    })
end

local function GetJobConfig(id)
    for _, job in ipairs(Config.Jobs) do
        if job.id == id then return job end
    end
end

-- =============================================================================
-- FRAMEWORK
-- =============================================================================
CreateThread(function()
    while GetResourceState('es_extended') ~= 'started' do Wait(100) end
    ESX = exports['es_extended']:getSharedObject()
end)

-- =============================================================================
-- NUI
-- =============================================================================
local function CloseNui()
    if not nuiOpen then return end
    nuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function OpenNui()
    if nuiOpen then return end
    if exports.esx_interim:IsWorking() then
        Notify(L('already_working'), 'error')
        return
    end

    local jobs = lib.callback.await('esx_interim:server:getJobs', false)
    if not jobs then return end

    nuiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        jobs = jobs,
        slogan = Config.PoleEmploi.slogan,
        confirmLabel = Config.PoleEmploi.confirmLabel,
    })
end

RegisterNUICallback('close', function(_, cb)
    CloseNui()
    cb('ok')
end)

RegisterNUICallback('selectJob', function(data, cb)
    cb('ok')
    local id = data and data.id
    CloseNui()
    if not id then return end

    local ok, err = lib.callback.await('esx_interim:server:selectJob', false, id)
    if not ok then
        Notify(err or L('job_locked'), 'error')
        return
    end

    currentJobId = id
    local job = GetJobConfig(id)
    Notify(L('job_started', job and job.label or id), 'success')
    SetupDepot(id)
end)

-- =============================================================================
-- BLIP + PED AGENCE
-- =============================================================================
CreateThread(function()
    local pe = Config.PoleEmploi
    if pe.blip.enabled then
        local blip = AddBlipForCoord(pe.blip.coords.x, pe.blip.coords.y, pe.blip.coords.z)
        SetBlipSprite(blip, pe.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, pe.blip.scale)
        SetBlipColour(blip, pe.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(pe.blip.label)
        EndTextCommandSetBlipName(blip)
    end

    if pe.ped.enabled then
        local model = joaat(pe.ped.model)
        lib.requestModel(model)
        local ped = CreatePed(4, model, pe.ped.coords.x, pe.ped.coords.y, pe.ped.coords.z - 1.0, pe.ped.coords.w, false, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        FreezeEntityPosition(ped, true)
        if pe.ped.scenario then
            TaskStartScenarioInPlace(ped, pe.ped.scenario, 0, true)
        end
        SetModelAsNoLongerNeeded(model)

        exports.ox_target:addLocalEntity(ped, {{
            name = 'esx_interim_agency',
            icon = pe.target.icon,
            label = pe.target.label,
            distance = 2.2,
            onSelect = OpenNui,
        }})
    else
        exports.ox_target:addSphereZone({
            coords = pe.target.coords,
            radius = pe.target.radius,
            options = {{
                name = 'esx_interim_agency',
                icon = pe.target.icon,
                label = pe.target.label,
                onSelect = OpenNui,
            }},
        })
    end
end)

-- =============================================================================
-- DÉPÔT MÉTIER
-- =============================================================================
local function ClearDepot()
    if depotZoneId then
        exports.ox_target:removeZone(depotZoneId)
        depotZoneId = nil
    end
    if depotBlip then
        RemoveBlip(depotBlip)
        depotBlip = nil
    end
end

local function DeleteWorkVehicle()
    if workVehicle and DoesEntityExist(workVehicle) then
        SetEntityAsMissionEntity(workVehicle, true, true)
        DeleteVehicle(workVehicle)
    end
    workVehicle = nil
end

local function SpawnWorkVehicle(job)
    DeleteWorkVehicle()
    local spawn = job.vehicleSpawn
    if IsAnyVehicleNearPoint(spawn.x, spawn.y, spawn.z, 3.0) then
        Notify(L('vehicle_blocked'), 'error')
        return false
    end

    local model = joaat(job.vehicle)
    lib.requestModel(model)
    workVehicle = CreateVehicle(model, spawn.x, spawn.y, spawn.z, spawn.w, true, false)
    SetVehicleOnGroundProperly(workVehicle)
    SetEntityAsMissionEntity(workVehicle, true, true)
    SetVehicleEngineOn(workVehicle, true, true, false)
    SetModelAsNoLongerNeeded(model)

    local plate = GetVehicleNumberPlateText(workVehicle)
    TriggerEvent('esx_interim:client:vehicleSpawned', workVehicle, plate)
    Notify(L('vehicle_spawned'), 'success')
    return true
end

function SetupDepot(jobId)
    ClearDepot()
    local job = GetJobConfig(jobId)
    if not job then return end

    depotBlip = AddBlipForCoord(job.depot.x, job.depot.y, job.depot.z)
    SetBlipSprite(depotBlip, job.blipSprite or 1)
    SetBlipColour(depotBlip, job.blipColor or 3)
    SetBlipScale(depotBlip, 0.85)
    SetBlipRoute(depotBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(job.label .. ' — Dépôt')
    EndTextCommandSetBlipName(depotBlip)

    local options = {
        {
            name = 'esx_interim_start_run',
            icon = 'fas fa-play',
            label = L('start_run'),
            canInteract = function()
                return currentJobId == jobId and not exports.esx_interim:IsWorking()
            end,
            onSelect = function()
                if not workVehicle or not DoesEntityExist(workVehicle) then
                    if not SpawnWorkVehicle(job) then return end
                end
                if depotBlip then SetBlipRoute(depotBlip, false) end
                exports.esx_interim:StartJobRun(jobId)
            end,
        },
        {
            name = 'esx_interim_return_veh',
            icon = 'fas fa-parking',
            label = L('return_vehicle'),
            canInteract = function()
                return workVehicle ~= nil and DoesEntityExist(workVehicle)
            end,
            onSelect = function()
                if exports.esx_interim:IsWorking() then
                    exports.esx_interim:CancelJobRun()
                end
                DeleteWorkVehicle()
                Notify(L('cancelled'), 'inform')
            end,
        },
        {
            name = 'esx_interim_quit',
            icon = 'fas fa-sign-out-alt',
            label = L('stop_job'),
            onSelect = function()
                QuitInterimJob()
            end,
        },
    }

    -- Point de vente minerais (joaillier)
    if job.sellPoint then
        options[#options + 1] = {
            name = 'esx_interim_info_sell',
            icon = 'fas fa-gem',
            label = 'GPS Joaillerie',
            onSelect = function()
                SetNewWaypoint(job.sellPoint.x, job.sellPoint.y)
                Notify(L('go_to_point'), 'inform')
            end,
        }
    end

    depotZoneId = exports.ox_target:addSphereZone({
        coords = job.depot,
        radius = 2.5,
        options = options,
    })
end

function QuitInterimJob()
    exports.esx_interim:CancelJobRun()
    DeleteWorkVehicle()
    ClearDepot()
    currentJobId = nil
    lib.callback.await('esx_interim:server:quitJob', false)
    Notify(L('job_stopped'), 'inform')
end

-- Sync job ESX si déjà intérim au login
RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    Wait(1500)
    local jobName = xPlayer and xPlayer.job and xPlayer.job.name
    if not jobName and ESX then
        local data = ESX.GetPlayerData()
        jobName = data and data.job and data.job.name
    end
    if jobName and GetJobConfig(jobName) then
        currentJobId = jobName
        SetupDepot(jobName)
    end
end)

RegisterNetEvent('esx:setJob', function(job)
    if job and GetJobConfig(job.name) then
        currentJobId = job.name
        SetupDepot(job.name)
    elseif currentJobId and (not job or not GetJobConfig(job.name)) then
        exports.esx_interim:CancelJobRun()
        DeleteWorkVehicle()
        ClearDepot()
        currentJobId = nil
    end
end)

-- Exports internes pour jobs.lua
exports('GetCurrentJobId', function()
    return currentJobId
end)

exports('GetWorkVehicle', function()
    return workVehicle
end)

exports('Notify', Notify)
exports('Locale', L)
exports('GetJobConfig', GetJobConfig)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    CloseNui()
    ClearDepot()
    DeleteWorkVehicle()
end)
