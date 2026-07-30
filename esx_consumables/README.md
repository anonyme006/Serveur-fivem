# esx_consumables

Nourriture & boissons : **barre esx_progressbar** (capsule orange) pendant que le joueur mange ou boit, puis mise à jour `esx_status` (faim / soif).

## Dépendances

- `es_extended`
- `esx_progressbar`
- `esx_status` (recommandé)
- `ox_inventory` (optionnel)

## Installation

```cfg
ensure es_extended
ensure esx_status
ensure esx_progressbar
ensure esx_consumables
```

### Avec ox_inventory

1. Fusionner `ox_inventory/items_snippet.lua` dans `ox_inventory/data/items.lua`
2. Chaque item pointe vers `export = 'esx_consumables.useItem'`

### Sans ox_inventory (ESX inventaire)

Les items de `config.lua` sont enregistrés via `ESX.RegisterUsableItem`.

## Test

```
/testeat burger
/testdrink water
```

## Config

`config.lua` — items, durée, animations, props, points faim/soif.
