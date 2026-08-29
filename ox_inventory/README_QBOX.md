# ox_inventory — Fork Samuel (Qbox)

Basé sur [Samuels-Development/ox_inventory](https://github.com/Samuels-Development/ox_inventory).

L'interface reste **identique au fork Samuel** (thème vert, 10 slots vêtements, silhouette, recherche/filtres, fast slots). Seul ajout : barres **santé, faim, soif** dans l'inventaire ; **armure** uniquement quand un gilet pare-balles est **activé** (`GetPedArmour > 0`).

## Installation

1. Copier `ox_inventory/` dans vos resources
2. Dépendances : `ox_lib`, `oxmysql`, `qbx_core`
3. `ensure ox_inventory`

## Stats (qboxUi)

Config dans `data/ui.lua` :

```lua
qboxUi = {
    showHealth = true,
    showHunger = true,
    showThirst = true,
    statusUpdateInterval = 500,
},
```

L'armure s'affiche automatiquement après utilisation d'un item `armour` (gilet activé).

## Build NUI

```bash
cd ox_inventory/web && npm install --legacy-peer-deps && npm run build
```
