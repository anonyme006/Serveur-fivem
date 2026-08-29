# ox_inventory — Fork Samuel (Qbox)

Intégration complète basée sur [Samuels-Development/ox_inventory](https://github.com/Samuels-Development/ox_inventory), personnalisée pour **Qbox** + **rcore_clothing**.

## Fonctionnalités ajoutées

- Stats joueur dans l'inventaire : santé, faim, soif, armure (state bags Qbox)
- Preview PED 3D (`pedPreview.mode = 'clone'`)
- Slots vêtements FR (15 slots, thème or `#d4af37`)
- Support **rcore_clothing** (preview, retrait tenue, sync skin)
- Bouton **Retirer tenue**

## Installation

1. Remplacer votre ressource `ox_inventory` par le dossier `ox_inventory/` de ce repo
2. Dépendances : `ox_lib`, `oxmysql`, `qbx_core`, `rcore_clothing`, `ox_target`
3. `ensure ox_inventory` dans `server.cfg`

## Configuration

Éditez `ox_inventory/data/ui.lua` :

```lua
qboxUi = {
    accentColor = '#d4af37',
    showHealth = true,
    showHunger = true,
    showThirst = true,
    showArmor = true,
    showRemoveOutfit = true,
    statusUpdateInterval = 500,
},
```

## Build NUI (si vous modifiez le web)

```bash
cd ox_inventory/web
npm install --legacy-peer-deps
npm run build
```

## Package drop-in (ox_inventory standard)

Pour la version standard d'ox_inventory (sans fork Samuel), voir [ox_inventory_ui/README.md](../ox_inventory_ui/README.md).
