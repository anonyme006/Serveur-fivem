-- Sky Driving School — install schema
-- Character-persistent IDs (citizenid). Safe to re-run (IF NOT EXISTS).

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
