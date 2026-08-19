# Rex Diner v2.0.0

Script restaurant **Qbox** complet — tablette NUI, craft, ventes, factures, stock, livraisons.

Stack : `qbx_core` · `ox_inventory` · `ox_lib` · `ox_target` · `oxmysql`

Sans ESX / QBCore legacy / RageUI / MenuV.

---

## Installation

1. Placez `rex_diner` dans vos resources
2. Importez `sql/rex_diner.sql`
3. Ajoutez le job : `install/qbox_job.lua` → `qbx_core/shared/jobs.lua`
4. Ajoutez les items : `install/ox_inventory_items.lua` → `ox_inventory/data/items.lua`
5. Configurez les positions dans `config.lua`
6. `server.cfg` :

```cfg
ensure oxmysql
ensure ox_lib
ensure ox_target
ensure ox_inventory
ensure qbx_core
ensure rex_diner
```

## Commandes

| Action | Touche / commande |
|--------|-------------------|
| Tablette | `F6` / `/diner` |
| Service | Vestiaire (ox_target) |
| Cuisine | Zone cuisine |
| Caisse | Zone caisse |

## Grades

0 Stagiaire · 1 Employé · 2 Cuisinier · 3 Manager · 4 Patron

Permissions dans `Config.Permissions`. Commissions dans `Config.Commission`.

## Multi-restaurants

Ajoutez une entrée dans `Config.Restaurants` avec `job`, `label`, `locations`, `stash`.

## Sécurité

- Prix / montants / commissions calculés **uniquement serveur**
- Job & grade via `qbx_core:GetPlayer`
- Distance client vérifiée
- Cooldowns anti-spam
- SQL préparées (oxmysql)

## Dépannage

- Tablette fermée → job / permission `tablet`
- Craft KO → items ox_inventory + stock SQL + grade
- Paiement KO → distance / fonds client
- Target absent → coords `config.lua` + `ox_target`

## Structure

```
rex_diner/
├── fxmanifest.lua · config.lua
├── shared/ · client/ · server/
├── web/ · sql/ · install/
└── README.md
```
