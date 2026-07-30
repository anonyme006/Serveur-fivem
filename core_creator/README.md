# core_creator

Ressource FiveM **autonome** pour créer et gérer en jeu : boutiques, blips, farming, jobs, garages, gangs, appartements, braquages et véhicules/clés — via une NUI admin moderne (React + TypeScript + Vite).

## Compatibilité

| Système | Support |
|---------|---------|
| ESX Legacy | Oui (bridge) |
| QBCore | Oui (bridge) |
| Qbox | Oui (bridge) |
| Standalone | Oui (tables internes) |
| ox_lib | Optionnel (callbacks / notify / progress) |
| ox_inventory | Optionnel (auto-détecté) |
| ox_target / qb-target | Optionnel (auto-détecté) |
| oxmysql | **Requis** |

## Prérequis

- FiveM artifact récent (Lua 5.4)
- `oxmysql`
- Un framework (ESX / QB / Qbox) ou mode standalone
- Node.js 18+ (uniquement pour compiler la NUI)

## Installation

1. Copiez `core_creator` dans vos `resources`.
2. Importez le SQL :

```bash
# via HeidiSQL / phpMyAdmin / mysql CLI
mysql -u user -p database < sql/core_creator.sql
```

La ressource tente aussi de créer les tables au démarrage.

3. Ajoutez dans `server.cfg` :

```cfg
ensure oxmysql
ensure ox_lib          # optionnel mais recommandé
ensure ox_inventory    # optionnel
ensure ox_target       # optionnel
ensure es_extended     # ou qb-core / qbx_core
ensure core_creator

# Permissions ACE
add_ace group.admin core_creator.admin allow
add_ace group.admin core_creator.module.shops allow
add_ace group.admin core_creator.module.blips allow
add_ace group.admin core_creator.module.vehicles allow
add_ace group.admin core_creator.module.farms allow
add_ace group.admin core_creator.module.jobs allow
add_ace group.admin core_creator.module.garages allow
add_ace group.admin core_creator.module.gangs allow
add_ace group.admin core_creator.module.apartments allow
add_ace group.admin core_creator.module.robberies allow
```

4. Compilez la NUI (si `web/dist` est absent ou après modification) :

```bash
cd core_creator/web
npm install
npm run build
```

## Configuration

Fichier principal : `config.lua`

- `Config.Framework` : `auto` | `esx` | `qbcore` | `qbox` | `standalone`
- `Config.Inventory` / `Target` / `Notify` / `VehicleKeys` : `auto` ou forcé
- `Config.Modules.*` : activer/désactiver chaque module
- `Config.Commands.*` : renommer les commandes
- `Config.Permissions` : ACE + groupes framework
- `Config.Logs.discord` + `webhooks` : logs Discord (jamais envoyés au client)

## Commandes

| Commande | Description |
|----------|-------------|
| `/corecreator` | Ouvre le panneau admin |
| `/corecreator_reload` | Recharge le cache / sync clients |
| `/corecreator_debug` | Active/désactive le debug |
| `/corecreator_tp [id] [module]` | Téléporte vers une création |
| `/corecreator_export [module]` | Export JSON dans `exports/` |
| `/corecreator_import <fichier>` | Import JSON depuis `exports/` |
| `/cclock` | Verrouille/déverrouille avec clé core_creator |

## Modules

### Shops
Boutiques dynamiques (items, stock, devise, job/gang, horaires, ped/blip/marker). Hot-reload DB.

### Blips
Blips dynamiques + preview temps réel.

### Vehicles & keys
Création véhicule, plaque, couleurs, attribution joueur, clés permanentes/temporaires, transfert, lock, insert framework (`owned_vehicles` / `player_vehicles`).

### Farms
Circuits multi-étapes (récolte → traitement → vente) avec vérifs serveur (distance, items, cooldown, chance).

### Jobs
Éditeur de métiers + grades + points + sync ESX `jobs`/`job_grades`.

### Garages
Public / job / gang / privé / fourrière — spawn multi-points, store, anti double-sortie.

