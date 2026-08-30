# Qbox Restaurants v2.1.0 — Horny's & Greasy Joe's

Script restaurant **Qbox** complet — tablette NUI, craft, ventes, factures, stock, livraisons.

Établissements configurés :
- **Horny's Burgers** (Mirror Park) — job `hornys`
- **Greasy Joe's Diner** (La Puerta) — job `greasy_joes`

Stack : `qbx_core` · `ox_inventory` · `ox_lib` · `ox_target` · `oxmysql`

Sans ESX / QBCore legacy / RageUI / MenuV.

---

## Installation

1. Placez `qbox-restaurants` dans vos resources
2. Importez `sql/qbox_restaurants.sql`
3. Ajoutez les jobs : `install/qbox_job.lua` → `qbx_core/shared/jobs.lua`
4. Ajoutez les items : `install/ox_inventory_items.lua` → `ox_inventory/data/items.lua`
5. Ajustez les positions dans `config.lua` selon vos MLO
6. `server.cfg` :

```cfg
ensure oxmysql
ensure ox_lib
ensure ox_target
ensure ox_inventory
ensure qbx_core
ensure qbox-restaurants
```

## Commandes

| Action | Touche / commande |
|--------|-------------------|
| Tablette | `F6` / `/restaurant` |
| Service | Vestiaire (ox_target) |
| Cuisine | Zone cuisine |
| Caisse | Zone caisse |

## Grades

0 Stagiaire · 1 Employé · 2 Cuisinier · 3 Manager · 4 Patron

Permissions dans `Config.Permissions`. Commissions dans `Config.Commission`.

## Multi-restaurants

Chaque établissement a son propre job, stock SQL, société et menu dans `Config.Restaurants`.
Les produits et recettes sont filtrés par restaurant via le champ `restaurants` dans `shared/products.lua` et `shared/recipes.lua`.

### MLO supportés

| Établissement | MLO recommandé | Emplacement |
|---------------|----------------|-------------|
| Horny's | Gabz / DRC Horny's | Mirror Park |
| Greasy Joe's | MXC Greasy Joe's Drive-in | La Puerta |

> Les coordonnées dans `config.lua` sont des points de départ. Ajustez-les in-game avec un outil coords si votre MLO diffère.

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
qbox-restaurants/
├── fxmanifest.lua · config.lua
├── shared/ · client/ · server/
├── web/ · sql/ · install/
└── README.md
```
