# ox_inventory_ui

Thème d’inventaire inspiré du visuel demandé (grilles 5×5 + boutons centraux), prévu pour **ox_inventory**.

## Couleurs des boutons

| Bouton | Couleur |
|--------|---------|
| **Information** | Bleu |
| **Utiliser** | **Vert** |
| **Échanger** | Teal |
| **Fermer** | **Rouge** |

## Installation

1. Copiez le dossier `ox_inventory_ui` dans `resources/[ox]/`
2. Dans `server.cfg` :

```cfg
ensure ox_inventory
ensure ox_inventory_ui
```

3. Aperçu navigateur (sans FiveM) : ouvrez `html/preview.html`

4. En jeu : commande `/invui` pour ouvrir l’interface (charge les items ox_inventory si disponibles)

## Structure

```
ox_inventory_ui/
├── client/main.lua      # Bridge NUI + exports
├── fxmanifest.lua
├── theme-vibe.css       # Patch CSS pour l'UI React ox_inventory
├── html/
│   ├── index.html       # UI principale
│   ├── style.css        # Thème (Utiliser vert / Fermer rouge)
│   ├── app.js           # Logique + messages NUI
│   └── preview.html     # Démo navigateur
└── README.md
```

### Patch UI React ox_inventory

Si vous gardez l’UI d’origine d’ox_inventory, copiez `theme-vibe.css` dans `ox_inventory/web/build/` et ajoutez dans `index.html` :

```html
<link rel="stylesheet" href="./theme-vibe.css" />
```

## Intégration ox_inventory

- Les images d’items pointent vers `nui://ox_inventory/web/images/<name>.png`
- Callbacks NUI : `useItem`, `giveItem`, `exit`, `closeInventory`
- Exports client : `exports.ox_inventory_ui:open(payload)` / `close()`

Pour remplacer entièrement l’UI React d’ox_inventory, branchez les mêmes messages NUI (`setupInventory`, `refreshSlots`, `closeInventory`) depuis votre client, ou utilisez cette ressource en overlay via `/invui`.

## Personnalisation rapide

Dans `html/style.css` :

```css
--btn-use: #2fbf5a;    /* Utiliser (vert) */
--btn-close: #d62839;  /* Fermer (rouge) */
--btn-info: #1e7fd6;   /* Information */
--btn-give: #1a6b72;   /* Échanger */
```
