local function dbg(...)
    if Config.Debug then
        print(('[vibe_api] %s'):format(table.concat({ ... }, ' ')))
    end
end

--- Retourne le joueur Qbox à partir de la source
---@param src number
---@return table|nil
local function getPlayer(src)
    return exports.qbx_core:GetPlayer(src)
end

exports('GetPlayer', getPlayer)

--- Sauvegarde un blob JSON de meta joueur
---@param citizenid string
---@param stats table
function SavePlayerMeta(citizenid, stats)
    MySQL.insert.await([[
        INSERT INTO vibe_player_meta (citizenid, stats)
        VALUES (?, ?)
        ON DUPLICATE KEY UPDATE stats = VALUES(stats)
    ]], { citizenid, json.encode(stats or {}) })
end

exports('SavePlayerMeta', SavePlayerMeta)

lib.callback.register('vibe_api:server:getCitizenId', function(source)
    local player = getPlayer(source)
    if not player then return nil end
    return player.PlayerData.citizenid
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    dbg('démarré — namespace', Config.Namespace)
end)
