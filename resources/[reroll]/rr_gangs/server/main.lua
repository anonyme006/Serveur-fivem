local owners = {}

CreateThread(function()
    for _, t in ipairs(Config.Territories) do
        owners[t.id] = t.owner
    end
end)

RegisterNetEvent('rr_gangs:server:capture', function(territoryId)
    local src = source
    local player = exports.rr_api:GetPlayer(src)
    if not player then return end
    local gang = player.PlayerData.gang and player.PlayerData.gang.name
    if not gang or gang == 'none' or not Config.Gangs[gang] then
        exports.rr_api:Notify(src, 'Gangs', 'Tu dois être dans un gang.', 'error')
        return
    end
    local territory
    for _, t in ipairs(Config.Territories) do
        if t.id == territoryId then territory = t break end
    end
    if not territory then return end
    if not exports.rr_api:DistCheck(src, territory.coords, territory.radius) then return end
    owners[territoryId] = gang
    territory.owner = gang
    exports.rr_api:Notify(src, 'Gangs', ('Territoire capturé par %s'):format(Config.Gangs[gang].label), 'success')
    TriggerClientEvent('ox_lib:notify', -1, {
        title = 'Gangs',
        description = ('%s contrôle maintenant %s'):format(Config.Gangs[gang].label, territory.label),
        type = 'inform',
    })
end)
