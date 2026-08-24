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

## SQL (obligatoire)

Importe **une** de ces options sur ta base Qbox :

```bash
# recommandé (racine du repo)
mysql -u USER -p DATABASE < sql/qbox_vehicles.sql

# ou depuis la ressource garage
mysql -u USER -p DATABASE < qbx_garage/sql/player_vehicles.sql
```

Fichiers :

| Fichier | Usage |
|---------|--------|
| `sql/qbox_vehicles.sql` | Install complète |
| `qbx_garage/sql/player_vehicles.sql` | Création table |
| `qbx_garage/sql/migrations.sql` | Colonnes manquantes si table déjà existante |

### États

| state | Signification |
|------:|---------------|
| 0 | Sorti |
| 1 | En garage |
| 2 | Fourrière |

## Fonctions

- Garages publics configurables
- Fourrière (paiement)
- Sortie / rangement
- Sauvegarde fuel / moteur / carrosserie / mods
- Anti double-sortie
- Remise en garage des véhicules `state = 0` au restart ressource
- Menus ox_lib + TextUI

## Utilisation

- **Point rouge** au sol → **E** ouvre le menu
- **Points verts** = places de spawn / rangement
- À pied sur le rouge : liste des véhicules
- En voiture près d’un vert : ranger le véhicule
- Fourrière : récupération payante
- Commande test : `/garage [nom]` (ex: `/garage pillbox`)

## Config

Éditez `config.lua` → `Config.Markers` + `Config.Garages` :

```lua
{
    name = 'pillbox',
    label = 'Garage Pillbox',
    type = 'public', -- public | job | gang | impound
    menu = vector3(...),          -- point rouge
    parks = { vector4(...), ... }, -- points verts
    impoundPrice = 500, -- si type impound
    job = 'police',     -- si type job
    gang = 'ballas',    -- si type gang
}
```

## Exports

```lua
exports['qbx_garage']:OpenGarage('pillbox')
```
