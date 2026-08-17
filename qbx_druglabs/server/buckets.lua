Buckets = {}

local playerLab = {} ---@type table<number, number> source -> labId
local DEFAULT_BUCKET = 0

---@param labId number
---@return number
function Buckets.GetForLab(labId)
    return Config.Labs.bucketBase + labId
end

function Buckets.GetPlayerLab(source)
    return playerLab[source]
end

function Buckets.Enter(source, labId)
    local bucket = Buckets.GetForLab(labId)
    SetPlayerRoutingBucket(source, bucket)
    playerLab[source] = labId
    Player(source).state:set('druglabId', labId, true)
    DrugLabs.Debug('Player', source, 'entered bucket', bucket)
end

function Buckets.Leave(source)
    SetPlayerRoutingBucket(source, DEFAULT_BUCKET)
    playerLab[source] = nil
    Player(source).state:set('druglabId', nil, true)
end

function Buckets.ForceLeave(source, reason)
    if not playerLab[source] then return end
    Buckets.Leave(source)
    TriggerClientEvent(DrugLabs.Events.client.leaveLab, source, reason or 'forced')
end

AddEventHandler('playerDropped', function()
    local src = source
    if playerLab[src] then
        playerLab[src] = nil
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= DrugLabs.Resource then return end
    for src in pairs(playerLab) do
        SetPlayerRoutingBucket(src, DEFAULT_BUCKET)
        Player(src).state:set('druglabId', nil, true)
    end
end)

-- Safety: clear bucket on death / character unload
RegisterNetEvent('QBCore:Server:OnPlayerUnload', function(src)
    src = src or source
    if playerLab[src] then
        Buckets.Leave(src)
    end
end)

RegisterNetEvent('qbx_core:server:playerLoggedOut', function()
    local src = source
    if playerLab[src] then
        Buckets.Leave(src)
    end
end)
