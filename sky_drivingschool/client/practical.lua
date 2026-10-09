SkyDS = SkyDS or {}
SkyDS.Client = SkyDS.Client or {}

local exam = nil
local examVehicle = nil
local checkpointBlips = {}
local routeBlip = nil
local currentCp = 1
local monitoring = false
local lastHealth = 1000
local tookOff = false
local landed = false
local leftVehicleWarn = 0

local function clearBlips()
    for _, b in ipairs(checkpointBlips) do
        if DoesBlipExist(b) then RemoveBlip(b) end
    end
    checkpointBlips = {}
    if routeBlip and DoesBlipExist(routeBlip) then RemoveBlip(routeBlip) end
    routeBlip = nil
end

local function deleteVehicle()
    if examVehicle and DoesEntityExist(examVehicle) then
        SetEntityAsMissionEntity(examVehicle, true, true)
        DeleteVehicle(examVehicle)
    end
    examVehicle = nil
end

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    RequestModel(hash)
    local t = GetGameTimer() + 8000
    while not HasModelLoaded(hash) and GetGameTimer() < t do Wait(10) end
    return HasModelLoaded(hash), hash
end

local function setupCheckpoints()
    clearBlips()
    if not exam or not exam.checkpoints then return end
    for i, cp in ipairs(exam.checkpoints) do
        local b = AddBlipForCoord(cp.x, cp.y, cp.z)
        SetBlipSprite(b, i == 1 and 1 or 1)
        SetBlipColour(b, i == 1 and 2 or 3)
        SetBlipScale(b, i == 1 and 0.9 or 0.6)
        SetBlipAsShortRange(b, false)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(('Checkpoint %s'):format(i))
        EndTextCommandSetBlipName(b)
        if i == 1 then
            SetBlipRoute(b, true)
            routeBlip = b
        end
        checkpointBlips[i] = b
    end
end

