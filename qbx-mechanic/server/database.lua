Database = {}

local function ensureMySQL()
    return GetResourceState('oxmysql') == 'started'
end

function Database.IsReady()
    return ensureMySQL()
end

--- Initialise les tables si elles n'existent pas (fichier sql/mechanic.sql recommandé)
function Database.Init()
    if not ensureMySQL() then
        print('[^1qbx-mechanic^0] oxmysql non démarré — importez sql/mechanic.sql manuellement.')
        return false
    end

    Utils.Debug('Database module ready')
    return true
end

---@param mechanicId string
---@param item string
---@return number
function Database.GetStockQuantity(mechanicId, item)
    local row = MySQL.single.await(
        'SELECT quantity FROM mechanic_stock WHERE mechanic_id = ? AND item = ? LIMIT 1',
        { mechanicId, item }
    )
    return row and row.quantity or 0
end

---@param mechanicId string
---@param citizenid string
---@param action string
---@param details table|nil
function Database.InsertLog(mechanicId, citizenid, action, details)
    if not Config.Logs or not Config.Logs.enabled then return end
    if Config.Logs.events and Config.Logs.events[action] == false then return end

    MySQL.insert.await(
        'INSERT INTO mechanic_logs (mechanic_id, citizenid, action, details) VALUES (?, ?, ?, ?)',
        { mechanicId, citizenid, action, Utils.EncodeJson(details) }
    )
end

return Database
