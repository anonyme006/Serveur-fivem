SkyDS = SkyDS or {}
SkyDS.DB = SkyDS.DB or {}

local SCHEMA = [[
CREATE TABLE IF NOT EXISTS `sky_ds_exams` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `school_id` VARCHAR(64) NOT NULL,
  `category` VARCHAR(32) NOT NULL,
  `exam_type` ENUM('theory','practical') NOT NULL,
  `passed` TINYINT(1) NOT NULL DEFAULT 0,
  `score` INT NOT NULL DEFAULT 0,
  `max_score` INT NOT NULL DEFAULT 100,
  `errors_json` LONGTEXT NULL,
  `duration_seconds` INT NULL,
  `paid_amount` INT NOT NULL DEFAULT 0,
  `payment_method` VARCHAR(16) NULL,
  `document_id` VARCHAR(64) NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_sky_ds_exams_citizen` (`citizenid`),
  KEY `idx_sky_ds_exams_cat` (`category`),
  KEY `idx_sky_ds_exams_type` (`exam_type`),
  KEY `idx_sky_ds_exams_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sky_ds_theory_passes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `category` VARCHAR(32) NOT NULL,
  `score_percent` INT NOT NULL,
  `passed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_sky_ds_theory` (`citizenid`, `category`),
  KEY `idx_sky_ds_theory_citizen` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sky_ds_licenses` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `category` VARCHAR(32) NOT NULL,
  `document_id` VARCHAR(64) NOT NULL,
  `status` ENUM('valid','suspended','revoked') NOT NULL DEFAULT 'valid',
  `points` INT NOT NULL DEFAULT 12,
  `max_points` INT NOT NULL DEFAULT 12,
  `issued_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_sky_ds_license` (`citizenid`, `category`),
  UNIQUE KEY `uq_sky_ds_document` (`document_id`),
  KEY `idx_sky_ds_lic_citizen` (`citizenid`),
  KEY `idx_sky_ds_lic_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sky_ds_points_history` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `category` VARCHAR(32) NOT NULL,
  `action` VARCHAR(32) NOT NULL,
  `infraction` VARCHAR(64) NULL,
  `points_delta` INT NOT NULL,
  `points_before` INT NOT NULL,
  `points_after` INT NOT NULL,
  `reason` VARCHAR(255) NOT NULL,
  `actor_citizenid` VARCHAR(50) NULL,
  `actor_name` VARCHAR(100) NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_sky_ds_ph_citizen` (`citizenid`),
  KEY `idx_sky_ds_ph_category` (`category`),
  KEY `idx_sky_ds_ph_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sky_ds_retakes` (
  `citizenid` VARCHAR(50) NOT NULL,
  `category` VARCHAR(32) NOT NULL,
  `exam_type` ENUM('theory','practical') NOT NULL,
  `available_at` INT NOT NULL,
  PRIMARY KEY (`citizenid`, `category`, `exam_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sky_ds_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NULL,
  `actor_citizenid` VARCHAR(50) NULL,
  `action` VARCHAR(64) NOT NULL,
  `details` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_sky_ds_logs_action` (`action`),
  KEY `idx_sky_ds_logs_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sky_ds_stats` (
  `citizenid` VARCHAR(50) NOT NULL,
  `theory_attempts` INT NOT NULL DEFAULT 0,
  `theory_passes` INT NOT NULL DEFAULT 0,
  `practical_attempts` INT NOT NULL DEFAULT 0,
  `practical_passes` INT NOT NULL DEFAULT 0,
  `licenses_earned` INT NOT NULL DEFAULT 0,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
]]

function SkyDS.DB.Init()
    for statement in SCHEMA:gmatch('([^;]+);') do
        local sql = statement:match('^%s*(.-)%s*$')
        if sql and sql ~= '' then
            MySQL.query.await(sql)
        end
    end
    SkyDS.Debug('Database schema ensured')
end

function SkyDS.DB.Log(citizenid, actorCitizenid, action, details)
    MySQL.insert.await(
        'INSERT INTO sky_ds_logs (citizenid, actor_citizenid, action, details) VALUES (?, ?, ?, ?)',
        { citizenid, actorCitizenid, action, details and json.encode(details) or nil }
    )
end

function SkyDS.DB.InsertExam(data)
    return MySQL.insert.await([[
        INSERT INTO sky_ds_exams
        (citizenid, school_id, category, exam_type, passed, score, max_score, errors_json, duration_seconds, paid_amount, payment_method, document_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.citizenid,
        data.school_id,
        data.category,
        data.exam_type,
        data.passed and 1 or 0,
        data.score or 0,
        data.max_score or 100,
        data.errors and json.encode(data.errors) or nil,
        data.duration_seconds,
        data.paid_amount or 0,
        data.payment_method,
        data.document_id,
    })
end

function SkyDS.DB.SetTheoryPass(citizenid, category, scorePercent)
    MySQL.insert.await([[
        INSERT INTO sky_ds_theory_passes (citizenid, category, score_percent)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE score_percent = VALUES(score_percent), passed_at = CURRENT_TIMESTAMP
    ]], { citizenid, category, scorePercent })
end

function SkyDS.DB.HasTheoryPass(citizenid, category)
    local row = MySQL.single.await(
        'SELECT id FROM sky_ds_theory_passes WHERE citizenid = ? AND category = ? LIMIT 1',
        { citizenid, category }
    )
    return row ~= nil
end

function SkyDS.DB.GetExamHistory(citizenid, limit)
    return MySQL.query.await(
        'SELECT * FROM sky_ds_exams WHERE citizenid = ? ORDER BY created_at DESC LIMIT ?',
        { citizenid, limit or 25 }
    ) or {}
end

function SkyDS.DB.SetRetake(citizenid, category, examType, availableAt)
    MySQL.insert.await([[
        INSERT INTO sky_ds_retakes (citizenid, category, exam_type, available_at)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE available_at = VALUES(available_at)
    ]], { citizenid, category, examType, availableAt })
end

function SkyDS.DB.GetRetake(citizenid, category, examType)
    local row = MySQL.single.await(
        'SELECT available_at FROM sky_ds_retakes WHERE citizenid = ? AND category = ? AND exam_type = ?',
        { citizenid, category, examType }
    )
    return row and tonumber(row.available_at) or 0
end

function SkyDS.DB.ClearRetake(citizenid, category, examType)
    MySQL.update.await(
        'DELETE FROM sky_ds_retakes WHERE citizenid = ? AND category = ? AND exam_type = ?',
        { citizenid, category, examType }
    )
end

function SkyDS.DB.UpsertLicense(citizenid, category, documentId, status, points, maxPoints)
    MySQL.insert.await([[
        INSERT INTO sky_ds_licenses (citizenid, category, document_id, status, points, max_points)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          document_id = VALUES(document_id),
          status = VALUES(status),
          points = VALUES(points),
          max_points = VALUES(max_points)
    ]], { citizenid, category, documentId, status, points, maxPoints })
end

function SkyDS.DB.GetLicense(citizenid, category)
    return MySQL.single.await(
        'SELECT * FROM sky_ds_licenses WHERE citizenid = ? AND category = ? LIMIT 1',
        { citizenid, category }
    )
end

function SkyDS.DB.GetLicenses(citizenid)
    return MySQL.query.await(
        'SELECT * FROM sky_ds_licenses WHERE citizenid = ? ORDER BY category ASC',
        { citizenid }
    ) or {}
end

function SkyDS.DB.UpdateLicensePoints(citizenid, category, points, status)
    MySQL.update.await(
        'UPDATE sky_ds_licenses SET points = ?, status = ? WHERE citizenid = ? AND category = ?',
        { points, status, citizenid, category }
    )
end

function SkyDS.DB.InsertPointsHistory(data)
    return MySQL.insert.await([[
        INSERT INTO sky_ds_points_history
        (citizenid, category, action, infraction, points_delta, points_before, points_after, reason, actor_citizenid, actor_name)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.citizenid,
        data.category,
        data.action,
        data.infraction,
        data.points_delta,
        data.points_before,
        data.points_after,
        data.reason,
        data.actor_citizenid,
        data.actor_name,
    })
end

function SkyDS.DB.GetPointsHistory(citizenid, limit)
    return MySQL.query.await(
        'SELECT * FROM sky_ds_points_history WHERE citizenid = ? ORDER BY created_at DESC LIMIT ?',
        { citizenid, limit or 40 }
    ) or {}
end

function SkyDS.DB.BumpStats(citizenid, field)
    local allowed = {
        theory_attempts = true,
        theory_passes = true,
        practical_attempts = true,
        practical_passes = true,
        licenses_earned = true,
    }
    if not allowed[field] then return end
    MySQL.insert.await(([[
        INSERT INTO sky_ds_stats (citizenid, %s) VALUES (?, 1)
        ON DUPLICATE KEY UPDATE %s = %s + 1
    ]]):format(field, field, field), { citizenid })
end

function SkyDS.DB.GetStats(citizenid)
    return MySQL.single.await('SELECT * FROM sky_ds_stats WHERE citizenid = ?', { citizenid })
end

function SkyDS.DB.GetGlobalStats()
    local exams = MySQL.single.await([[
        SELECT
          COUNT(*) AS total_exams,
          SUM(CASE WHEN exam_type = 'theory' AND passed = 1 THEN 1 ELSE 0 END) AS theory_passes,
          SUM(CASE WHEN exam_type = 'practical' AND passed = 1 THEN 1 ELSE 0 END) AS practical_passes,
          SUM(CASE WHEN passed = 0 THEN 1 ELSE 0 END) AS failures
        FROM sky_ds_exams
    ]]) or {}
    local licenses = MySQL.scalar.await('SELECT COUNT(*) FROM sky_ds_licenses WHERE status = ?', { 'valid' }) or 0
    local active = 0
    for _ in pairs(SkyDS.ActiveExams or {}) do active = active + 1 end
    return {
        totalExams = tonumber(exams.total_exams) or 0,
        theoryPasses = tonumber(exams.theory_passes) or 0,
        practicalPasses = tonumber(exams.practical_passes) or 0,
        failures = tonumber(exams.failures) or 0,
        validLicenses = tonumber(licenses) or 0,
        activeExams = active,
    }
end

function SkyDS.DB.GetRecentExams(limit)
    return MySQL.query.await(
        'SELECT * FROM sky_ds_exams ORDER BY created_at DESC LIMIT ?',
        { limit or 50 }
    ) or {}
end

function SkyDS.DB.GetLogs(limit)
    return MySQL.query.await(
        'SELECT * FROM sky_ds_logs ORDER BY created_at DESC LIMIT ?',
        { limit or 50 }
    ) or {}
end

function SkyDS.DB.NewDocumentId(category)
    local suffix = tostring(math.random(100000, 999999))
    return ('DMV-%s-%s-%s'):format(string.upper(category or 'X'), os.time(), suffix)
end
