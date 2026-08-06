# core_wholesaler

Grossiste centralisé pour serveurs **Qbox**.  
Toutes les entreprises achètent leurs marchandises dans un seul entrepôt.

## Dépendances

| Ressource | Requis |
|-----------|--------|
| [qbx_core](https://github.com/Qbox-project/qbx_core) | Oui |
| [ox_lib](https://github.com/overextended/ox_lib) | Oui |
| [ox_target](https://github.com/overextended/ox_target) | Oui |
| [ox_inventory](https://github.com/overextended/ox_inventory) | Oui |
| [oxmysql](https://github.com/overextended/oxmysql) | Oui |
| Renewed-Banking / qb-banking | Recommandé (paiement société) |

**Aucun ESX / QB Legacy.**

## Installation

1. Copier le dossier `core_wholesaler` dans `resources/[core]/` (ou équivalent).
2. Ajouter dans `server.cfg` :

```cfg
ensure oxmysql
ensure ox_lib
ensure ox_target
ensure ox_inventory
ensure qbx_core
ensure core_wholesaler

# Permission admin (bypass grade)
add_ace group.admin core_wholesaler.admin allow
```

3. Les tables SQL sont **créées automatiquement** au démarrage.  
   Schéma de référence : `sql/install.sql`.

4. Enregistrer le job `wholesaler` dans Qbox (voir ci-dessous).

5. Ajouter les items ox_inventory listés dans `install/items_example.lua`.

6. Configurer `config.lua` (positions, catégories, entreprises, banking).

## Job Qbox

Dans `qbx_core/shared/jobs.lua` (ou via votre système de jobs) :

```lua
['wholesaler'] = {
    label = 'Grossiste Central',
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        [0] = { name = 'Employé', payment = 50 },
        [1] = { name = 'Préparateur', payment = 75 },
        [2] = { name = 'Manager', payment = 100 },
        [3] = { name = 'Patron', isboss = true, payment = 150 },
    },
},
```

Créer aussi le compte société `wholesaler` dans votre banking (`Config.Payment.wholesalerAccount`).

## Fonctionnalités

### Entrepôt unique
- Accueil (PNJ)
- Zone de commande
- Zone de retrait
- Quai de chargement
- Bureau du responsable

### Menu ox_lib
- Acheter des marchandises
- Voir le stock disponible
- Historique des achats
- Mes commandes
- Retirer une commande
- Gestion des livraisons (transporteurs)
- Administration / Menu patron

### Catégories (configurables)
Alimentation · Restaurant · Mécano · EMS · Police · Station-service · Chantier

### PNJ hors service
Quand **aucun employé** du job `wholesaler` n’est en service (`onduty`), un PNJ vendeur permet aux entreprises d’acheter directement (remise immédiate des items, majoration configurable).  
Dès qu’un employé prend son service, le PNJ refuse la vente et renvoie vers l’accueil.

Configurable via `Config.NpcVendor` (position, modèle, majoration, `instantGive`).

### Cycle des commandes
`En attente` → `Préparée` → `Disponible` → `Retirée` / `Livrée`

Notification ox_lib quand la commande est prête.

### Paiement
- Compte société
- Banque personnelle
- Argent liquide  

TVA + taxe entreprise configurables.

### Livraison
Les jobs transporteurs (`trucker`, `delivery`, `logistics`) peuvent prendre les commandes en mode livraison, charger au quai et déposer chez le client.

### Export
Les employés du grossiste expédient des cargaisons vers **Port**, **Gare** ou **Aéroport** (paiement élevé).

### Boss
CA, bénéfices, commandes, entreprises clientes, stock, prix, recrutement / licenciement.

## Configuration rapide

Fichier principal : `config.lua`

| Clé | Description |
|-----|-------------|
| `Config.Warehouse` | Positions, PNJ, blips, zones |
| `Config.Categories` | Produits, prix, stock initial |
| `Config.AllowedCompanies` | Jobs autorisés → catégories |
| `Config.Payment.banking` | `renewed` / `qb-banking` / `qbx_management` |
| `Config.Tax` | TVA + taxe |
| `Config.Orders.prepareBase` | Temps de préparation |
| `Config.Delivery.jobs` | Jobs livreurs |
| `Config.Export.destinations` | Points d’export |

## Structure

```
core_wholesaler/
├── fxmanifest.lua
├── config.lua
├── client/          # zones, menus, delivery, export, boss
├── server/          # database, stock, orders, payment, …
├── shared/          # utilitaires
├── locales/         # fr / en
├── sql/             # schéma de référence
└── install/         # exemples job / items
```

## Optimisation

- Zones via **ox_target** (pas de boucle de proximité au repos)
- Threads client actifs uniquement pendant une livraison / export
- Cache stock serveur en mémoire
- Objectif : **0.00 ms** au repos

## Tables SQL

- `wholesaler_stock`
- `wholesaler_orders`
- `wholesaler_products`
- `wholesaler_history`
- `wholesaler_employees`
- `wholesaler_companies`
- `wholesaler_exports` (exports)