local function advanceCheckpoint()
    if checkpointBlips[currentCp] and DoesBlipExist(checkpointBlips[currentCp]) then
        RemoveBlip(checkpointBlips[currentCp])
        if routeBlip == checkpointBlips[currentCp] then routeBlip = nil end
    end
    currentCp = currentCp + 1
    lib.callback.await('sky_drivingschool:server:practicalInfraction', false, 'checkpoint', { index = currentCp - 1 })
    if currentCp <= #(exam.checkpoints or {}) then
        local b = checkpointBlips[currentCp]
        if b and DoesBlipExist(b) then
            SetBlipColour(b, 2)
            SetBlipScale(b, 0.9)
            SetBlipRoute(b, true)
            routeBlip = b
        end
        SkyDS.Client.Notify(L('checkpoint', currentCp - 1, #exam.checkpoints), 'inform')
        SkyDS.Client.SendNui('practicalHud', {
            checkpoint = currentCp - 1,
            total = #exam.checkpoints,
        })
    end
end

local function report(infraction, detail)
    if not exam or not monitoring then return end
    local res = lib.callback.await('sky_drivingschool:server:practicalInfraction', false, infraction, detail)
    if res and res.state then
        SkyDS.Client.SendNui('practicalHud', {
            score = res.state.score,
            errorCount = res.state.errorCount,
            deduction = res.state.deduction,
            lastInfraction = infraction,
        })
        if res.state.failNow then
            SkyDS.Client.FinishPractical(infraction == 'death' and 'death' or 'failed')
        end
    end
end

function SkyDS.Client.StopPractical(silent)
    monitoring = false
    clearBlips()
    deleteVehicle()
    exam = nil
    currentCp = 1
    tookOff = false
    landed = false
    if not silent then
        SkyDS.Client.SendNui('practicalEnd', {})
        SetNuiFocus(false, false)
    end
end

function SkyDS.Client.FinishPractical(reason)
    if not exam or not monitoring then return end
    monitoring = false
    local payload = {
        reason = reason or 'complete',
        checkpointsHit = math.max(0, currentCp - 1),
        tookOff = tookOff,
        landed = landed,
    }
    clearBlips()
    local result = lib.callback.await('sky_drivingschool:server:finishPractical', false, payload)
    deleteVehicle()
    exam = nil
    if result and result.ok then
        SkyDS.Client.OpenNui('practicalResult', result.result)
    else
        SkyDS.Client.Notify(result and result.error or L('practical_failed', 0), 'error')
    end
end

function SkyDS.Client.BeginPractical(data)
    if monitoring then return end
    exam = data
    currentCp = 1
    tookOff = false
    landed = false
    monitoring = true

    local ok, hash = loadModel(data.vehicleModel)
    if not ok then
        SkyDS.Client.Notify(L('vehicle_spawn_failed'), 'error')
        lib.callback.await('sky_drivingschool:server:finishPractical', false, { reason = 'abandon', checkpointsHit = 0 })
        monitoring = false
        exam = nil
        return
    end

    local s = data.spawn
    examVehicle = CreateVehicle(hash, s.x, s.y, s.z, s.w or 0.0, true, false)
    SetModelAsNoLongerNeeded(hash)
    if not examVehicle or examVehicle == 0 then
        SkyDS.Client.Notify(L('vehicle_spawn_failed'), 'error')
        lib.callback.await('sky_drivingschool:server:finishPractical', false, { reason = 'abandon', checkpointsHit = 0 })
        monitoring = false
        exam = nil
        return
    end

    SetVehicleOnGroundProperly(examVehicle)
    SetVehicleEngineOn(examVehicle, true, true, false)
    SetPedIntoVehicle(PlayerPedId(), examVehicle, -1)
    SetVehicleNumberPlateText(examVehicle, 'DMVEXAM')
    lastHealth = GetVehicleBodyHealth(examVehicle)

    local netId = NetworkGetNetworkIdFromEntity(examVehicle)
    SetNetworkIdCanMigrate(netId, true)
    lib.callback.await('sky_drivingschool:server:registerExamVehicle', false, netId)

    setupCheckpoints()

    -- Lightweight HUD via NUI without capturing mouse
    SendNUIMessage({
        action = 'practicalHud',
        data = {
            active = true,
            label = data.label,
            score = data.startingScore,
            passScore = data.passScore,
            timeLimit = data.timeLimit,
            checkpoint = 0,
            total = #(data.checkpoints or {}),
            speedLimit = data.speedLimitMph,
        },
    })

    CreateThread(function()
        local endsAt = GetGameTimer() + ((data.timeLimit or 600) * 1000)
        local speedWarnAt = 0
        local zoneWarnAt = 0
        local damageTick = 0

        while monitoring and exam do
            local sleep = 200
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)

            -- Death
            if (Config.AntiCheat and Config.AntiCheat.deathFailExam) and IsEntityDead(ped) then
                report('death', {})
                SkyDS.Client.FinishPractical('death')
                break
            end

            -- Must stay in exam vehicle
            if examVehicle and DoesEntityExist(examVehicle) then
                if veh ~= examVehicle then
                    sleep = 100
                    leftVehicleWarn = leftVehicleWarn + 1
                    if leftVehicleWarn == 1 then
                        SkyDS.Client.Notify(L('left_vehicle'), 'error')
                    end
                    if leftVehicleWarn > 15 then -- ~1.5s grace then penalty / fail path
                        report('left_vehicle', {})
                        leftVehicleWarn = 0
                    end
                    if (Config.AntiCheat and Config.AntiCheat.vehicleSwapFailExam) and veh ~= 0 and veh ~= examVehicle then
                        report('abandon', { reason = 'vehicle_swap' })
                        SkyDS.Client.FinishPractical('abandon')
                        break
                    end
                else
                    leftVehicleWarn = 0
                    sleep = 100

                    -- Speed
                    local speed = GetEntitySpeed(veh) * 2.236936 -- m/s to mph
                    local limit = (exam.speedLimitMph or 45) + (exam.speedToleranceMph or 5)
                    if speed > limit then
                        if GetGameTimer() > speedWarnAt then
                            report('speeding', { speed = speed, limit = limit })
                            SkyDS.Client.Notify(L('speeding'), 'warning')
                            speedWarnAt = GetGameTimer() + 4000
                        end
                    end

                    -- Damage
                    if GetGameTimer() > damageTick then
                        damageTick = GetGameTimer() + (Config.PracticalScoring.damageCheckIntervalMs or 500)
                        local health = GetVehicleBodyHealth(veh)
                        local delta = lastHealth - health
                        if delta > 8 then
                            if HasEntityCollidedWithAnything(veh) then
                                report('vehicle_collision', { delta = delta })
                            else
                                report('vehicle_damage', { delta = delta })
                            end
                            SkyDS.Client.Notify(L('collision'), 'warning')
                        end
                        lastHealth = health
                        if health < 100 or IsEntityDead(veh) then
                            report('abandon', { reason = 'vehicle_destroyed' })
                            SkyDS.Client.FinishPractical('abandon')
                            break
                        end
                    end

                    -- Air / boat specifics
                    if exam.vehicleType == 'air' then
                        local height = GetEntityHeightAboveGround(veh)
                        if height > (exam.minAltitude or 15.0) then tookOff = true end
                        if tookOff and height < 3.0 and speed < 20.0 then landed = true end
                        if tookOff and HasEntityCollidedWithAnything(veh) then
                            if height < 8.0 and speed > 35.0 then
                                report('crash_landing', { height = height, speed = speed })
                            elseif height < 8.0 then
                                report('hard_landing', { height = height })
                            else
                                report('object_collision', {})
                            end
                        end
                    elseif exam.vehicleType == 'boat' then
                        if HasEntityCollidedWithAnything(veh) then
                            report('water_collision', {})
                        end
                    end
                end
            end

            -- Zone check
            if exam.zoneCenter and exam.zoneRadius then
                local pos = GetEntityCoords(ped)
                local dist = #(pos - vec3(exam.zoneCenter.x, exam.zoneCenter.y, exam.zoneCenter.z))
                local grace = exam.graceZone or 35.0
                if dist > (exam.zoneRadius + grace) then
                    if GetGameTimer() > zoneWarnAt then
                        SkyDS.Client.Notify(L('out_of_zone'), 'error')
                        report('out_of_zone', { dist = dist })
                        zoneWarnAt = GetGameTimer() + 3000
                    end
                end
            end

            -- Checkpoints
            if exam.checkpoints and currentCp <= #exam.checkpoints then
                local cp = exam.checkpoints[currentCp]
                local pos = GetEntityCoords(ped)
                local radius = exam.checkpointRadius or 8.0
                if #(pos - vec3(cp.x, cp.y, cp.z)) <= radius then
                    advanceCheckpoint()
                    if currentCp > #exam.checkpoints then
                        if exam.vehicleType == 'air' and exam.requireLanding and not landed then
                            -- soft completion wait for landing
                            SkyDS.Client.Notify('Land to complete the exam.', 'inform')
                        else
                            SkyDS.Client.FinishPractical('complete')
                            break
                        end
                    end
                end
            elseif exam.vehicleType == 'air' and exam.requireLanding and landed and currentCp > #exam.checkpoints then
                SkyDS.Client.FinishPractical('complete')
                break
            end

            -- Timer
            local remaining = math.floor((endsAt - GetGameTimer()) / 1000)
            if remaining <= 0 then
                SkyDS.Client.FinishPractical('overtime')
                break
            end
            if remaining % 5 == 0 then
                SkyDS.Client.SendNui('practicalHud', { remaining = remaining })
            end

            Wait(sleep)
        end
    end)
end

-- Cleanup on resource stop handled in main.lua
