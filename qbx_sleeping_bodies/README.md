# qbx_sleeping_bodies

Corps persistants endormis à la déconnexion pour **QBox / qbx_core** + OneSync.

## Installation

1. Place `qbx_sleeping_bodies` dans tes resources
2. Importe `sql/sleeping_bodies.sql` (auto au start aussi)
3. `server.cfg` :

```cfg
ensure oxmysql
ensure ox_lib
ensure qbx_core
ensure ox_target          # optionnel
ensure illenium-appearance # ou fivem-appearance / qb-clothing
ensure qbx_sleeping_bodies
```

## Fonctionnement

| Événement | Action |
|-----------|--------|
| Déconnexion / crash / timeout | Ped allongé + SQL |
| Reconnexion | Corps supprimé |
| Restart ressource / serveur | Corps restaurés depuis MySQL |
| Routing bucket | Visibilité filtrée par bucket |

## Admin

`/sleepingbodies` — menu ox_lib (groupes `Config.AdminGroups` ou ace `qbx_sleeping_bodies.admin`)

- Lister / rechercher
- Supprimer un ou tous
- Se TP au corps / TP le corps ici

## Config clé

Voir `config.lua` : animation, offsets, noms 3D, ox_target, système d’apparence (`auto`).

## Exports

```lua
-- Serveur
exports.qbx_sleeping_bodies:RemoveSleepingBody(citizenid)

-- Client
exports.qbx_sleeping_bodies:PlaySleepingAnimation(ped)
exports.qbx_sleeping_bodies:ApplyPlayerAppearance(ped, appearance)
```
