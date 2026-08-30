-- qbx-duty — historique optionnel du temps de service

CREATE TABLE IF NOT EXISTS `duty_logs` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(60) NOT NULL,
  `job` VARCHAR(50) NOT NULL,
  `grade` INT NOT NULL DEFAULT 0,
  `clock_in` DATETIME NOT NULL,
  `clock_out` DATETIME DEFAULT NULL,
  `duration` INT DEFAULT NULL COMMENT 'secondes',
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`),
  KEY `job` (`job`),
  KEY `clock_in` (`clock_in`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
