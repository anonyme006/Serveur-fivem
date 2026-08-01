# ox_notify — style notifications (photo)

Remplace le look par défaut d’**ox_lib** (`lib.notify`) par des toasts :

- stack **à gauche** (milieu vertical)
- fond sombre semi-transparent
- **barre d’accent** verticale à gauche
- **barre de durée** fine en bas (même couleur)
- titre gras + description, texte blanc
- rouge (`error` / `warning`) · jaune/or (`success`) · bleu (`inform`)

## Installation

1. Copie le dossier `ox_notify` dans tes resources, ex. :
   ```
   resources/[local]/ox_notify
   ```

2. Dans `server.cfg` (après ox_lib) :
   ```cfg
   ensure ox_lib
   ensure ox_notify
   ```

3. **Patch ox_lib** (obligatoire pour que *tous* les `lib.notify` passent ici) :
   ```
   ox_notify/ox_lib_patch/notify.lua
     →  ox_lib/resource/interface/client/notify.lua
   ```
   (remplace le fichier, garde une copie de l’original)

4. `ensure ox_notify` puis `restart ox_lib` (ou reboot serveur).

## Test in-game

```
/testnotify
```

Reproduit les 3 notifications de la capture (2× station pleine rouge + livraison jaune).

## API

Compatible ox_lib :

```lua
lib.notify({
    title = 'Station pleine',
    description = 'Xero | Strawberry Avenue est à capacité maximale (3000L)',
    type = 'error',
    duration = 5000,
})
```

Export direct :

```lua
exports.ox_notify:Notify({
    title = 'Livraison terminée',
    description = 'Plus de barils ou arrêt manuel',
    type = 'success',
})

-- style okokNotify
exports.ox_notify:Alert('Titre', 'Message', 5000, 'success')
```

Serveur → client :

```lua
TriggerClientEvent('ox_lib:notify', source, { title = '...', description = '...', type = 'error' })
-- ou
TriggerClientEvent('ox_notify:notify', source, { title = '...', description = '...', type = 'success' })
```

## Config

`config.lua` :

| Clé | Défaut | Rôle |
|-----|--------|------|
| `Position` | `'left'` | `left` / `right` |
| `Vertical` | `'center'` | `top` / `center` / `bottom` |
| `DefaultDuration` | `5000` | ms |
| `ShowDuration` | `true` | barre bas |
| `ShowIcons` | `false` | comme la photo (sans icône) |
| `Types.*.color` | rouge / or / bleu | accents |

## Aperçu navigateur

Ouvre `ox_notify/html/preview.html` dans un navigateur → bouton **Reproduire la photo**.

## Contenu

```
ox_notify/
├── client/main.lua
├── config.lua
├── fxmanifest.lua
├── html/          ← NUI + preview.html
├── ox_lib_patch/  ← notify.lua à coller dans ox_lib
└── README.md
```
