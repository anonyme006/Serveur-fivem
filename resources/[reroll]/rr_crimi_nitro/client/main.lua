local boosting = false

RegisterCommand('nitro', function()
    if not cache.vehicle or cache.seat ~= -1 then
        exports.rr_api:Notify('Nitro', 'Conducteur requis.', 'error')
        return
    end
    if boosting then return end
    local ok = lib.callback.await('rr_crimi_nitro:server:use', false)
    if not ok then
        exports.rr_api:Notify('Nitro', 'Pas de bouteille nitro.', 'error')
        return
    end
    boosting = true
    local veh = cache.vehicle
    SetVehicleBoostActive(veh, true)
    ModifyVehicleTopSpeed(veh, Config.Boost)
    local ends = GetGameTimer() + Config.Duration
    CreateThread(function()
        while GetGameTimer() < ends and cache.vehicle == veh do
            SetVehicleEnginePowerMultiplier(veh, Config.Boost)
            Wait(0)
        end
        SetVehicleEnginePowerMultiplier(veh, 1.0)
        SetVehicleBoostActive(veh, false)
        ModifyVehicleTopSpeed(veh, 1.0)
        boosting = false
    end)
end, false)
RegisterKeyMapping('nitro', 'Activer nitro', 'keyboard', 'LSHIFT')
