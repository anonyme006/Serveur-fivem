lib.callback.register('rr_permits:server:mine', function(source)
    local cid = exports.rr_api:GetCitizenId(source)
    return exports.rr_api:LoadPlayerMeta(cid)
end)

RegisterNetEvent('rr_permits:server:showClosest', function()
    local src = source
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local closest, closestDist
    for _, id in pairs(GetPlayers()) do
        id = tonumber(id)
        if id ~= src then
            local dist = #(coords - GetEntityCoords(GetPlayerPed(id)))
            if dist < Config.CheckDistance and (not closestDist or dist < closestDist) then
                closest, closestDist = id, dist
            end
        end
    end
    if not closest then
        exports.rr_api:Notify(src, 'Permis', 'Personne à proximité.', 'error')
        return
    end
    local cid = exports.rr_api:GetCitizenId(src)
    local meta = exports.rr_api:LoadPlayerMeta(cid)
    TriggerClientEvent('rr_permits:client:show', closest, exports.rr_api:GetCharName(src), meta.permits or {})
    exports.rr_api:Notify(src, 'Permis', 'Tu montres tes permis.', 'inform')
end)
