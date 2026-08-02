RegisterNetEvent('rr_spawnselector:server:selected', function(spawnId)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    print(('[rr_spawnselector] %s a choisi %s'):format(player.PlayerData.citizenid, tostring(spawnId)))
end)
