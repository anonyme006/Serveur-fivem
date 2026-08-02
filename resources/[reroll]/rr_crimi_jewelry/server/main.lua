local active = false
local last = 0
local looted = {}

local function copsOnline()
    local n = 0
    for _, id in pairs(GetPlayers()) do
        if exports.rr_api:HasPoliceJob(tonumber(id), true) then n = n + 1 end
    end
    return n
end

RegisterNetEvent('rr_crimi_jewelry:server:start', function()
    local src = source
    if not exports.rr_api:DistCheck(src, Config.Start, 5.0) then return end
    if active or (os.time() - last) < Config.Cooldown then
        exports.rr_api:Notify(src, 'Bijouterie', 'Indisponible.', 'error')
        return
    end
    if copsOnline() < Config.MinCops then
        exports.rr_api:Notify(src, 'Bijouterie', 'Pas assez de policiers.', 'error')
        return
    end
    active = true
    last = os.time()
    looted = {}
    exports.rr_api:Notify(src, 'Bijouterie', 'Alarme déclenchée — casse les vitrines !', 'inform')
    if GetResourceState('rr_dispatch') == 'started' then
        exports.rr_dispatch:Alert('10-90', 'Braquage bijouterie Vangelico', { x = Config.Start.x, y = Config.Start.y, z = Config.Start.z })
    end
    SetTimeout(10 * 60 * 1000, function()
        active = false
    end)
end)

RegisterNetEvent('rr_crimi_jewelry:server:loot', function(index)
    local src = source
    if not active or looted[index] then return end
    local coords = Config.Vitrines[index]
    if not coords or not exports.rr_api:DistCheck(src, coords, 3.0) then return end
    looted[index] = true
    exports.ox_inventory:AddItem(src, Config.RewardItem, Config.RewardAmount)
end)
