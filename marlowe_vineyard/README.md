# Marlowe Vineyard — Job Qbox + MenuV

Job FiveM complet pour **Marlowe Vineyard**, compatible **Qbox / qbx_core**, **ox_lib**, **ox_target**, **ox_inventory**, **oxmysql** et **MenuV**.

## Dépendances

Assurez-vous que ces ressources sont démarrées **avant** `marlowe_vineyard` :

```cfg
ensure oxmysql
ensure ox_lib
ensure qbx_core
ensure ox_inventory
ensure ox_target
ensure menuv
ensure marlowe_vineyard
```

## Installation

### 1. Copier la ressource

Placez le dossier `marlowe_vineyard/` dans votre répertoire `resources/`.

### 2. Base de données

Exécutez le fichier SQL :

```sql
source marlowe_vineyard/sql/marlowe.sql
```

Les tables sont aussi créées automatiquement au démarrage de la ressource.

### 3. Job Qbox

Ajoutez le job `marlowe` dans `qbx_core/shared/jobs.lua` (voir `install/qbx_job.lua`).

### 4. Items ox_inventory

Ajoutez les items du fichier `install/ox_inventory_items.lua` dans votre configuration ox_inventory (`data/items.lua`).

Items requis :

- `grape`
- `grape_juice`
- `wine_red` / `wine_white` / `wine_rose`
- `wine_bottle_filled`
- `wine_bottle_labeled`

### 5. Compte société

Créez un compte société `marlowe` dans votre système bancaire (Renewed-Banking, qb-banking, etc.).

### 6. MenuV

Utilisez une **version RELEASE** de MenuV (précompilée), pas les sources master.

## Utilisation

| Action | Méthode |
|--------|---------|
| Menu principal | `/marlowe` ou touche **F6** |
| Récolte | ox_target sur les vignes |
| Production | ox_target sur la cuve |
| Stock | ox_target sur l'entrepôt |
| Garage | ox_target au garage |
| Vestiaire | ox_target au vestiaire |
| Direction | ox_target au bureau (grade ≥ Responsable) |

## Structure

```
marlowe_vineyard/
├── fxmanifest.lua
├── config.lua
├── client/
│   ├── menu.lua          # Tous les menus MenuV
│   ├── main.lua
│   ├── vineyard.lua      # ox_target + récolte
│   ├── production.lua
│   ├── deliveries.lua
│   ├── garage.lua
│   ├── clothing.lua
│   └── boss.lua
├── server/
│   ├── database.lua
│   ├── main.lua
│   ├── production.lua
│   ├── deliveries.lua
│   ├── employees.lua
│   └── finances.lua
├── shared/
│   └── utils.lua
├── sql/
│   └── marlowe.sql
├── html/images/
│   └── Marlowe_Vineyard.png
└── install/
    ├── ox_inventory_items.lua
    └── qbx_job.lua
```

## Sécurité

Toutes les actions sensibles (items, commandes, employés, finances, récompenses) sont **validées côté serveur** :

- job `marlowe`
- grade minimum
- distance
- duty (si requis)
- inventaire

## Configuration

Modifiez `config.lua` pour ajuster :

- Coordonnées du vignoble
- Grades et permissions
- Recettes de production
- Véhicules du garage
- Couleurs MenuV (doré par défaut)
- Points de livraison

## MenuV

- Position principale : `centerright`
- Thème : `native`
- Couleur : RGB `(180, 130, 40)` — doré Marlowe
- Navigation via sous-menus (`value = submenu`)
- Événements `item:On('select', ...)`

**Aucun RageUI, qb-menu ou menu HTML custom.**

## Logo

Le logo `html/images/Marlowe_Vineyard.png` est référencé dans le manifest. Remplacez-le par votre logo officiel si nécessaire (MenuV utilise principalement titre + couleurs pour l'affichage).

## Exports

```lua
-- Client
exports.marlowe_vineyard:OpenMenu()
exports.marlowe_vineyard:IsMarloweEmployee()
```
