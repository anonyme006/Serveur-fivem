# ox_inventory — Fork Samuel (Qbox)

Basé sur [Samuels-Development/ox_inventory](https://github.com/Samuels-Development/ox_inventory).

## Installation

```cfg
ensure ox_lib
ensure oxmysql
ensure ox_target
ensure qbx_core
ensure ox_inventory

setr inventory:target 1
```

## Contenu

| Fichier | Rôle |
|---------|------|
| `data/ui.lua` | UI (thème vert, clothing, stats) |
| `data/shops.lua` | **Magasins natifs** (24/7, alcool, armes, etc.) |
| `modules/qbox_ui/` | Stats santé / faim / soif (+ armure si gilet activé) |

## Shops

Tout se fait **via ox_inventory** — voir [SHOPS.md](SHOPS.md).

Aucun script shop externe n’est nécessaire : ciblez le comptoir (`ox_target`) ou un marker, l’inventaire s’ouvre en mode shop.

## Stats inventaire

- Santé / faim / soif : toujours dans l’UI inventaire
- Armure : uniquement si gilet pare-balles **activé** (`GetPedArmour > 0`)

## Build NUI

```bash
cd ox_inventory/web && npm install --legacy-peer-deps && npm run build
```
