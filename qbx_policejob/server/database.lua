--[[--------------------------------------------------------------------------
    Couche base de données — oxmysql (PHASE 1 : ensure tables)
---------------------------------------------------------------------------]]

PoliceDB = PoliceDB or {}

local SCHEMA = [[
CREATE TABLE IF NOT EXISTS `police_fines` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `officer_citizenid` VARCHAR(50) NOT NULL,
    `department` VARCHAR(50) NOT NULL,
    `category` VARCHAR(50) NOT NULL,
    `fine_key` VARCHAR(50) NOT NULL,
    `label` VARCHAR(120) NOT NULL,
    `amount` INT NOT NULL,
    `paid` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_police_fines_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `police_prison` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `officer_citizenid` VARCHAR(50) DEFAULT NULL,
    `department` VARCHAR(50) DEFAULT NULL,
    `minutes` INT NOT NULL,
    `release_at` TIMESTAMP NOT NULL,
    `active` TINYINT(1) NOT NULL DEFAULT 1,
    `reason` VARCHAR(255) DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_police_prison_citizen` (`citizenid`),
    KEY `idx_police_prison_active` (`citizenid`, `active`),
    KEY `idx_police_prison_release` (`release_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `police_community_service` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `officer_citizenid` VARCHAR(50) DEFAULT NULL,
    `tasks_remaining` INT NOT NULL,
    `tasks_total` INT NOT NULL,
    `active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_police_cs_citizen` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `police_incidents` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `department` VARCHAR(50) NOT NULL,
    `officer_citizenid` VARCHAR(50) NOT NULL,
    `target_citizenid` VARCHAR(50) DEFAULT NULL,
    `type` VARCHAR(50) NOT NULL,
    `payload` LONGTEXT DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_police_incidents_type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `police_objects` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `department` VARCHAR(50) NOT NULL,
    `owner_citizenid` VARCHAR(50) NOT NULL,
    `object_key` VARCHAR(50) NOT NULL,
    `model` VARCHAR(80) NOT NULL,
    `coords` VARCHAR(120) NOT NULL,
    `heading` FLOAT NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `police_gsr` (
    `citizenid` VARCHAR(50) NOT NULL,
    `positive` TINYINT(1) NOT NULL DEFAULT 0,
    `expires_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `police_confiscations` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `officer_citizenid` VARCHAR(50) NOT NULL,
    `target_citizenid` VARCHAR(50) NOT NULL,
    `department` VARCHAR(50) NOT NULL,
    `item_type` VARCHAR(30) NOT NULL,
    `item_name` VARCHAR(80) DEFAULT NULL,
    `amount` INT NOT NULL DEFAULT 0,
    `metadata` LONGTEXT DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_police_confisc_target` (`target_citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]]

function PoliceDB.EnsureSchema()
    local statements = {}
    for statement in SCHEMA:gmatch('CREATE TABLE.-;') do
        statements[#statements + 1] = statement
    end

    for i = 1, #statements do
        local ok, err = pcall(function()
            MySQL.query.await(statements[i])
        end)
        if not ok then
            print(('[qbx_policejob] SQL error (%s): %s'):format(i, err))
        end
    end

    Police.Debug(('Schema ensure done (%s tables)'):format(#statements))
end

---@param citizenid string
---@param positive boolean
---@param expiresAt string|nil mysql datetime
function PoliceDB.UpsertGsr(citizenid, positive, expiresAt)
    MySQL.insert.await([[
        INSERT INTO police_gsr (citizenid, positive, expires_at)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE positive = VALUES(positive), expires_at = VALUES(expires_at)
    ]], { citizenid, positive and 1 or 0, expiresAt })
end

---@param citizenid string
---@return table|nil
function PoliceDB.GetGsr(citizenid)
    return MySQL.single.await('SELECT * FROM police_gsr WHERE citizenid = ? LIMIT 1', { citizenid })
end

---@param data table
---@return number|nil insertId
function PoliceDB.LogIncident(data)
    return MySQL.insert.await([[
        INSERT INTO police_incidents (department, officer_citizenid, target_citizenid, type, payload)
        VALUES (?, ?, ?, ?, ?)
    ]], {
        data.department,
        data.officer_citizenid,
        data.target_citizenid,
        data.type,
        data.payload and json.encode(data.payload) or nil,
    })
end
