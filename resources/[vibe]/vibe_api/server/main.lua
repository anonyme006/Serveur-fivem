local function dbg(...)
    if not Config.Debug then return end
    local parts = {}
    for i = 1, select('#', ...) do parts[#parts+1] = tostring(select(i, ...)) end
    print(('[vibe_api] %s'):format(table.concat(parts, ' ')))
end

local function getPlayer(src)
    return exports.qbx_core:GetPlayer(src)
end

local function notify(src, title, description, nType)
    TriggerClientEvent('ox_lib:notify', src, {
        title = title or 'Vibe',
        description = description or '',
        type = nType or 'inform',
    })
end

local function getJob(src)
    local player = getPlayer(src)
    if not player then return nil end
    return player.PlayerData.job
end

local function isOnDuty(src)
    local job = getJob(src)
    return job and job.onduty == true
end

local function hasPoliceJob(src, requireDuty)
    local job = getJob(src)
    if not job or not VibeJobs.IsPolice(job.name) then return false end
    if requireDuty ~= false and not job.onduty then return false end
    return true
end

local function addMoney(src, account, amount, reason)
    local player = getPlayer(src)
    if not player then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    player.Functions.AddMoney(account or 'cash', amount, reason or 'vibe')
    return true
end

local function removeMoney(src, account, amount, reason)
    local player = getPlayer(src)
    if not player then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    return player.Functions.RemoveMoney(account or 'cash', amount, reason or 'vibe')
end

local function getMoney(src, account)
    local player = getPlayer(src)
    if not player then return 0 end
    return player.Functions.GetMoney(account or 'cash') or 0
end

local function getCitizenId(src)
    local player = getPlayer(src)
    return player and player.PlayerData.citizenid or nil
end

local function getCharName(src)
    local player = getPlayer(src)
    if not player then return 'Inconnu' end
    local c = player.PlayerData.charinfo or {}
    return (('%s %s'):format(c.firstname or 'John', c.lastname or 'Doe'))
end

local function distCheck(src, coords, maxDist)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    local pcoords = GetEntityCoords(ped)
    return #(pcoords - vector3(coords.x, coords.y, coords.z)) <= (maxDist or 5.0)
end

exports('GetPlayer', getPlayer)
exports('Notify', notify)
exports('GetJob', getJob)
exports('IsOnDuty', isOnDuty)
exports('HasPoliceJob', hasPoliceJob)
exports('AddMoney', addMoney)
exports('RemoveMoney', removeMoney)
exports('GetMoney', getMoney)
exports('GetCitizenId', getCitizenId)
exports('GetCharName', getCharName)
exports('DistCheck', distCheck)

function SavePlayerMeta(citizenid, stats)
    MySQL.insert.await([[
        INSERT INTO vibe_player_meta (citizenid, stats)
        VALUES (?, ?)
        ON DUPLICATE KEY UPDATE stats = VALUES(stats)
    ]], { citizenid, json.encode(stats or {}) })
end

function LoadPlayerMeta(citizenid)
    local row = MySQL.single.await('SELECT stats, permits FROM vibe_player_meta WHERE citizenid = ?', { citizenid })
    if not row then return { stats = {}, permits = {} } end
    return {
        stats = row.stats and json.decode(row.stats) or {},
        permits = row.permits and json.decode(row.permits) or {},
    }
end

exports('SavePlayerMeta', SavePlayerMeta)
exports('LoadPlayerMeta', LoadPlayerMeta)

lib.callback.register('vibe_api:server:getCitizenId', function(source)
    return getCitizenId(source)
end)

lib.callback.register('vibe_api:server:getJob', function(source)
    return getJob(source)
end)

lib.callback.register('vibe_api:server:isPolice', function(source, requireDuty)
    return hasPoliceJob(source, requireDuty)
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    dbg('API vibe démarrée')
end)
