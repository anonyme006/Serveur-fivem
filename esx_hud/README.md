# esx_hud

HUD ESX minimaliste pour FiveM, inspiré d’un design clean :

- **Barres status** (bas gauche) : santé (vert), faim (jaune), soif (bleu)
- **Speedometer** (bas droite, conducteur) : vitesse, RPM, moteur, carburant, plaque

## Prérequis

- [ESX Legacy](https://github.com/esx-framework/esx_core) (`es_extended`)
- `esx_status` (recommandé pour faim / soif)
- Optionnel : `LegacyFuel` ou `cdn-fuel` pour un niveau d’essence réaliste

## Installation

1. Copiez le dossier `esx_hud` dans `resources/[esx]/` (ou équivalent).
2. Dans `server.cfg` :

```cfg
ensure es_extended
ensure esx_status
ensure esx_hud
```

3. Redémarrez le serveur (ou `ensure esx_hud`).

## Configuration

Éditez `config.lua` :

| Option | Description |
|--------|-------------|
| `Config.SpeedUnit` | `'kmh'` ou `'mph'` |
| `Config.ShowVehicleHud` | Afficher le compteur véhicule |
| `Config.HideRadar` | Cacher la minimap GTA |
| `Config.Status.hunger` / `thirst` | Noms des status `esx_status` |

## Fonctionnement

| Élément | Source |
|---------|--------|
| Santé | `GetEntityHealth` |
| Faim / soif | `esx_status` |
| Vitesse / RPM | natives véhicule |
| Moteur | `GetVehicleEngineHealth` |
| Essence | `LegacyFuel` / `cdn-fuel` / native |
| Plaque | `GetVehicleNumberPlateText` |

Le HUD se cache automatiquement dans le menu pause et hors session joueur.

## Structure

```
esx_hud/
├── fxmanifest.lua
├── config.lua
├── client/main.lua
└── html/
    ├── index.html
    ├── style.css
    └── script.js
```

## Notes

- Affiche le speedometer uniquement pour le **conducteur**.
- Sans `esx_status`, faim et soif restent à 100 %.
- Compatible avec un restart à chaud de la ressource.
