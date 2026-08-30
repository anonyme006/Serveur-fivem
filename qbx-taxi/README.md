# qbx-taxi — San Andreas Taxi Corporation

Système taxi RP complet pour **Qbox** avec **MenuV** comme interface principale.

## Étape 1 — fxmanifest.lua + config.lua

Cette étape pose uniquement les fondations de configuration :

- **`fxmanifest.lua`** : dépendances (`menuv`, `qbx_core`, `ox_lib`, `oxmysql`, `ox_target`, `ox_inventory`, `qbx-duty`)
- **`config.lua`** : configuration complète (entreprise, MenuV, grades, véhicules, garage, duty, tarifs, dispatch, vestiaire, boss, facturation, webhooks, SQL, sécurité)

Aucun script client/serveur n'est chargé à cette étape.

## Stack

| Composant | Rôle |
|-----------|------|
| **Qbox** | Framework (`qbx_core`) |
| **MenuV** | Menus principaux (pas de NUI parallèle) |
| **ox_lib** | Notifications, callbacks, zones |
| **ox_target** | Interactions monde |
| **oxmysql** | Base de données |
| **ox_inventory** | Coffre entreprise |
| **qbx-duty** | Prise de service + blips map |

## Installation

1. Installer [MenuV](https://github.com/ThymonA/menuv) et démarrer **avant** qbx-taxi
2. Copier `San_Andreas_Taxi_Corporation.png` → `web/assets/logo.png`
3. `server.cfg` :

```cfg
ensure menuv
ensure ox_lib
ensure oxmysql
ensure qbx_core
ensure qbx-duty
ensure ox_target
ensure ox_inventory
ensure qbx-taxi
```

## Structure prévue

```
qbx-taxi/
├── fxmanifest.lua
├── config.lua
├── client/
│   ├── main.lua
│   ├── menu_main.lua
│   ├── menu_personnel.lua
│   ├── menu_vehicle.lua
│   ├── menu_garage.lua
│   ├── menu_dispatch.lua
│   ├── menu_rides.lua
│   ├── menu_taximeter.lua
│   ├── duty.lua
│   ├── vehicle.lua
│   ├── target.lua
│   └── utils.lua
├── server/
│   ├── main.lua
│   ├── rides.lua
│   ├── employees.lua
│   ├── billing.lua
│   ├── database.lua
│   └── callbacks.lua
├── shared/
│   └── utils.lua
├── web/assets/logo.png
└── sql/taxi.sql
```

## Roadmap

| Étape | Contenu |
|-------|---------|
| **1** | fxmanifest + config |
| 2 | Intégration MenuV |
| 3 | Menu principal |
| 4 | Menu personnel |
| 5 | Menu véhicule |
| 6 | Garage |
| 7 | qbx-duty |
| 8 | Dispatch |
| 9 | Système de courses |
| 10 | Taximètre |
| 11 | Paiement |
| 12 | Statistiques |
| 13 | Gestion employés |
| 14 | SQL |
| 15 | Logs |
| 16 | Tests |
| 17 | Optimisation |

## Notes MenuV

API officielle (vérifier la version installée) :

```lua
local menu = MenuV:CreateMenu(title, subtitle, position, r, g, b)
menu:AddButton({ icon = '🚕', label = '...', value = ..., description = '...' })
menu:AddConfirm({ icon = '✅', label = '...', value = false })
menu:On('select', function(item) end)
```

Couleurs taxi : RGB `255, 200, 0` — position `topleft`.

## Prochaine étape

**Étape 2** — Intégrer MenuV (`@menuv/menuv.lua` + initialisation).
