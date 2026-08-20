--[[
    Pulse Phone — Accès base de données
]]

Pulse = Pulse or {}
Pulse.Database = {}

function Pulse.Database.Init()
    Pulse.Utils.Debug('Database module ready')
end

---@return string
local function generateNumber()
    local prefix = Config.PhoneNumber.prefix or ''
    local len = Config.PhoneNumber.length
    for _ = 1, 30 do
        local digits = ''
        for i = 1, len do
            digits = digits .. tostring(math.random(0, 9))
        end
        local number = prefix .. digits
        local exists = MySQL.scalar.await('SELECT 1 FROM phone_users WHERE phone_number = ? LIMIT 1', { number })
        if not exists then
            return number
        end
    end
    error('[pulse-phone] Unable to generate unique phone number')
end

---@param citizenid string
---@param _player table|nil
---@return table|nil
function Pulse.Database.EnsureUser(citizenid, _player)
    local row = MySQL.single.await('SELECT * FROM phone_users WHERE citizenid = ? LIMIT 1', { citizenid })
    if row then return row end

    local number = generateNumber()
    MySQL.insert.await(
        'INSERT INTO phone_users (citizenid, phone_number, wallpaper, theme) VALUES (?, ?, ?, ?)',
        { citizenid, number, Config.DefaultWallpaper, Config.DefaultTheme }
    )
    return MySQL.single.await('SELECT * FROM phone_users WHERE citizenid = ? LIMIT 1', { citizenid })
end

---@param citizenid string
---@return table|nil
function Pulse.Database.GetUser(citizenid)
    return MySQL.single.await('SELECT * FROM phone_users WHERE citizenid = ? LIMIT 1', { citizenid })
end

---@param number string
---@return table|nil
function Pulse.Database.GetUserByNumber(number)
    number = Pulse.Utils.NormalizeNumber(number)
    if not number then return nil end
    return MySQL.single.await('SELECT * FROM phone_users WHERE phone_number = ? LIMIT 1', { number })
end

function Pulse.Database.MarkNotificationRead(citizenid, notifId)
    MySQL.update.await(
        'UPDATE phone_notifications SET is_read = 1 WHERE id = ? AND citizenid = ?',
        { notifId, citizenid }
    )
end

RegisterNetEvent('pulse-phone:server:markNotificationRead', function(notifId)
    local src = source
    local citizenid = Pulse.Server.GetCitizenId(src)
    if not citizenid or type(notifId) ~= 'number' then return end
    Pulse.Database.MarkNotificationRead(citizenid, notifId)
end)
