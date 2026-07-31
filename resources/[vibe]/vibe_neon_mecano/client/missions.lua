local missionVehicle = 0
local missionPed = 0
local currentMission = nil

local function cleanupMissionEntities()
    if missionVehicle ~= 0 and DoesEntityExist(missionVehicle) then
        DeleteEntity(missionVehicle)
    end
    if missionPed ~= 0 and DoesEntityExist(missionPed) then
        DeleteEntity(missionPed)
    end
    missionVehicle = 0
    missionPed = 0
end

local function spawnMissionScene(data)
    cleanupMissionEntities()
    local loc = data.coords
    local model = joaat(data.vehicleModel or 'blista')
    lib.requestModel(model)
    missionVehicle = CreateVehicle(model, loc.x, loc.y, loc.z, loc.w or 0.0, true, false)
    SetEntityAsMissionEntity(missionVehicle, true, true)
    SetVehicleOnGroundProperly(missionVehicle)
    SetVehicleDoorsLocked(missionVehicle, 2)
    SetVehicleEngineOn(missionVehicle, false, true, true)

    local mType = data.missionType
    local dmg = data.damage or {}
    if dmg.engine then SetVehicleEngineHealth(missionVehicle, dmg.engine) end
    if dmg.body then SetVehicleBodyHealth(missionVehicle, dmg.body) end
    if data.burstTires then
        SetVehicleTyreBurst(missionVehicle, 0, true, 1000.0)
        SetVehicleTyreBurst(missionVehicle, 1, true, 1000.0)
    end
    if mType == 'engine' or mType == 'battery' then
        SetVehicleUndriveable(missionVehicle, true)
    end

    local pedModel = joaat('a_m_y_business_01')
    lib.requestModel(pedModel)
    missionPed = CreatePed(4, pedModel, loc.x + 2.0, loc.y + 1.0, loc.z, 0.0, true, false)
    SetEntityAsMissionEntity(missionPed, true, true)
    TaskStartScenarioInPlace(missionPed, 'WORLD_HUMAN_STAND_MOBILE', 0, true)
    SetModelAsNoLongerNeeded(model)
    SetModelAsNoLongerNeeded(pedModel)
end

RegisterNetEvent('vibe_neon_mecano:client:startMission', function(data)
    currentMission = data
    spawnMissionScene(data)

    exports.ox_target:addLocalEntity(missionVehicle, {{
        name = 'neon_mission_repair',
        icon = 'fa-solid fa-wrench',
        label = 'Intervenir sur le véhicule',
        canInteract = function()
            return Neon.IsMechanic() and currentMission and currentMission.id == data.id
        end,
        onSelect = function()
            if not currentMission or currentMission.id ~= data.id then return end
            local ok = Neon.MissionRepair(missionVehicle, currentMission.missionType)
            if ok then
                TriggerServerEvent('vibe_neon_mecano:server:completeMission', currentMission.id)
            end
        end,
    }})
end)

RegisterNetEvent('vibe_neon_mecano:client:missionComplete', function()
    if missionPed ~= 0 and DoesEntityExist(missionPed) then
        TaskWanderStandard(missionPed, 10.0, 10)
        SetTimeout(15000, function()
            if DoesEntityExist(missionPed) then DeleteEntity(missionPed) end
        end)
    end
    if missionVehicle ~= 0 and DoesEntityExist(missionVehicle) then
        SetVehicleFixed(missionVehicle)
        SetVehicleUndriveable(missionVehicle, false)
        SetVehicleEngineOn(missionVehicle, true, true, false)
        SetTimeout(20000, function()
            if DoesEntityExist(missionVehicle) then DeleteEntity(missionVehicle) end
        end)
    end
    currentMission = nil
end)

RegisterNetEvent('vibe_neon_mecano:client:missionEnded', function()
    cleanupMissionEntities()
    currentMission = nil
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    cleanupMissionEntities()
end)
