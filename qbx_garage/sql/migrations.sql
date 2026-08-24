-- =========================================================
-- Qbox — migrations utiles si la table existe déjà
-- Exécute uniquement les lignes nécessaires
-- =========================================================

-- Colonnes manquantes fréquentes
ALTER TABLE `player_vehicles`
  ADD COLUMN IF NOT EXISTS `fakeplate` varchar(50) DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS `garage` varchar(50) DEFAULT 'pillbox',
  ADD COLUMN IF NOT EXISTS `fuel` int(11) DEFAULT 100,
  ADD COLUMN IF NOT EXISTS `engine` float DEFAULT 1000,
  ADD COLUMN IF NOT EXISTS `body` float DEFAULT 1000,
  ADD COLUMN IF NOT EXISTS `state` int(11) DEFAULT 1,
  ADD COLUMN IF NOT EXISTS `depotprice` int(11) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS `drivingdistance` int(50) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS `status` text DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS `coords` text DEFAULT NULL;

-- Index (ignore l'erreur si déjà présents)
-- CREATE INDEX `idx_player_vehicles_citizenid` ON `player_vehicles` (`citizenid`);
-- CREATE INDEX `idx_player_vehicles_garage` ON `player_vehicles` (`garage`);
-- CREATE INDEX `idx_player_vehicles_state` ON `player_vehicles` (`state`);

-- Remettre les véhicules sortis en garage (après crash / restart)
-- UPDATE `player_vehicles` SET `state` = 1 WHERE `state` = 0;

-- Exemple fourrière manuelle
-- UPDATE `player_vehicles` SET `state` = 2, `depotprice` = 500, `garage` = 'impound' WHERE `plate` = 'ABC12345';
