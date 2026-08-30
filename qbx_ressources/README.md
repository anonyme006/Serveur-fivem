# qbx_ressources

Pack **QBox unifié** — une seule resource pour tout le RP serveur.

Remplace / regroupe :

| Ancienne resource | Module |
|-------------------|--------|
| `qbx_rp_core` | `Config.Modules.core` |
| `qbx-duty` | `Config.Modules.duty` |
| `qbx_sleeping_bodies` | `Config.Modules.sleeping` |

## Installation

```cfg
ensure qbx_core
ensure oxmysql
ensure ox_lib
ensure ox_target
ensure ox_inventory
ensure qbx_ressources
```

SQL auto : `sql/qbx_ressources.sql` (clés, bâches, occasions, antennes, `duty_logs`, `sleeping_bodies`).

Items ox_inventory : voir `install/ox_items.lua` et `install/ox_items_antenna.lua`.

## Modules (`config/init.lua`)

```lua
Config.Modules = {
    core = true,       -- véhicules, clés, météo, réseau, discord…
    duty = true,       -- service + blips entreprises
    sleeping = true,   -- corps endormis à la déco
}
```

Configs détaillées :

- `config/core.lua`
- `config/duty.lua`
- `config/sleeping.lua`

## Core RP

Persistance `player_vehicles`, fourrière reboot, dégâts, clés + serrurier, portefeuille F4, bâche, occasions, carte Esc, alertes, offroad, météo, Discord, réseau téléphone.

```lua
exports.qbx_ressources:GiveVehicleKey(src, plate, label)
exports.qbx_ressources:HasNetworkSignal(source)
exports.qbx_ressources:DiscordLog('admin', 'Titre', 'Desc', { src = source })
```

## Duty (entreprises)

Blips 🟢 / 🔴, ox_target, visibilité par job, state bags.

```lua
-- Client
exports.qbx_ressources:IsOnDuty()
exports.qbx_ressources:SetDuty(true)
exports.qbx_ressources:GetOnDutyCount('police')

-- Serveur
exports.qbx_ressources:IsOnDuty(source)
exports.qbx_ressources:GetEmployeesOnDuty('mechanic')

-- State
LocalPlayer.state.duty
Player(source).state.duty
```

Intégration métier :

```lua
if not exports.qbx_ressources:IsOnDuty() then
    lib.notify({ description = 'Vous devez être en service.', type = 'error' })
    return
end
```

## Corps endormis

À la déconnexion : ped endormi persisté (MySQL + OneSync). Commande admin `/sleepingbodies`.

## Structure

```
qbx_ressources/
├── config/          init + core + duty + sleeping
├── client/core|duty|sleeping
├── server/core|duty|sleeping
├── shared/
├── html/            portefeuille + toast duty
├── install/         items ox_inventory
└── sql/qbx_ressources.sql
```

## Compat

`provide` pour `qbx_rp_core`, `qbx-duty`, `qbx_sleeping_bodies` — les dépendances anciennes trouvent cette resource.
Les exports se font désormais via `exports.qbx_ressources` (ou `exports['qbx_ressources']`).
