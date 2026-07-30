local placing = false
local placementCam = nil
local placementObj = nil
local current = { x = 0.0, y = 0.0, z = 0.0, w = 0.0 }
local finishCb = nil
local options = {}

local function destroyPlacement()
    placing = false
    if placementCam then
        RenderScriptCams(false, true, 300, true, true)
        DestroyCam(placementCam, false)
        placementCam = nil
    end
    if placementObj and DoesEntityExist(placementObj) then
        DeleteEntity(placementObj)
        placementObj = nil
    end
end

local function rotationToDirection(rot)
    local z = math.rad(rot.z)
    local x = math.rad(rot.x)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

local function syncNuiCoords()
    SendNUIMessage({
        action = 'placementCoords',
        data = {
            x = CoreUtils.Round(current.x, 4),
            y = CoreUtils.Round(current.y, 4),
            z = CoreUtils.Round(current.z, 4),
            w = CoreUtils.Round(current.w, 2),
        },
    })
end

AddEventHandler('core_creator:placement:start', function(opts, cb)
    if placing then return end
    options = opts or {}
    finishCb = cb
    placing = true

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    current = {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        w = GetEntityHeading(ped),
    }

    placementCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(placementCam, coords.x, coords.y, coords.z + 2.0)
    SetCamRot(placementCam, -20.0, 0.0, GetEntityHeading(ped), 2)
    SetCamActive(placementCam, true)
    RenderScriptCams(true, true, 400, true, true)

    if options.previewModel then
        local hash = joaat(options.previewModel)
        RequestModel(hash)
        local t = GetGameTimer() + 3000
        while not HasModelLoaded(hash) and GetGameTimer() < t do Wait(10) end
        if HasModelLoaded(hash) then
            if IsModelAVehicle(hash) then
                placementObj = CreateVehicle(hash, current.x, current.y, current.z, current.w, false, false)
            else
                placementObj = CreateObject(hash, current.x, current.y, current.z, false, false, false)
            end
            SetEntityCollision(placementObj, false, false)
            FreezeEntityPosition(placementObj, true)
            SetEntityAlpha(placementObj, 180, false)
            SetModelAsNoLongerNeeded(hash)
        end
    end

    SetNuiFocus(false, false)
    Bridge.Notify('Placement: Entrée = confirmer | Retour = annuler | Shift = précision', 'inform', 7000)

    CreateThread(function()
        while placing do
            local speed = Config.Placement.cameraSpeed
            if IsControlPressed(0, Config.Placement.fineControl) then
                speed = speed * 0.25
            elseif IsControlPressed(0, 21) then
                speed = speed * Config.Placement.cameraFastMultiplier
            end

            local camPos = GetCamCoord(placementCam)
            local camRot = GetCamRot(placementCam, 2)
            local dir = rotationToDirection(camRot)
            local right = vector3(-dir.y, dir.x, 0.0)

            if IsControlPressed(0, 32) then camPos = camPos + dir * speed end -- W
            if IsControlPressed(0, 33) then camPos = camPos - dir * speed end -- S
            if IsControlPressed(0, 34) then camPos = camPos - right * speed end -- A
            if IsControlPressed(0, 35) then camPos = camPos + right * speed end -- D
            if IsControlPressed(0, 22) then camPos = camPos + vector3(0.0, 0.0, speed) end -- SPACE
            if IsControlPressed(0, 36) then camPos = camPos - vector3(0.0, 0.0, speed) end -- CTRL

            local lookX = GetControlNormal(0, 1) * Config.Placement.rotateSpeed
            local lookY = GetControlNormal(0, 2) * Config.Placement.rotateSpeed
            camRot = vector3(camRot.x - lookY, 0.0, camRot.z - lookX)
            SetCamCoord(placementCam, camPos.x, camPos.y, camPos.z)
            SetCamRot(placementCam, camRot.x, camRot.y, camRot.z, 2)

            -- Raycast to ground/aim point
            local dest = camPos + dir * 80.0
            local ray = StartShapeTestRay(camPos.x, camPos.y, camPos.z, dest.x, dest.y, dest.z, -1, PlayerPedId(), 0)
            local _, hit, endCoords = GetShapeTestResult(ray)
            if hit == 1 then
                current.x, current.y, current.z = endCoords.x, endCoords.y, endCoords.z
            else
                current.x, current.y, current.z = dest.x, dest.y, dest.z
            end

            if IsControlPressed(0, 44) then -- Q
                current.w = current.w - 1.5
            end
            if IsControlPressed(0, 38) then -- E
                current.w = current.w + 1.5
            end

            if placementObj and DoesEntityExist(placementObj) then
                SetEntityCoords(placementObj, current.x, current.y, current.z, false, false, false, false)
                SetEntityHeading(placementObj, current.w)
            else
                ClientCore.DrawMarkerAt(current, Config.Defaults.marker)
            end

            -- simple gizmo lines
            DrawLine(current.x, current.y, current.z, current.x + 1.0, current.y, current.z, 255, 60, 60, 200)
            DrawLine(current.x, current.y, current.z, current.x, current.y + 1.0, current.z, 60, 255, 60, 200)
            DrawLine(current.x, current.y, current.z, current.x, current.y, current.z + 1.0, 60, 60, 255, 200)

            syncNuiCoords()

            if IsControlJustReleased(0, Config.Placement.confirmControl) then
                local result = {
                    ok = true,
                    data = {
                        x = CoreUtils.Round(current.x, 4),
                        y = CoreUtils.Round(current.y, 4),
                        z = CoreUtils.Round(current.z, 4),
                        w = CoreUtils.Round(current.w, 2),
                    },
                }
                destroyPlacement()
                if finishCb then finishCb(result) end
                break
            end

            if IsControlJustReleased(0, Config.Placement.cancelControl) or IsControlJustReleased(0, 322) then
                destroyPlacement()
                if finishCb then finishCb({ ok = false }) end
                break
            end

            Wait(0)
        end
    end)
end)

AddEventHandler('onResourceStop', function(res)
    if res == CoreUtils.ResourceName() then
        destroyPlacement()
    end
end)
