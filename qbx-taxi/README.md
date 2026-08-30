# qbx-taxi — San Andreas Taxi Corporation

Ressource taxi immersive pour serveur **Qbox**.

## Étape 1 — Architecture + Config + Qbox

Cette étape pose les fondations :

- Structure complète du projet
- `fxmanifest.lua` compatible Qbox / ox_lib / oxmysql
- `config.lua` exhaustif
- Intégration Qbox (client + serveur)
- NUI shell (noir / jaune taxi)
- Callbacks de base

## Dépendances

- [qbx_core](https://github.com/Qbox-project/qbx_core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [oxmysql](https://github.com/overextended/oxmysql)
- [ox_target](https://github.com/overextended/ox_target)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- **qbx-duty** (intégration complète à l'étape 3)

## Installation

1. Copier `qbx-taxi` dans `resources/[jobs]/`
2. Copier `San_Andreas_Taxi_Corporation.png` vers `web/assets/logo.png`
3. Ajouter dans `server.cfg` :

```cfg
ensure ox_lib
ensure oxmysql
ensure qbx_core
ensure qbx-duty
ensure ox_target
ensure ox_inventory
ensure qbx-taxi
```

4. Le job `taxi` sera ajouté à l'**Étape 2**.

## Exports

### Client

- `exports['qbx-taxi']:IsTaxiEmployee()`
- `exports['qbx-taxi']:GetJobGrade()`
- `exports['qbx-taxi']:HasJobPermission(permission)`
- `exports['qbx-taxi']:GetPublicConfig()`

### Serveur

- `exports['qbx-taxi']:IsTaxiEmployee(source)`
- `exports['qbx-taxi']:HasJobPermission(source, permission)`
- `exports['qbx-taxi']:GetOnDutyTaxiDrivers()`
- `exports['qbx-taxi']:GetPublicConfig()`

## Callbacks

- `qbx-taxi:server:getPublicConfig`
- `qbx-taxi:server:getPlayerStatus`

## Notes Qbox

- Pas de `GetCoreObject()` — utilisation de `exports.qbx_core:*`
- PlayerData client via `@qbx_core/modules/playerdata.lua` (`QBX.PlayerData`)
- Duty natif Qbox : `PlayerData.job.onduty` + `exports.qbx_core:GetDutyCountJob('taxi')`
- Intégration **qbx-duty** prévue étape 3 (sans recréer un système duty)

## Prochaine étape

**Étape 2** — Job Taxi + grades + permissions dans Qbox.
