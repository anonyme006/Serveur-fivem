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

- Blip concessionnaire → **E**
- Menu ox_lib : catégories → véhicules → acheter
- Recherche via le menu
- Commande test : `/concessionnaire`

## Configuration

Fichier `config.lua` :

| Option | Description |
|--------|-------------|
| `Config.Zones` | Position, marker, blip |
| `Config.Preview` | Spawn + offset caméra |
| `Config.PurchaseSpawn` | Spawn du véhicule acheté (dehors) |
| `Config.PaymentAccount` | `'bank'`, `'cash'` / `'money'` ou `'both'` |
| `Config.DefaultGarage` | Garage enregistré en DB |
| `Config.PurchaseState` | `0` sorti / `1` garage |
| `Config.Vehicles` | Catalogue |
| `Config.Categories` | Catégories du menu |

## Base de données

Insert dans `player_vehicles` :

- `license`, `citizenid`, `vehicle`, `hash`, `mods`, `plate`
- `garage`, `fuel`, `engine`, `body`, `state`

## Exports

```lua
exports['qbx_concessionnaire']:OpenDealership()
exports['qbx_concessionnaire']:CloseDealership()
```
