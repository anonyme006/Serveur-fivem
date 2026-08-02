local braced = {}

RegisterNetEvent('rr_bracelet:server:set', function(target, enable)
    local src = source
    if not exports.rr_api:HasPoliceJob(src, true) then return end
    if enable then
        braced[target] = true
        exports.rr_api:Notify(target, 'Bracelet', 'Un bracelet electronique a ete pose.', 'error')
    else
        braced[target] = nil
        exports.rr_api:Notify(target, 'Bracelet', 'Bracelet retire.', 'inform')
    end
    exports.rr_api:Notify(src, 'Bracelet', enable and 'Bracelet pose.' or 'Bracelet retire.', 'success')
end)

CreateThread(function()
    while true do
        Wait(Config.Update * 1000)
        local payload = {}
        for target in pairs(braced) do
            local ped = GetPlayerPed(target)
            if ped and ped ~= 0 then
                local c = GetEntityCoords(ped)
                payload[target] = { x = c.x, y = c.y, z = c.z }
            end
        end
        for _, id in pairs(GetPlayers()) do
            id = tonumber(id)
            if exports.rr_api:HasPoliceJob(id, true) then
                TriggerClientEvent('rr_bracelet:client:sync', id, payload)
            end
        end
    end
end)
