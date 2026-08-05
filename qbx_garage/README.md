# qbx_garage

Garage véhicules **Qbox** avec menus **ox_lib**.

## Prérequis

- `qbx_core`
- `oxmysql`
- `ox_lib`
- Table `player_vehicles`
- Optionnel : `qbx_vehiclekeys`, `ox_fuel` / `LegacyFuel`

## Installation

```cfg
ensure qbx_core
ensure oxmysql
ensure ox_lib
ensure qbx_garage
```

Compatible avec les véhicules achetés via `qbx_concessionnaire`.

## Fonctions

- Garages publics configurables
- Fourrière (paiement)
- Sortie / rangement
- Sauvegarde fuel / moteur / carrosserie / mods
- Anti double-sortie
- Remise en garage des véhicules `state = 0` au restart ressource
- Menus ox_lib + TextUI

## Utilisation

- Aller sur un blip garage → **E**
- À pied : liste des véhicules
- En voiture (conducteur) : rangement
- Fourrière : récupération payante
- Commande test : `/garage [nom]` (ex: `/garage pillbox`)

## États DB

| state | Signification |
|------:|---------------|
| 0 | Sorti |
| 1 | En garage |
| 2 | Fourrière |

## Config

Éditez `config.lua` → `Config.Garages` :

```lua
{
    name = 'pillbox',
    label = 'Garage Pillbox',
    type = 'public', -- public | job | gang | impound
    menu = vector3(...),
    store = vector3(...),
    spawns = { vector4(...), ... },
    impoundPrice = 500, -- si type impound
    job = 'police',     -- si type job
    gang = 'ballas',    -- si type gang
}
```

## Exports

```lua
exports['qbx_garage']:OpenGarage('pillbox')
```
