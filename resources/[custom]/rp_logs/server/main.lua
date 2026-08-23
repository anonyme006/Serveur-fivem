local function getIdentifiers(src)
    if not src or src < 1 then return {} end
    local data = {
        name = GetPlayerName(src) or 'unknown',
        identifiers = {},
    }
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id then
            data.identifiers[#data.identifiers + 1] = id
            if id:find('license:') then data.license = id end
            if id:find('discord:') then data.discord = id end
        end
    end
    return data
end

local function sendDiscord(category, title, description, fields, color)
    if not Config.DiscordLogs then return end
    local url = Config.Webhooks[category] or Config.Webhooks.default
    if not url or url == '' then return end
    local embed = {
        {
            title = title,
            description = description,
            color = color or Config.Colors[category] or Config.Colors.default,
            fields = fields or {},
            footer = { text = os.date('%d/%m/%Y %H:%M:%S') },
        }
    }
    PerformHttpRequest(url, function() end, 'POST', json.encode({
        username = 'RP Logs',
        embeds = embed,
    }), { ['Content-Type'] = 'application/json' })
end

---@param category string
---@param source number|nil
---@param message string
---@param meta? table
local function Log(category, source, message, meta)
    category = category or 'default'
    meta = meta or {}
    local info = source and getIdentifiers(source) or {}
    local citizenid = meta.citizenid
    if source and not citizenid then
        local player = exports.qbx_core:GetPlayer(source)
        if player then citizenid = player.PlayerData.citizenid end
    end

    if Config.SaveToDatabase then
        MySQL.insert.await(
            'INSERT INTO rp_logs (category, citizenid, player_name, license, message, meta) VALUES (?, ?, ?, ?, ?, ?)',
            {
                category,
                citizenid,
                info.name,
                info.license,
                message,
                json.encode(meta),
            }
        )
    end

    local fields = {
        { name = 'Joueur', value = info.name or 'N/A', inline = true },
        { name = 'CitizenID', value = citizenid or 'N/A', inline = true },
        { name = 'License', value = info.license or 'N/A', inline = false },
    }
    for k, v in pairs(meta) do
        if k ~= 'citizenid' then
            fields[#fields + 1] = { name = tostring(k), value = tostring(v), inline = true }
        end
    end

    sendDiscord(category, ('[%s] %s'):format(category:upper(), message), message, fields)
    if Config.Debug then
        print(('[rp_logs] [%s] %s'):format(category, message))
    end
end

exports('Log', Log)

RegisterNetEvent('rp_logs:server:log', function(category, message, meta)
    local src = source
    if type(category) ~= 'string' or type(message) ~= 'string' then return end
    -- Les clients ne peuvent logger que des catégories non-admin
    local blocked = { admin = true, sanctions = true }
    if blocked[category] then return end
    if not exports.rp_core:RateLimit(src, 'log', 2000) then return end
    Log(category, src, message, meta)
end)

MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `rp_logs` (
          `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
          `category` VARCHAR(32) NOT NULL,
          `citizenid` VARCHAR(50) DEFAULT NULL,
          `player_name` VARCHAR(128) DEFAULT NULL,
          `license` VARCHAR(80) DEFAULT NULL,
          `message` TEXT NOT NULL,
          `meta` LONGTEXT DEFAULT NULL,
          `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`),
          KEY `idx_rp_logs_category` (`category`),
          KEY `idx_rp_logs_citizenid` (`citizenid`),
          KEY `idx_rp_logs_created` (`created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end)

print('[rp_logs] ready')
