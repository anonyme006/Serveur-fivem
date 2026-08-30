# core_garage

Garage premium pour **ESX Legacy 1.12+** — public, personnel, entreprise, métier, fourrière, bateau, avion, hélicoptère.

## Dépendances

- `es_extended` (ESX Legacy)
- `oxmysql`
- `ox_lib`
- `ox_target`
- `menuv` (ThymonA/menuv)
- OneSync Infinity
- Lua 5.4

## Installation

1. Copier le dossier `core_garage` dans `resources/[local]/`
2. Importer `sql/install.sql` **ou** démarrer la ressource (création auto des tables)
3. Dans `server.cfg` :

```cfg
ensure es_extended
ensure oxmysql
ensure ox_lib
ensure ox_target
ensure menuv
ensure core_garage
```

4. Configurer `config.lua` (garages, prix, blips, jobs, UI, MenuV…)

## MenuV (style Marlowe Vineyard)

Par défaut, `core_garage` utilise **MenuV** pour l’interface joueur et l’admin (comme Marlowe Vineyard).

```lua
Config.MenuV = {
    enabled = true,
    garageInterface = 'menuv',  -- 'menuv' | 'nui'
    adminInterface = 'menuv',   -- 'menuv' | 'ox_lib'
    Position = 'bottomright',
    Theme = 'native',
    Size = 'size-125',
    Colors = { Red = 56, Green = 189, Blue = 248 },
}
```

- **Garage** : menu principal → « Mes véhicules » (liste dynamique) + « Ranger le véhicule »
- **Admin** : `/garageadmin` → navigation MenuV (formulaires via ox_lib inputDialog)
- Pour retrouver la **NUI premium**, mettre `garageInterface = 'nui'`

## Fonctionnalités

| Module | Détail |
|--------|--------|
| Garages | 8 types, blips/markers, accès job/gang, activation SQL |
| NUI | Image, plaque, moteur/carrosserie/essence, km, assurance, statut, recherche, tri |
| MenuV | Interface garage + admin style Marlowe Vineyard (configurable) |
| Sortie | ProgressBar, anim portail, spawn OneSync, anti-dupe, props complets, clés |
| Rangement | `ox_target` sans être assis, moteur coupé, sauvegarde complète |
| Fourrière | Véhicule détruit → fourrière, prix/délai, réduction assurance |
| Entreprise | Flotte partagée, grades, max sortis, logs |
| Admin | `/garageadmin` — CRUD garage, spawn, retour, blip (SQL) |

## Architecture

```
core_garage/
├── fxmanifest.lua
├── config.lua
├── shared/utils.lua
├── locales/fr.lua | en.lua
├── client/          # main, garage, spawn, store, admin, nui
├── server/          # database, security, garage, spawn, store, impound, company, admin
├── html/            # NUI moderne responsive
└── sql/install.sql
```

## Sécurité

- Callbacks `ox_lib` uniquement (pas d’events métier ouverts)
- Validation propriétaire / entreprise serveur
- Distance + NetID vérifiés
- Lock plaque anti-duplication (sortie / rangement)
- Rate-limit actions

## Admin

Commande : `/garageadmin` (groupes `Config.Admin.groups` ou ACE `core_garage.admin`)

- Créer / modifier / supprimer / activer
- Déplacer menu, spawn, retour
- Configurer blip
- Créer fourrière & garage entreprise

## Exports

**Serveur**

```lua
exports['core_garage']:RegisterVehicle({ owner = identifier, plate = 'ABC123', props = {}, garage = 'legion_public', type = 'car' })
exports['core_garage']:ImpoundVehicle(plate, reason, fee, minutes, impoundGarage)
exports['core_garage']:GetVehicleByPlate(plate)
exports['core_garage']:SetVehicleStored(plate, true, 'legion_public')
```

**Client**

```lua
exports['core_garage']:OpenGarage('legion_public')
exports['core_garage']:StoreVehicle(vehicleEntity)
```

## Clés véhicules

À la sortie, déclenche `Config.General.keysEvent` (défaut `core_garage:client:giveKeys`) + hooks `vehiclekeys:client:SetOwner` / `esx_core:giveVehicleKeys`.  
Option : `Config.General.keysExport = 'wasabi_carlock'`.

## Optimisation

- Aucune boucle inutile au repos (markers en sleep dynamique)
- `ox_target` zones + global vehicle
- Statebags propriétaire / plaque
- Cache garages mémoire serveur

## Licence

Usage serveur RP — adapter librement à votre base.
