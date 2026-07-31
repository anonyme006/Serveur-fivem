# esx_core

Petit core RP pour serveur **ESX Legacy** : persistance véhicules, fourrière au reboot, dégâts d’accident, clés, portefeuille / trousseau, bâche, parking d’occasions, carte à l’Échap, alertes essence / faim / soif.

## Dépendances

- `es_extended`
- `oxmysql`
- `ox_lib`
- `esx_status` *(optionnel — alertes faim / soif)*
- `ox_fuel` ou `LegacyFuel` *(optionnel — alerte essence)*
- `pa_garage` / `ox_garage` *(recommandé — récupération fourrière)*

## Installation

1. Place le dossier `esx_core` dans tes resources
2. Importe `sql/esx_core.sql` (auto au démarrage aussi)
3. Dans `server.cfg` :

```cfg
ensure es_extended
ensure oxmysql
ensure ox_lib
ensure esx_status
ensure pa_garage
ensure esx_core
```

## Fonctionnalités

| Module | Détail |
|--------|--------|
| **Persistance** | Sauvegarde périodique moteur / carrosserie / essence / dégâts dans `owned_vehicles` |
| **Fourrière reboot** | Tous les véhicules `stored = 0` → `impound_public` au démarrage |
| **Accidents** | Dégâts renforcés + risque de calage + save immédiate |
| **Clés** | Véhicules + habitations, permanentes / temporaires — touche **U** |
| **Portefeuille** | Espèces, banque, trousseau — touche **F4** (NUI) ou `/trousseau` |
| **Bâche** | `/bache` — pose / retire une bâche, véhicule protégé du reboot fourrière |
| **Occasions** | Parking Strawberry — **E** acheter, **G** mettre en vente |
| **Carte Échap** | Prop carte + anim quand le menu pause est ouvert |
| **Alertes** | Essence basse, faim / soif (seuils dans `config.lua`) |
| **Offroad** | Sable / boue / herbe / gravier → couple et vitesse réduits |

## Raccourcis

| Action | Touche / commande |
|--------|-------------------|
| Verrouiller véhicule | `U` / `/vehiclelock` |
| Portefeuille | `F4` / `/portefeuille` |
| Trousseau (menu) | `/trousseau` |
| Bâche | `/bache` |

## Exports utiles

```lua
-- Serveur
exports.esx_core:HasKey(src, 'vehicle', plate)
exports.esx_core:GiveKey(holderIdentifier, 'vehicle', plate, ownerIdentifier, label, temporary, minutes)
exports.esx_core:GiveHouseKey(holderSrc, houseId, label, ownerIdentifier)
exports.esx_core:RegisterHouseDoor(houseId, coords, locked)

-- Client
exports.esx_core:ToggleVehicleLock()
```

## Offroad

Sur sable, boue, herbe haute, gravier, neige… le véhicule perd de l’adhérence et de la vitesse (`Config.Offroad`).

- Les **4x4** (classe 9) sont moins pénalisés (`offroadClassMultiplier`)
- Motos / bateaux / air = exemptés
- Ajuste `Config.Offroad.surfaces` pour chaque type de sol

## Clés automatiques (garage + achat)

Activé par défaut dans `Config.Keys` :

| Option | Effet |
|--------|--------|
| `giveOnGarageTakeOut` | Clés données à la sortie `pa_garage` / fourrière (`ox_garage:registerSpawn`) |
| `giveOnPurchase` | Clés données à l’achat `esx_concessionnaire` |
| `notifyOnGive` | Notification joueur |

### Hooks manuels (autres scripts)

```lua
-- Serveur
exports.esx_core:GiveVehicleKey(src, plate, label)
TriggerEvent('esx_core:keys:giveVehicleKey', src, plate, label)

-- Depuis le concessionnaire (giveKeys)
pcall(function()
    exports.esx_core:GiveVehicleKey(src, plate, model)
end)
```

## Config importante

- `Config.AutoImpound.impoundId` — doit matcher `pa_garage` (`impound_public`)
- `Config.UsedParking.slots` — emplacements du parking occasions
- `Config.Alerts.*` — seuils essence / faim / soif
