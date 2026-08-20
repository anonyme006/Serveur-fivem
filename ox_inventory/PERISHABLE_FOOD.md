# Nourriture & boissons périssables (ox_inventory)

Les items alimentaires utilisent le système natif **degrade** / **decay** d’ox_inventory.

| Item | Durée (`degrade` en minutes) | Effet |
|------|------------------------------|--------|
| `fish`, `slaughtered_chicken` | 90 (1h30) | Disparaît une fois périmé |
| `alive_chicken` | 120 (2h) | idem |
| `burger`, `testburger` | 180 / 120 | idem |
| `packaged_chicken` | 240 (4h) | idem |
| `sprunk` | 360 (6h) | idem |
| `bread` / `Pain` | 480 (8h) | idem |
| `mustard` | 480 (8h) | idem |
| `water` / `Eau` | 720 (12h) | idem |

- `degrade` = durée de conservation en **minutes** (barre de durabilité dans l’inventaire)
- `decay = true` = l’item est **supprimé** à 0 %

Ajuste les valeurs dans `ox_inventory/data/items.lua`.

> Les items déjà en inventaire sans metadata de durabilité recevront le timer au prochain ajout / refresh selon ox_inventory. Pour forcer : vider/re-donner les items ou relog selon ta version.
