local skinned = {}

RegisterNetEvent('rr_hunt:server:skin', function(netId)
    local src = source
    if skinned[netId] then return end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity == 0 then return end
    local coords = GetEntityCoords(entity)
    local ped = GetPlayerPed(src)
    if #(GetEntityCoords(ped) - coords) > 5.0 then return end
    skinned[netId] = true
    exports.ox_inventory:AddItem(src, Config.RewardItem, Config.RewardAmount)
end)
