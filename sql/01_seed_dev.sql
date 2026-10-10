-- Seed de développement — simule un extrait Qbox + Renewed-Banking
-- À utiliser UNIQUEMENT en local (docker-compose). Ne pas appliquer en prod.

CREATE TABLE IF NOT EXISTS `players` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `userId` INT UNSIGNED DEFAULT NULL,
  `citizenid` varchar(50) NOT NULL,
  `cid` int(11) DEFAULT NULL,
  `license` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `money` text NOT NULL,
  `charinfo` text DEFAULT NULL,
  `job` text NOT NULL,
  `gang` text DEFAULT NULL,
  `position` text NOT NULL,
  `metadata` text NOT NULL,
  `inventory` longtext DEFAULT NULL,
  `phone_number` VARCHAR(20) DEFAULT NULL,
  `last_updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `last_logged_out` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`citizenid`),
  KEY `id` (`id`),
  KEY `license` (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `player_vehicles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `license` varchar(50) DEFAULT NULL,
  `citizenid` varchar(50) DEFAULT NULL,
  `vehicle` varchar(50) DEFAULT NULL,
  `hash` varchar(50) DEFAULT NULL,
  `mods` longtext DEFAULT NULL,
  `plate` varchar(15) NOT NULL,
  `fakeplate` varchar(50) DEFAULT NULL,
  `garage` varchar(50) DEFAULT NULL,
  `fuel` int(11) DEFAULT 100,
  `engine` float DEFAULT 1000,
  `body` float DEFAULT 1000,
  `state` int(11) DEFAULT 1,
  `depotprice` int(11) NOT NULL DEFAULT 0,
  `drivingdistance` int(50) DEFAULT NULL,
  `status` text DEFAULT NULL,
  `coords` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `plate` (`plate`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `player_transactions` (
  `id` varchar(50) NOT NULL,
  `isFrozen` int(11) DEFAULT 0,
  `transactions` longtext DEFAULT '[]',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `bank_accounts_new` (
  `id` varchar(50) NOT NULL,
  `amount` int(11) DEFAULT 0,
  `transactions` longtext DEFAULT '[]',
  `auth` longtext DEFAULT '[]',
  `isFrozen` int(11) DEFAULT 0,
  `creator` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rp_invoices` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `invoice_id` VARCHAR(32) NOT NULL,
  `sender_cid` VARCHAR(50) NOT NULL,
  `target_cid` VARCHAR(50) NOT NULL,
  `society` VARCHAR(50) DEFAULT NULL,
  `amount` INT UNSIGNED NOT NULL,
  `reason` VARCHAR(180) NOT NULL,
  `status` ENUM('pending','paid','refused','expired') NOT NULL DEFAULT 'pending',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `paid_at` TIMESTAMP NULL DEFAULT NULL,
  `expires_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_invoice_id` (`invoice_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `players` (`userId`, `citizenid`, `cid`, `license`, `name`, `money`, `charinfo`, `job`, `gang`, `position`, `metadata`, `phone_number`, `last_logged_out`)
VALUES
(1, 'SER10001', 1, 'license:devplayer001', 'Alex Dev',
 '{"cash":2450,"bank":87500,"crypto":0}',
 '{"firstname":"Alex","lastname":"Moreau","birthdate":"1996-04-12","nationality":"FR","cid":1,"gender":0,"phone":"555-0101"}',
 '{"name":"police","label":"LSPD","payment":250,"onduty":true,"isboss":false,"grade":{"name":"Officer","level":2}}',
 '{"name":"none","label":"Aucun","grade":{"name":"none","level":0}}',
 '{"x":0,"y":0,"z":0,"w":0}',
 '{"playtime":184320,"health":200,"armor":0,"hunger":80,"thirst":75}',
 '555-0101', DATE_SUB(NOW(), INTERVAL 2 HOUR)),
(1, 'SER10002', 2, 'license:devplayer001', 'Alex Dev',
 '{"cash":120,"bank":3200,"crypto":0}',
 '{"firstname":"Nora","lastname":"Vidal","birthdate":"1999-11-03","nationality":"FR","cid":2,"gender":1,"phone":"555-0102"}',
 '{"name":"unemployed","label":"Civilian","payment":50,"onduty":false,"isboss":false,"grade":{"name":"Freelancer","level":0}}',
 '{"name":"none","label":"Aucun","grade":{"name":"none","level":0}}',
 '{"x":0,"y":0,"z":0,"w":0}',
 '{"playtime":43200,"health":200,"armor":0}',
 '555-0102', DATE_SUB(NOW(), INTERVAL 1 DAY));

INSERT INTO `player_vehicles` (`license`, `citizenid`, `vehicle`, `hash`, `mods`, `plate`, `garage`, `fuel`, `engine`, `body`, `state`, `drivingdistance`)
VALUES
('license:devplayer001', 'SER10001', 'sultan', '-123456', '{}', 'SER 001', 'pillboxgarage', 78, 920, 880, 1, 15400),
('license:devplayer001', 'SER10001', 'police3', '-654321', '{}', 'LSPD 12', 'mrpd', 55, 1000, 970, 0, 8200),
('license:devplayer001', 'SER10001', 'elegy', '123789', '{}', 'SER 777', 'impound', 12, 410, 300, 2, 42100),
('license:devplayer001', 'SER10002', 'blista', '987654', '{}', 'NORA 9', 'legionsquare', 90, 990, 995, 1, 2100);

INSERT INTO `player_transactions` (`id`, `isFrozen`, `transactions`)
VALUES
('SER10001', 0, '[
  {"amount":2500,"message":"Salaire LSPD","trans_id":"tx-1001","receiver":"Alex Moreau","receiver_cid":"SER10001","sender":"LSPD","sender_cid":"police","type":"deposit","time":1736200000},
  {"amount":450,"message":"Achat Fast Food","trans_id":"tx-1002","receiver":"Burger Shot","receiver_cid":"burgershot","sender":"Alex Moreau","sender_cid":"SER10001","type":"withdraw","time":1736210000},
  {"amount":12000,"message":"Virement concessionnaire","trans_id":"tx-1003","receiver":"PDM","receiver_cid":"cardealer","sender":"Alex Moreau","sender_cid":"SER10001","type":"withdraw","time":1736220000}
]');

INSERT INTO `rp_invoices` (`invoice_id`, `sender_cid`, `target_cid`, `society`, `amount`, `reason`, `status`)
VALUES
('INV-DEV-1', 'SER10001', 'SER10002', 'police', 500, 'Amende excès de vitesse', 'pending');

INSERT INTO `portal_accounts` (`discord_id`, `discord_username`, `discord_avatar`, `role`)
VALUES
('100000000000000001', 'alex.dev', 'abcd', 'admin'),
('100000000000000099', 'staff.serenity', NULL, 'moderator');

INSERT INTO `portal_account_links` (`account_id`, `license`, `user_id`, `linked_citizenid`)
VALUES
(1, 'license:devplayer001', 1, 'SER10001');

INSERT INTO `portal_notifications` (`citizenid`, `title`, `body`, `level`)
VALUES
('SER10001', 'Portail lié', 'Votre compte Discord est désormais lié.', 'success'),
('SER10001', 'Fourrière', 'Votre Elegy a été mise en fourrière.', 'warning');

INSERT INTO `portal_activities` (`citizenid`, `category`, `summary`)
VALUES
('SER10001', 'login', 'Connexion au portail'),
('SER10001', 'vehicle', 'Consultation garage'),
('SER10001', 'bank', 'Consultation compte bancaire');

INSERT INTO `portal_playtime_sessions` (`citizenid`, `license`, `started_at`, `ended_at`, `seconds`, `session_token`)
VALUES
('SER10001', 'license:devplayer001', DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 3 DAY) + INTERVAL 2 HOUR, 7200, REPEAT('a', 64)),
('SER10001', 'license:devplayer001', DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_SUB(NOW(), INTERVAL 1 DAY) + INTERVAL 90 MINUTE, 5400, REPEAT('b', 64));
