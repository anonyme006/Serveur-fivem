# esx_concessionnaire

Concessionnaire véhicules **ESX** avec menus **ox_lib** (context / input / alert) + prévisualisation 3D.

## Prérequis

- `es_extended` (ESX Legacy)
- `oxmysql`
- `ox_lib`

## Installation

```cfg
ensure es_extended
ensure oxmysql
ensure ox_lib
ensure esx_concessionnaire
```

La table `owned_vehicles` ESX doit exister.

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
| `Config.Preview` | Spawn + caméra de prévisualisation |
| `Config.PurchaseSpawn` | Spawn du véhicule acheté |
| `Config.PaymentAccount` | `'bank'`, `'money'` ou `'both'` |
| `Config.Vehicles` | Catalogue |
| `Config.Categories` | Catégories du menu |

## Exports

```lua
exports['esx_concessionnaire']:OpenDealership()
exports['esx_concessionnaire']:CloseDealership()
```
