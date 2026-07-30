# esx_losplantos_inventory

Menu inventaire **list-style** pour ESX, fidèle au design Los Plantos (bandeau synthwave, barre de poids, liste semi-transparente avec sélection blanche).

## Installation

1. Copier le dossier `esx_losplantos_inventory` dans `resources/[esx]/` (ou équivalent).
2. Ajouter dans `server.cfg` :

```cfg
ensure es_extended
ensure esx_losplantos_inventory
```

3. Redémarrer le serveur / la ressource.

> Si vous avez déjà `esx_inventoryhud`, `ox_inventory` ou un autre inventaire, désactivez-le ou changez la touche pour éviter les conflits.

## Utilisation

| Action | Contrôle |
|--------|----------|
| Ouvrir / fermer | **F2** (configurable) |
| Naviguer | Flèches ↑ ↓ ou clic |
| Utiliser | Entrée / double-clic / bouton **Utiliser** |
| Donner | Bouton **Donner** / touche **G** / clic droit |
| Échanger | Bouton **Échanger** / touche **E** (choisir joueur + quantité) |
| Jeter | Bouton **Jeter** / touche **J** (choisir quantité) |
| Fermer | ESC / Backspace |

Pour **Donner** et **Échanger**, un joueur doit être à moins de `Config.GiveDistance` (3 m par défaut). Un modal permet de choisir la **quantité** et le **joueur**.

## Configuration

Fichier `config.lua` :

- `Config.OpenKey` — touche d’ouverture
- `Config.MaxWeight` — poids max affiché (kg)
- `Config.ItemImages` — mapping item → icône `html/img/`
- `Config.ItemLabels` — labels FR de secours

## Aperçu NUI

Ouvrir `html/index.html` dans un navigateur pour prévisualiser le menu avec les items de démo (hors FiveM).

## Structure

```
esx_losplantos_inventory/
├── fxmanifest.lua
├── config.lua
├── client/main.lua
├── server/main.lua
└── html/
    ├── index.html
    ├── style.css
    ├── app.js
    ├── assets/header.png
    └── img/*.svg
```

## Exports client

```lua
exports['esx_losplantos_inventory']:OpenInventory()
exports['esx_losplantos_inventory']:CloseInventory()
exports['esx_losplantos_inventory']:IsInventoryOpen()
```

## Notes

- Compatible ESX Legacy (imports + `ESX.UseItem`).
- Les icônes manquantes basculent sur `default.svg`.
- Remplacez `html/assets/header.png` pour personnaliser le bandeau.