### Gangs
Grades, membres, points HQ, stockage `core_creator_gang_members` (+ SetGang QB/Qbox).

### Apartments
Achat, routing buckets, coloc/invités, entrée/sortie, historique propriétaire.

### Robberies
Étapes, police min, cooldowns, alarmes, récompenses — état autoritaire serveur.

## Placement 3D

Depuis l’éditeur NUI → **Placement 3D** :

- Caméra libre WASD + souris
- Q/E = heading
- Shift = précision
- Entrée = confirmer
- Retour / Échap = annuler

## Exports serveur

```lua
exports['core_creator']:IsAdmin(src)
exports['core_creator']:CanUseModule(src, 'shops')
exports['core_creator']:GetShop(idOrName)
exports['core_creator']:GetJob(idOrName)
exports['core_creator']:GetGang(idOrName)
exports['core_creator']:GetGarage(idOrName)
exports['core_creator']:GetApartment(idOrName)
exports['core_creator']:GetRobbery(idOrName)
exports['core_creator']:GetFarm(idOrName)
exports['core_creator']:GetBlip(idOrName)
exports['core_creator']:HasVehicleKey(src, plate)
exports['core_creator']:IsVehicleOwner(src, plate)
exports['core_creator']:ReloadModule('shops')
exports['core_creator']:CreateEntity('shops', entityTable, 'api')
exports['core_creator']:DeleteEntity('shops', id)
exports['core_creator']:GetCreatedJobs()
exports['core_creator']:GetGangMembers(gangName)
exports['core_creator']:PlayerGang(src)
exports['core_creator']:Log(src, action, module, entityId, payload)
```

## Événements utiles

```lua
-- Serveur
AddEventHandler('core_creator:entityChanged', function(module, action, id) end)
AddEventHandler('core_creator:databaseReady', function() end)

-- Client
RegisterNetEvent('core_creator:syncModule', function(module) end)
```

## Architecture

```
core_creator/
├── fxmanifest.lua
├── config.lua
├── shared/          # bridge, utils, locales, validator
├── client/          # NUI, placement, preview, modules runtime
├── server/          # permissions, database, logger, CRUD, modules
├── web/             # React + TS + Vite (source + dist)
├── locales/         # fr.json / en.json
├── sql/             # core_creator.sql
└── exports/         # fichiers import/export
```

## Créer un nouveau module

1. Ajouter la table SQL sur le modèle existant (`name`, `label`, `coords`, `data`, `active`, audit fields).
2. Activer dans `Config.Modules`.
3. Ajouter `server/modules/mymodule.lua` + `client/modules/mymodule.lua`.
4. Enregistrer via `CoreCreator.RegisterModule('mymodule', { ... })`.
5. Ajouter le label NUI dans `web/src/App.tsx` (`MODULE_LABELS`).
6. Rebuild NUI : `npm run build`.

## Sécurité

- Permissions vérifiées **serveur** (ACE + framework)
- Distances, items, argent, cooldowns côté serveur
- Requêtes préparées oxmysql
- Validation centralisée (`Validator` / `ServerValidator`)
- Webhooks Discord uniquement serveur
- Pas de confiance aux payloads NUI

## Compilation NUI

```bash
cd web
npm install
npm run build
# sortie → web/dist (servie par fxmanifest ui_page)
```

Dev hot-reload (hors jeu) :

```bash
cd web
npm run dev
```

## Dépannage

| Problème | Solution |
|----------|----------|
| NUI blanche | `npm run build` puis `ensure core_creator` |
| Permission refusée | ACE `core_creator.admin` ou groupe admin framework |
| Tables manquantes | Importer `sql/core_creator.sql` |
| Callbacks KO | Installer `ox_lib` ou utiliser le bridge event fallback |
| Items non donnés | Vérifier `Config.Inventory` / ox_inventory |
| Clés KO | Configurer `Config.VehicleKeys` ou utiliser le système interne |

## Licence

Usage libre sur votre serveur. Adaptez selon vos besoins.
