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
- `music` — musique de chargement (voir ci-dessous)

Remplace `html/logo.jpg` pour changer le visuel.

### Musique de chargement

1. Remplace `html/audio/loading.mp3` par ta piste (MP3 recommandé).
2. Ajuste dans `html/config.js` :

```js
music: {
    enabled: true,
    file: 'audio/loading.mp3',
    volume: 0.35,      // 0 à 1
    loop: true,
    autoplay: true,
    defaultOn: true,     // état au démarrage
    labelOn: 'SON : ON',
    labelOff: 'SON : OFF',
},
```

Un bouton **SON : ON/OFF** en haut à droite permet de couper la musique pendant le chargement.

## Notes

- Suit la progression native FiveM (`loadProgress`)
- Fermeture auto via `ShutdownLoadingScreen` quand la session démarre
- Palette alignée logo : cyan électrique + or
