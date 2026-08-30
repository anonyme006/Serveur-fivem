# serenity_loadingscreen

Loading screen **Serenity V RP** avec le logo officiel.

## Installation

1. Place le dossier `serenity_loadingscreen` dans tes resources
2. Dans `server.cfg` **en premier** (avant le framework) :

```cfg
ensure serenity_loadingscreen
```

## Personnalisation

Édite `html/config.js` :

- `tagline` — sous-titre sous le logo
- `tips` — messages rotatifs
- `tipInterval` — délai entre tips (ms)

Remplace `html/logo.jpg` pour changer le visuel.

## Notes

- Suit la progression native FiveM (`loadProgress`)
- Fermeture auto via `ShutdownLoadingScreen` quand la session démarre
- Palette alignée logo : cyan électrique + or
