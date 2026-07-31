local cacheStats = {}

local function ensure(src)
    local cid = exports.vibe_api:GetCitizenId(src)
    if not cid then return end
    if not cacheStats[cid] then
        local meta = exports.vibe_api:LoadPlayerMeta(cid)
        cacheStats[cid] = meta.stats or {}
        cacheStats[cid].hunger = cacheStats[cid].hunger or 100
        cacheStats[cid].thirst = cacheStats[cid].thirst or 100
    end
    return cid, cacheStats[cid]
end

local function sync(src)
    local cid, stats = ensure(src)
    if stats then TriggerClientEvent('vibe_playerstats:client:sync', src, stats) end
end

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function(player)
    -- qbx may use different event; also handle playerConnecting style below
end)

RegisterNetEvent('vibe_playerstats:server:add', function(key, amount)
    local src = source
    local cid, stats = ensure(src)
    if not stats or (key ~= 'hunger' and key ~= 'thirst') then return end
    stats[key] = math.min(100, math.max(0, (stats[key] or 0) + (tonumber(amount) or 0)))
    exports.vibe_api:SavePlayerMeta(cid, stats)
    sync(src)
end)

AddEventHandler('playerJoining', function()
    local src = source
    SetTimeout(5000, function() sync(src) end)
end)

CreateThread(function()
    while true do
        Wait(Config.Tick * 1000)
        for _, id in pairs(GetPlayers()) do
            id = tonumber(id)
            local cid, stats = ensure(id)
            if stats then
                stats.hunger = math.max(0, (stats.hunger or 100) - Config.HungerLoss)
                stats.thirst = math.max(0, (stats.thirst or 100) - Config.ThirstLoss)
                if stats.hunger <= Config.DamageBelow or stats.thirst <= Config.DamageBelow then
                    local ped = GetPlayerPed(id)
                    local hp = GetEntityHealth(ped)
                    if hp > 110 then SetEntityHealth(ped, hp - 2) end
                end
                exports.vibe_api:SavePlayerMeta(cid, stats)
                TriggerClientEvent('vibe_playerstats:client:sync', id, stats)
            end
        end
    end
end)
