# Rex Diner

Script restaurant complet pour **FiveM Qbox** avec tablette NUI moderne.

Technologies : `qbx_core` · `ox_inventory` · `ox_lib` · `ox_target` · `oxmysql`

> Ne nécessite **pas** ESX, QBCore legacy, RageUI ni MenuV.

---

## 1. Installation

1. Copiez le dossier `rex_diner` dans vos resources (`resources/[jobs]/rex_diner` par ex.).
2. Importez le SQL : `sql/rex_diner.sql`
3. Ajoutez le job Qbox depuis `install/qbox_job.lua`
4. Ajoutez les items ox_inventory depuis `install/ox_inventory_items.lua`
5. Dans `server.cfg` :

```cfg
ensure oxmysql
ensure ox_lib
ensure ox_target
ensure ox_inventory
ensure qbx_core
ensure rex_diner
```

6. Configurez les positions dans `config.lua` → `Config.Restaurants.rex_diner.locations`
7. Redémarrez le serveur

---

## 2. Dépendances

| Resource     | Rôle                          |
|-------------|-------------------------------|
| qbx_core    | Joueurs, jobs, argent         |
| ox_inventory| Items, stash, craft           |
| ox_lib      | Callbacks, progress, notify, menus |
| ox_target   | Interactions zones            |
| oxmysql     | Base de données               |

Optionnel : compte société via `Renewed-Banking` ou `qbx_management` (détection automatique).

---

## 3. Installation SQL

Exécutez `sql/rex_diner.sql` dans votre base MySQL/MariaDB.

Tables créées :

- `rex_diner_sales` / `rex_diner_sale_items`
- `rex_diner_employees`
- `rex_diner_invoices`
- `rex_diner_stock`
- `rex_diner_orders` / `rex_diner_order_items`
- `rex_diner_deliveries`
- `rex_diner_service`
- `rex_diner_settings`

---

## 4. Configuration

Fichier principal : `config.lua`

```lua
Config.Job = 'rex_diner'
Config.TabletCommand = 'diner'
Config.TabletKey = 'F6'
Config.PaymentDistance = 5.0
Config.Currency = '$'
```

Flags :

- `Config.EnableBilling`
- `Config.EnableDeliveries`
- `Config.EnableCrafting`
- `Config.EnableEmployeeManagement`
- `Config.EnableStock`

Commissions par grade : `Config.Commission`  
Permissions : `Config.Permissions`

---

## 5. Items ox_inventory

Fusionnez le contenu de `install/ox_inventory_items.lua` dans `ox_inventory/data/items.lua`.

Ingrédients : `bread`, `meat`, `cheese`, `lettuce`, `tomato`, `potato`, `oil`, `flour`, `sugar`, `milk`, `coffee_bean`, `cola_syrup`, `water`

Produits : `burger_classic`, `burger_dino`, `rex_fries`, `rex_dessert`, `rex_coffee`, `rex_cola`, `rex_plat`, `formula_mini_dino`, `formula_jurassic_royal`

Ajoutez des images PNG dans `ox_inventory/web/images/` si besoin.

---

## 6. Configuration du job

Ajoutez le job `rex_diner` dans Qbox (`qbx_core/shared/jobs.lua`) via `install/qbox_job.lua`.

Grades :

| Grade | Label     |
|------:|-----------|
| 0     | Stagiaire |
| 1     | Employé   |
| 2     | Cuisinier |
| 3     | Manager   |
| 4     | Patron    |

Donner le job en jeu (exemple admin) :

```
/setjob [id] rex_diner 1
```

---

## 7. Recettes

Fichier : `shared/recipes.lua`

Chaque recette définit :

- `label`, `time`, `grade`
- `ingredients` (items ox_inventory ou stock restaurant)
- `result` (item + amount)

La vérification est **100 % serveur** (job, grade, ingrédients, inventaire).

---

## 8. Produits

Fichier : `shared/products.lua`

Champs : `label`, `price`, `category`, `item`, `recipe`, `prepTime`, `available`, `sellable`

Les prix utilisés en caisse viennent **uniquement** de ce fichier (jamais du client).

---

## 9. Positions

Dans `Config.Restaurants.<key>.locations` :

- `Boss`, `Kitchen`, `Cashier`, `Storage`, `Cloakroom`, `Delivery`

Chaque zone utilise `ox_target` (box zone).

Adaptez les `vector3` à votre MLO diner.

---

## 10. Commandes

| Commande / touche | Action                |
|-------------------|-----------------------|
| `/diner`          | Ouvrir/fermer tablette|
| `F6` (configurable)| Mapping tablette     |
| Vestiaire (target)| Service on/off        |
| Cuisine (target)  | Menu recettes         |
| Caisse (target)   | Tablette caisse       |
| Stock (target)    | Stash ox_inventory    |

---

## 11. Permissions

Selon `Config.Permissions` :

- Stagiaire : tablette + ventes
- Employé : + recettes + factures
- Cuisinier : + cuisine
- Manager : + employés + stock + commandes + livraisons
- Patron : + finances + settings

---

## 12. Multi-restaurants

Ajoutez une entrée dans `Config.Restaurants` :

```lua
Config.Restaurants.burger_shot = {
    job = 'burgershot',
    label = 'Burger Shot',
    locations = { ... },
    stash = { id = 'burgershot_storage', label = 'Stock Burger Shot', slots = 80, weight = 200000 },
}
```

Le script résout automatiquement le restaurant via le job du joueur.

---

## 13. Flux joueur

1. Entrer au Rex Diner  
2. Prendre son service (vestiaire / tablette)  
3. Ouvrir la tablette (`F6`)  
4. Consulter le dashboard  
5. Préparer des recettes en cuisine (ingrédients inventaire ou stock)  
6. Ajouter des produits au ticket  
7. Sélectionner un client proche  
8. Faire payer (cash / banque) ou facturer  
9. Commission + stats MySQL mises à jour  

---

## 14. Sécurité

- Prix / montants / commissions recalculés serveur
- Job & grade lus via `exports.qbx_core:GetPlayer`
- Distance client vérifiée
- Cooldowns anti-spam (`Config.Cooldowns`)
- Requêtes SQL préparées (oxmysql)

---

## 15. Dépannage

**La tablette ne s'ouvre pas**  
→ Vérifiez que le joueur a le job configuré et la permission `tablet`.

**Craft échoue**  
→ Vérifiez items ox_inventory + stock SQL + grade cuisine.

**Paiement refusé**  
→ Client trop loin (`Config.PaymentDistance`) ou fonds insuffisants.

**Zones target absentes**  
→ Coordonnées incorrectes dans `config.lua`, ou `ox_target` non démarré.

**SQL errors**  
→ Réimportez `sql/rex_diner.sql` et vérifiez oxmysql.

**Société non créditée**  
→ Installez Renewed-Banking / qbx_management ou désactivez `Config.EnableSocietyAccount`.

---

## Structure

```
rex_diner/
├── fxmanifest.lua
├── config.lua
├── shared/
├── client/
├── server/
├── web/
├── sql/
└── install/
```

Version : **1.0.0**
