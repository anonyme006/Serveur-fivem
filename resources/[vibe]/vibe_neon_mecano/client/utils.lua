Neon = Neon or {}

function Neon.IsMechanic()
    local job = exports.vibe_api:GetJob()
    return job and Config.Jobs[job.name] and job.onduty
end

function Neon.GetTargetVehicle(maxDist)
    maxDist = maxDist or 5.0
    if cache.vehicle and cache.vehicle ~= 0 then
        return cache.vehicle
    end
    return GetClosestVehicle(GetEntityCoords(cache.ped), maxDist, 0, 71)
end

function Neon.GetVehicleState(veh)
    if veh == 0 then return nil end
    local burst = {}
    for i = 0, 7 do
        burst[i] = IsVehicleTyreBurst(veh, i, false)
    end
    return {
        engine = GetVehicleEngineHealth(veh),
        body = GetVehicleBodyHealth(veh),
        tank = GetVehiclePetrolTankHealth(veh),
        burst = burst,
        dirty = GetVehicleDirtLevel(veh),
    }
end

function Neon.FormatHealth(value)
    return math.floor(math.max(0, math.min(100, (value / 10.0))))
end

function Neon.PlayAnim(dict, clip, flag)
    lib.requestAnimDict(dict)
    TaskPlayAnim(cache.ped, dict, clip, 8.0, -8.0, -1, flag or 1, 0, false, false, false)
end

function Neon.StopAnim()
    ClearPedTasks(cache.ped)
end

function Neon.Progress(opts)
    return lib.progressCircle({
        duration = opts.duration,
        label = opts.label,
        position = 'bottom',
        canCancel = opts.canCancel ~= false,
        disable = opts.disable or { move = true, car = true, combat = true },
        anim = opts.anim,
    })
end

function Neon.Notify(title, msg, nType)
    exports.vibe_api:Notify(title or Config.CompanyName, msg, nType or 'inform')
end

function Neon.ApplyPartialFix(veh, fixType)
    if veh == 0 then return end
    if fixType == 'engine' then
        SetVehicleEngineHealth(veh, 1000.0)
        SetVehicleUndriveable(veh, false)
    elseif fixType == 'body' then
        SetVehicleBodyHealth(veh, 1000.0)
        SetVehicleDeformationFixed(veh)
    elseif fixType == 'tank' then
        SetVehiclePetrolTankHealth(veh, 1000.0)
    elseif fixType == 'tires' then
        for i = 0, 7 do
            if IsVehicleTyreBurst(veh, i, false) then
                SetVehicleTyreFixed(veh, i)
            end
        end
    elseif fixType == 'clean' then
        SetVehicleDirtLevel(veh, 0.0)
        WashDecalsFromVehicle(veh, 1.0)
    elseif fixType == 'full' then
        SetVehicleFixed(veh)
        SetVehicleDeformationFixed(veh)
        SetVehicleEngineHealth(veh, 1000.0)
        SetVehicleBodyHealth(veh, 1000.0)
        SetVehiclePetrolTankHealth(veh, 1000.0)
        SetVehicleUndriveable(veh, false)
        for i = 0, 7 do
            SetVehicleTyreFixed(veh, i)
        end
        SetVehicleDirtLevel(veh, 0.0)
    end
end

RegisterNetEvent('vibe_neon_mecano:client:applyFix', function(netId, fixType)
    local veh = NetworkGetEntityFromNetworkId(netId)
    if veh == 0 then return end
    Neon.ApplyPartialFix(veh, fixType)
end)
