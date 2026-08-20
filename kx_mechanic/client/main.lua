KX = KX or {}
KX.PlayerData = {}
KX.IsMechanic = false
KX.OnDuty = false
KX.Grade = 0
KX.NuiOpen = false
KX.CurrentVehicle = nil
KX.Busy = false

local function refreshJob()
    local job = lib.callback.await('kx_mechanic:server:getPlayerJob', false)
    if not job then
        KX.IsMechanic = false
        KX.OnDuty = false
        KX.Grade = 0
        return
    end

    KX.IsMechanic = job.name == Config.Job
    KX.OnDuty = job.onduty == true
    KX.Grade = job.grade or 0
end

CreateThread(function()
    refreshJob()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    refreshJob()
end)

RegisterNetEvent('qbx_core:client:playerLoaded', function()
    refreshJob()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    if type(job) == 'table' then
        KX.IsMechanic = job.name == Config.Job
        KX.OnDuty = job.onduty == true
        KX.Grade = job.grade and (job.grade.level or job.grade) or 0
    else
        refreshJob()
    end
end)

RegisterNetEvent('qbx_core:client:onGroupUpdate', function()
    refreshJob()
end)

function KX.CanWork()
    if not KX.IsMechanic then return false end
    if Config.RequireOnDuty and not KX.OnDuty then return false end
    return true
end

function KX.HasPerm(permission)
    if not KX.CanWork() then return false end
    return Utils.HasPermission(KX.Grade, permission)
end

function KX.Notify(message, nType)
    Utils.Notify(nil, message, nType)
end

function KX.GetClosestVehicle(maxDistance)
    maxDistance = maxDistance or Config.MaxRepairDistance
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicle = lib.getClosestVehicle(coords, maxDistance, true)
    if vehicle and DoesEntityExist(vehicle) then
        return vehicle
    end
    return nil
end

function KX.GetVehiclePlate(vehicle)
    if not vehicle or vehicle == 0 then return nil end
    return Utils.NormalizePlate(GetVehicleNumberPlateText(vehicle))
end

function KX.GetNativeSnapshot(vehicle)
    if not vehicle or vehicle == 0 then return nil end
    return {
        engine = GetVehicleEngineHealth(vehicle),
        body = GetVehicleBodyHealth(vehicle),
        fuel = GetVehicleFuelLevel(vehicle),
        temp = GetVehicleEngineTemperature(vehicle),
        dirt = GetVehicleDirtLevel(vehicle),
    }
end

function KX.SetNui(state, payload)
    KX.NuiOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({
        action = state and 'open' or 'close',
        data = payload,
    })
end

RegisterCommand('mechanic', function()
    if not KX.CanWork() then
        KX.Notify('Vous devez être mécanicien.', 'error')
        return
    end
    KX.OpenMechanicMenu()
end, false)

RegisterKeyMapping('mechanic', 'Ouvrir le menu mécanicien', 'keyboard', 'F6')

exports('CanWork', function()
    return KX.CanWork()
end)