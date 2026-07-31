# esx_gruppe6

Job **Gruppe 6** pour serveur **ESX** — convois de fonds entre magasins, banques, armureries et grossistes.

## Dépendances

- `es_extended`
- `esx_addonaccount` (compte société)
- `oxmysql`
- `ox_lib`
- `ox_target`
- `ox_inventory`

## Installation

1. Copier `esx_gruppe6/` dans votre dossier `resources`
2. Exécuter `sql/gruppe6.sql` sur votre base ESX
3. Ajouter l'item `money_bag` dans `ox_inventory/data/items.lua` :
   ```lua
   ['money_bag'] = { label = 'Sac de billets', weight = 2500, stack = false, close = true },
   ```
4. Dans `server.cfg` :
   ```
   ensure esx_addonaccount
   ensure esx_gruppe6
   ```
5. Assigner le job : `/setjob [id] gruppe6 0`

## Gameplay

1. Aller au dépôt Gruppe 6 (Maze Bank West)
2. Prendre une tournée → fourgon + route GPS (3 à 6 arrêts)
3. Récupérer les sacs de billets à chaque arrêt
4. Revenir au dépôt → l'argent est versé sur **`society_gruppe6`**

## Commandes ingame (admin ou grade ≥ 1)

| Commande | Description |
|----------|-------------|
| `/g6addpoint magasin Mon 247` | Ajouter un point |
| `/g6delpoint 5` | Supprimer un point |
| `/g6togglepoint 5` | Activer / désactiver |
| `/g6listpoints` | Lister les points |

Types : `magasin`, `banque`, `armurerie`, `grossiste`

## Configuration

Tout est dans `config.lua` : dépôt, véhicule, rémunération par type, cooldown, points par défaut.

Les points ingame sont stockés en base (`esx_gruppe6_points`) et seedés automatiquement au premier démarrage.
