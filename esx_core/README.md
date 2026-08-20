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
| **Clés** | Item inventaire à l’achat + serrurier pour racheter |
| **Portefeuille** | Espèces, banque, trousseau — touche **F4** (NUI) ou `/trousseau` |
| **Bâche** | `/bache` — pose / retire une bâche, véhicule protégé du reboot fourrière |
| **Occasions** | Parking Strawberry — **E** acheter, **G** mettre en vente |
| **Carte Échap** | Prop carte + anim quand le menu pause est ouvert |
| **Alertes** | Essence basse, faim / soif (seuils dans `config.lua`) |
| **Offroad** | Sable / boue / herbe / gravier → couple et vitesse réduits |
| **Météo sync** | Même météo & heure pour tous + rotation dynamique |
| **Logs Discord** | Connexions, chat, morts, véhicules, clés, admin… |
| **Réseau téléphone** | Antennes à déployer — sans signal : pas d’appels / SMS / social |

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

## Logs Discord

Dans `config.lua` → `Config.Discord.defaultWebhook` (URL webhook Discord).

Catégories : `connect`, `chat`, `death`, `explosion`, `admin`, `vehicles`, `keys`, `money`, `weather`, `resources`, `system`.

```lua
-- Depuis un autre script
exports.esx_core:DiscordLog('admin', 'Titre', 'Description', { color = 'warning', src = source })
```

## Météo synchronisée

Tous les joueurs partagent la même météo et la même heure (`Config.Weather` / `Config.Time`).

| Commande | Description |
|----------|-------------|
| `/weather [TYPE]` | Force la météo (CLEAR, RAIN, THUNDER…) |
| `/time [h] [m]` | Force l’heure |
| `/blackout [on/off]` | Coupe les lumières de la ville |
| `/freezetime` | Gele / dégèle l’heure |

```lua
exports.esx_core:SetWeather('RAIN')
exports.esx_core:SetTime(21, 30)
exports.esx_core:SetBlackout(true)
exports.esx_core:FreezeTime(true)
```

## Offroad

Sur sable, boue, herbe haute, gravier, neige… le véhicule perd de l’adhérence et de la vitesse (`Config.Offroad`).

- Les **4x4** (classe 9) sont moins pénalisés (`offroadClassMultiplier`)
- Motos / bateaux / air = exemptés
- Ajuste `Config.Offroad.surfaces` pour chaque type de sol

## Clés inventaire + serrurier

À l’**achat** d’un véhicule, une clé item (`vehicle_key`) est ajoutée à l’inventaire (ox_inventory / ESX).

### Installation item

**ox_inventory** — ajoute dans `ox_inventory/data/items.lua` le contenu de `install/ox_items.lua` :

```lua
['vehicle_key'] = {
    label = 'Clé de véhicule',
    weight = 20,
    stack = false,
    close = true,
    description = 'Clé permettant de verrouiller / déverrouiller un véhicule',
    client = {
        export = 'esx_core.useVehicleKey',
    },
},
```

**ESX items** — exécute `install/esx_items.sql`.

### Serrurier

Point sur la carte pour **racheter / dupliquer** une clé (prix `Config.KeyShop.price`, max par plaque configurable). Commande `/serrurier`.

| Option | Défaut | Effet |
|--------|--------|--------|
| `Keys.inventory.giveItemOnPurchase` | true | Item à l’achat |
| `Keys.inventory.requireItemToLock` | true | Il faut la clé en inventaire pour verrouiller |
| `Keys.inventory.giveMissingOnGarage` | false | Ne redonne pas gratuitement à la sortie garage |

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
