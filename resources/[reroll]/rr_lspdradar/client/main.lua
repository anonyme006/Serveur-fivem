local enabled = false

local function kmh(entity)
    return GetEntitySpeed(entity) * 3.6
end

RegisterCommand('radar', function()
    if not exports.rr_api:IsPolice(true) then
        exports.rr_api:Notify('Radar', 'FDO en service uniquement.', 'error')
        return
    end
    enabled = not enabled
    exports.rr_api:Notify('Radar', enabled and 'Radar activé.' or 'Radar désactivé.', 'inform')
end, false)

CreateThread(function()
    while true do
        if enabled and cache.vehicle then
            if (not Config.OnlyInEmergencyVehicle) or GetVehicleClass(cache.vehicle) == 18 then
                local pos = GetEntityCoords(cache.vehicle)
                local fwd = GetOffsetFromEntityInWorldCoords(cache.vehicle, 0.0, 25.0, 0.0)
                local ray = StartShapeTestRay(pos.x, pos.y, pos.z, fwd.x, fwd.y, fwd.z, 10, cache.vehicle, 0)
                local _, hit, _, _, entity = GetShapeTestResult(ray)
                if hit == 1 and IsEntityAVehicle(entity) then
                    local speed = math.floor(kmh(entity))
                    local plate = GetVehicleNumberPlateText(entity)
                    lib.showTextUI(('Radar: %s km/h | %s%s'):format(speed, plate, speed > Config.SpeedLimit and ' ⚠' or ''))
                else
                    lib.hideTextUI()
                end
                Wait(150)
            else
                Wait(500)
            end
        else
            lib.hideTextUI()
            Wait(500)
        end
    end
end)
