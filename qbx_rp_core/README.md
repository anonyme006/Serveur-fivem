# qbx_rp_core

Core RP pour serveur **QBox (`qbx_core`)** : persistance véhicules, fourrière au reboot, dégâts d’accident, clés, portefeuille / trousseau, bâche, parking d’occasions, carte à l’Échap, alertes essence / faim / soif, météo sync, logs Discord, réseau téléphone.

Portage QBox du module ESX équivalent — utilise `player_vehicles` (`citizenid`, `mods`, `state` 0/1/2).

## Dépendances

- `qbx_core`
- `oxmysql`
- `ox_lib`
- `ox_inventory` *(clés item + antennes)*
- `ox_fuel` ou `LegacyFuel` *(optionnel — alerte essence)*
- `qbx_garages` / `ox_garage` *(recommandé — sortie garage / fourrière)*

## Installation

1. Place le dossier `qbx_rp_core` dans tes resources
2. Importe `sql/qbx_rp_core.sql` (auto au démarrage aussi)
3. Ajoute les items ox_inventory (`install/ox_items.lua`, `install/ox_items_antenna.lua`)
4. Dans `server.cfg` :

```cfg
ensure qbx_core
ensure oxmysql
ensure ox_lib
ensure ox_inventory
ensure qbx_garages
ensure qbx_rp_core
```

## Fonctionnalités

| Module | Détail |
|--------|--------|
| **Persistance** | Sauvegarde périodique moteur / carrosserie / essence / dégâts dans `player_vehicles.mods` |
| **Fourrière reboot** | Véhicules `state = 0` → `state = 2` + garage `impound` au démarrage |
| **Accidents** | Dégâts renforcés + risque de calage + save immédiate |
| **Clés** | DB + item inventaire à l’achat + serrurier (100$) |
| **Portefeuille** | Cash, banque, trousseau — touche **F4** (NUI) ou `/trousseau` |
| **Bâche** | `/bache` — pose / retire, véhicule protégé du reboot fourrière |
| **Occasions** | Parking Strawberry — acheter / mettre en vente |
| **Carte Échap** | Prop carte + anim quand le menu pause est ouvert |
| **Alertes** | Essence basse ; faim / soif via `PlayerData.metadata` |
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
exports.qbx_rp_core:HasKey(src, 'vehicle', plate)
exports.qbx_rp_core:GiveKey(holderCitizenId, 'vehicle', plate, ownerCitizenId, label, temporary, minutes)
exports.qbx_rp_core:GiveHouseKey(holderSrc, houseId, label, ownerCitizenId)
exports.qbx_rp_core:RegisterHouseDoor(houseId, coords, locked)
exports.qbx_rp_core:HasNetworkSignal(source)
exports.qbx_rp_core:GetSignalStrength(source)

-- Client
exports.qbx_rp_core:ToggleVehicleLock()
```

## Réseau téléphone (antennes)

Sans antenne à portée : **pas d’appels, SMS, ni réseaux sociaux**.

1. Ajoute l’item `phone_antenna` (`install/ox_items_antenna.lua`)
2. Utilise l’item pour déployer
3. Retire près de l’antenne pour récupérer l’item

Portée : `Config.Network.range` (180 m). Antennes fixes optionnelles dans `staticAntennas`.

```lua
if not exports.qbx_rp_core:HasNetworkSignal(source) then return end
```

Compat auto : npwd, lb-phone, gksphone, qs-smartphone.

## Logs Discord

Dans `config.lua` → `Config.Discord.defaultWebhook`.

Catégories : `connect`, `chat`, `death`, `explosion`, `admin`, `vehicles`, `keys`, `money`, `weather`, `resources`, `system`.

```lua
exports.qbx_rp_core:DiscordLog('admin', 'Titre', 'Description', { color = 'warning', src = source })
```

## Météo synchronisée

| Commande | Description |
|----------|-------------|
| `/weather [TYPE]` | Force la météo (CLEAR, RAIN, THUNDER…) |
| `/time [h] [m]` | Force l’heure |
| `/blackout [on/off]` | Coupe les lumières de la ville |
| `/freezetime` | Gele / dégèle l’heure |

Permissions : `Config.Weather.adminGroups` via `qbx_core:HasPermission` / ACE `group.<name>`.

```lua
exports.qbx_rp_core:SetWeather('RAIN')
exports.qbx_rp_core:SetTime(21, 30)
exports.qbx_rp_core:SetBlackout(true)
exports.qbx_rp_core:FreezeTime(true)
```

## Clés inventaire + serrurier

À l’**achat**, une clé item (`vehicle_key`) est ajoutée (ox_inventory).

Ajoute dans `ox_inventory/data/items.lua` le contenu de `install/ox_items.lua` :

```lua
['vehicle_key'] = {
    label = 'Clé de véhicule',
    weight = 20,
    stack = false,
    close = true,
    description = 'Clé permettant de verrouiller / déverrouiller un véhicule',
    client = {
        export = 'qbx_rp_core.useVehicleKey',
    },
},
```

Serrurier : `Config.KeyShop.price` (défaut **100$**), commande `/serrurier`.

## Clés automatiques (garage + achat)

| Option | Effet |
|--------|--------|
| `giveOnGarageTakeOut` | Sortie garage / fourrière (`ox_garage:registerSpawn`, hooks qbx_garages) |
| `giveOnPurchase` | Achat `qbx_vehicleshop` / `qb-vehicleshop` |
| `notifyOnGive` | Notification joueur |

```lua
exports.qbx_rp_core:GiveVehicleKey(src, plate, label)
TriggerEvent('qbx_rp_core:keys:giveVehicleKey', src, plate, label)
```

## Config importante

- `Config.Persistence.columns` — table `player_vehicles`, colonnes QBox
- `Config.Persistence.state` — `out=0`, `garaged=1`, `impound=2`
- `Config.AutoImpound.impoundId` — id fourrière (`impound` par défaut)
- `Config.UsedParking.slots` — emplacements occasions
- `Config.Alerts.*` — seuils essence / faim / soif (metadata QBox)
- `Config.Discord.defaultWebhook` — logs
