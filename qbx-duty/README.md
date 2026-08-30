# qbx-duty

Système **global** de prise de service / hors service pour toutes les entreprises Qbox.

Une seule ressource centrale — les scripts métier (`qbx-mechanic`, `qbx-police`, etc.) consomment les exports au lieu de réimplémenter le duty.

## Dépendances

- `qbx_core`
- `ox_lib`
- `ox_target`
- `oxmysql`

## Installation

```cfg
ensure qbx_core
ensure ox_lib
ensure ox_target
ensure oxmysql
ensure qbx-duty
```

SQL `duty_logs` importé automatiquement si `Config.TrackDutyTime = true`.

## Configuration

Tout se configure dans `config.lua` :

- `Config.Jobs` — entreprises, sprites, couleurs, `showOffDuty`, `showPlayerName`
- `Config.DutyPoints` — points ox_target par job
- `Config.Visibility` — qui voit quels employés sur la map
- `Config.Blips.updateInterval` — sync coords (défaut 2000 ms)

### Ajouter une entreprise

```lua
restaurant = {
    label = 'Restaurant',
    enabled = true,
    duty = true,
    blips = true,
    showOffDuty = true,
    onDuty = { sprite = 93, color = 2, scale = 0.70 },
    offDuty = { sprite = 93, color = 1, scale = 0.65 },
},

Config.DutyPoints.restaurant = { vec3(x, y, z) }

Config.Visibility.restaurant = { restaurant = true }
```

Aucune modification de code requise.

## Map — blips dynamiques

| Statut | Couleur | Signification |
|--------|---------|---------------|
| En service | `2` (vert) | 🟢 |
| Hors service | `1` (rouge) | 🔴 |

- Blip créé **une seule fois**, puis coords / couleur / nom mis à jour
- `showOffDuty = false` → disparaît de la map hors service
- Nom : `John | Police | En service` si `showPlayerName = true`

## Prise de service

ox_target aux `Config.DutyPoints` :

- 🟢 Prendre son service
- 🔴 Quitter son service

Validations **serveur** : job, distance au point, autorisation.

## State bags

```lua
LocalPlayer.state.duty      -- bool
LocalPlayer.state.dutyJob   -- string

Player(source).state.duty
Player(source).state.dutyJob
```

## Exports client

```lua
exports['qbx-duty']:IsOnDuty()
exports['qbx-duty']:GetDuty()
exports['qbx-duty']:SetDuty(true)
exports['qbx-duty']:GetOnDutyCount('police')
exports['qbx-duty']:GetEmployeesOnDuty('mechanic')
exports['qbx-duty']:IsJobOnDuty('ambulance')
```

## Exports serveur

```lua
exports['qbx-duty']:IsOnDuty(source)
exports['qbx-duty']:SetDuty(source, true)
exports['qbx-duty']:GetDuty(source)
exports['qbx-duty']:GetEmployeesOnDuty('police')
exports['qbx-duty']:GetOnDutyCount('police')
exports['qbx-duty']:IsJobOnDuty('police')
exports['qbx-duty']:ToggleDuty(source)
```

## Intégration métier

```lua
if not exports['qbx-duty']:IsOnDuty() then
    lib.notify({ description = 'Vous devez être en service.', type = 'error' })
    return
end
```

## Events

| Event | Côté |
|-------|------|
| `qbx-duty:client:onDuty` | client |
| `qbx-duty:client:offDuty` | client |
| `qbx-duty:client:updateBlips` | client |
| `qbx-duty:server:setDuty` | server |

## Temps de service

`Config.TrackDutyTime = true` → table `duty_logs` (clock_in, clock_out, duration).

## Sécurité & perf

- Source de vérité : **serveur**
- Coords lues côté serveur (`GetEntityCoords`)
- Pas de boucle `Wait(0)`
- Sync ciblée aux viewers autorisés
- Suppression blip à la déconnexion / changement de job
