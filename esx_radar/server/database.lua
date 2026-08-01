---@diagnostic disable: undefined-global
--[[
    server/database.lua
    Accès MySQL (oxmysql) — radars + historique des flashes.
]]

RadarDB = {}

--- Crée les tables si absentes (sécurité au démarrage)
function RadarDB.EnsureTables()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `radar_list` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `name` VARCHAR(64) NOT NULL,
            `road_name` VARCHAR(128) NOT NULL,
            `speed_limit` INT UNSIGNED NOT NULL DEFAULT 50,
            `tolerance` INT UNSIGNED NOT NULL DEFAULT 5,
            `detection_distance` FLOAT NOT NULL DEFAULT 20.0,
            `direction` ENUM('both', 'forward', 'backward') NOT NULL DEFAULT 'both',
            `x` FLOAT NOT NULL,
            `y` FLOAT NOT NULL,
            `z` FLOAT NOT NULL,
            `heading` FLOAT NOT NULL DEFAULT 0.0,
            `enabled` TINYINT(1) NOT NULL DEFAULT 1,
            `created_by` VARCHAR(64) DEFAULT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            INDEX `idx_enabled` (`enabled`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `radar_flashes` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `identifier` VARCHAR(64) NOT NULL,
            `player_name` VARCHAR(128) NOT NULL,
            `plate` VARCHAR(16) NOT NULL,
            `vehicle_model` VARCHAR(64) NOT NULL,
            `position` VARCHAR(128) NOT NULL,
            `radar_id` INT UNSIGNED DEFAULT NULL,
            `radar_name` VARCHAR(64) NOT NULL,
            `road_name` VARCHAR(128) NOT NULL,
            `speed` INT UNSIGNED NOT NULL,
            `retained_speed` INT UNSIGNED NOT NULL,
            `speed_limit` INT UNSIGNED NOT NULL,
            `fine_amount` INT UNSIGNED NOT NULL DEFAULT 0,
            `authorized` TINYINT(1) NOT NULL DEFAULT 0,
            `flashed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            INDEX `idx_identifier` (`identifier`),
            INDEX `idx_plate` (`plate`),
            INDEX `idx_radar_id` (`radar_id`),
            INDEX `idx_flashed_at` (`flashed_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end

--- Charge tous les radars
---@return table[]
function RadarDB.GetAllRadars()
    return MySQL.query.await('SELECT * FROM radar_list ORDER BY id ASC') or {}
end

--- Charge un radar par id
---@param id number
---@return table|nil
function RadarDB.GetRadar(id)
    return MySQL.single.await('SELECT * FROM radar_list WHERE id = ?', { id })
end

--- Insert un radar
---@param data table
---@return number|nil insertId
function RadarDB.InsertRadar(data)
    return MySQL.insert.await([[
        INSERT INTO radar_list
            (name, road_name, speed_limit, tolerance, detection_distance, direction, x, y, z, heading, enabled, created_by)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?)
    ]], {
        data.name,
        data.road_name,
        data.speed_limit,
        data.tolerance,
        data.detection_distance,
        data.direction,
        data.x,
        data.y,
        data.z,
        data.heading,
        data.created_by,
    })
end

--- Met à jour un radar (champs éditables)
---@param data table
---@return number affected
function RadarDB.UpdateRadar(data)
    return MySQL.update.await([[
        UPDATE radar_list SET
            name = ?,
            road_name = ?,
            speed_limit = ?,
            tolerance = ?,
            detection_distance = ?,
            direction = ?
        WHERE id = ?
    ]], {
        data.name,
        data.road_name,
        data.speed_limit,
        data.tolerance,
        data.detection_distance,
        data.direction,
        data.id,
    })
end

--- Active / désactive
---@param id number
---@param enabled boolean
---@return number
function RadarDB.SetEnabled(id, enabled)
    return MySQL.update.await('UPDATE radar_list SET enabled = ? WHERE id = ?', {
        enabled and 1 or 0,
        id,
    })
end

--- Supprime un radar
---@param id number
---@return number
function RadarDB.DeleteRadar(id)
    return MySQL.update.await('DELETE FROM radar_list WHERE id = ?', { id })
end

--- Enregistre un flash
---@param data table
---@return number|nil
function RadarDB.InsertFlash(data)
    return MySQL.insert.await([[
        INSERT INTO radar_flashes
            (identifier, player_name, plate, vehicle_model, position, radar_id,
             radar_name, road_name, speed, retained_speed, speed_limit, fine_amount, authorized)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.identifier,
        data.player_name,
        data.plate,
        data.vehicle_model,
        data.position,
        data.radar_id,
        data.radar_name,
        data.road_name,
        data.speed,
        data.retained_speed,
        data.speed_limit,
        data.fine_amount,
        data.authorized and 1 or 0,
    })
end
