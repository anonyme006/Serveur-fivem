# ox_garage

Garage ESX avec **ox_lib** + barre **esx_progressbar** (capsule orange) pour le rangement et la sortie des véhicules.

## Dépendances

- `es_extended`
- `oxmysql`
- `ox_lib`
- `esx_progressbar`
- `ox_target` (optionnel — sinon markers + touche E)

## Installation

```cfg
ensure es_extended
ensure oxmysql
ensure ox_lib
ensure esx_progressbar
ensure ox_garage
```

Table attendue : `owned_vehicles` (ESX standard) avec colonnes `owner`, `plate`, `vehicle`, `stored`, et idéalement `parking` / `pound`.

Si besoin :

```sql
ALTER TABLE owned_vehicles ADD COLUMN IF NOT EXISTS parking VARCHAR(60) NULL;
ALTER TABLE owned_vehicles ADD COLUMN IF NOT EXISTS pound VARCHAR(60) NULL;
```

## Utilisation

- **À pied** au garage → liste des véhicules stockés → progress « Sortie du véhicule… »
- **En véhicule** (ou option « Ranger ») → progress « Rangement du véhicule… »
- **Fourrière** → caution configurable + progress de sortie

## Config

Voir `config.lua` — garages, fourrière, durées de progression, blips.
