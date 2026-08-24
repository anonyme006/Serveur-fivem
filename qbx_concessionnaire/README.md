# qbx_concessionnaire

Concessionnaire véhicules **Qbox** avec menus **ox_lib** (context / input / alert) + prévisualisation 3D.

## Prérequis

- `qbx_core`
- `oxmysql`
- `ox_lib`
- Table `player_vehicles` (standard Qbox / qb-garages)
- Optionnel : `qbx_vehiclekeys` / `qb-vehiclekeys`

## Installation

```cfg
ensure qbx_core
ensure oxmysql
ensure ox_lib
ensure qbx_concessionnaire
```

## Utilisation

- **Point rouge** au sol → **E** ouvre le menu
- **Points verts** = places de livraison du véhicule acheté
- Menu ox_lib : catégories → véhicules → aperçu / acheter
- Commande test : `/concessionnaire`

## Configuration

Fichier `config.lua` :

| Option | Description |
|--------|-------------|
| `Config.Markers` | Disques plats rouge (menu) / vert (park) |
| `Config.Zones` | `menu`, `parks`, `preview`, blip |
| `Config.PaymentAccount` | `'bank'`, `'cash'` / `'money'` ou `'both'` |
| `Config.DefaultGarage` | Garage enregistré en DB |
| `Config.PurchaseState` | `0` sorti / `1` garage |
| `Config.Vehicles` | Catalogue |
| `Config.Categories` | Catégories du menu |

## Base de données

Importe le SQL Qbox **une fois** :

```bash
mysql -u USER -p DATABASE < sql/qbox_vehicles.sql
# ou
mysql -u USER -p DATABASE < qbx_concessionnaire/sql/player_vehicles.sql
```

Insert dans `player_vehicles` :

- `license`, `citizenid`, `vehicle`, `hash`, `mods`, `plate`
- `garage`, `fuel`, `engine`, `body`, `state`

| state | Signification |
|------:|---------------|
| 0 | Sorti (après achat) |
| 1 | En garage |
| 2 | Fourrière |

## Exports

```lua
exports['qbx_concessionnaire']:OpenDealership()
exports['qbx_concessionnaire']:CloseDealership()
```
