lib.callback.register('vibe_permits:server:mine', function(source)
    local cid = exports.vibe_api:GetCitizenId(source)
    return exports.vibe_api:LoadPlayerMeta(cid)
end)

RegisterNetEvent('vibe_permits:server:showClosest', function()
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
        exports.vibe_api:Notify(src, 'Permis', 'Personne à proximité.', 'error')
        return
    end
    local cid = exports.vibe_api:GetCitizenId(src)
    local meta = exports.vibe_api:LoadPlayerMeta(cid)
    TriggerClientEvent('vibe_permits:client:show', closest, exports.vibe_api:GetCharName(src), meta.permits or {})
    exports.vibe_api:Notify(src, 'Permis', 'Tu montres tes permis.', 'inform')
end)
