# qbx_shopcreator

Système complet de création et gestion de commerces pour **Qbox / QBX**, avec NUI React/TypeScript.

## Prérequis

| Ressource | Rôle |
|-----------|------|
| `qbx_core` | Joueurs, argent, permissions |
| `ox_lib` | Callbacks, notify, points, UI helpers |
| `ox_target` | Interactions monde |
| `ox_inventory` | Items, stash commerce |
| `oxmysql` | Persistance SQL |

Lua 5.4 (`lua54 'yes'`).

## Installation

1. Copier le dossier `qbx_shopcreator` dans `resources/` (ex. `resources/[qbx]/qbx_shopcreator`).
2. Importer le schéma SQL :

```bash
mysql -u USER -p DATABASE < qbx_shopcreator/sql/install.sql
```

Par défaut, `ServerConfig.AutoMigrate = true` exécute aussi `sql/install.sql` au démarrage (idempotent via `CREATE TABLE IF NOT EXISTS`).

3. Rebuild NUI si vous modifiez le front :

```bash
cd qbx_shopcreator/web
npm install
npm run build
```

Le runtime charge `web/dist/`.

4. `server.cfg` — ordre de démarrage recommandé :

```cfg
ensure oxmysql
ensure ox_lib
ensure ox_target
ensure ox_inventory
ensure qbx_core
ensure qbx_shopcreator
```

5. Permissions admin (ACE) :

```cfg
add_ace group.admin qbx_shopcreator.admin allow
```

Ou via permissions Qbox (`admin` / `god` dans `Config.AdminPermissions`), ou via l’onglet **Admins** de l’UI (citizenid / license).

## Commandes

| Commande | Description |
|----------|-------------|
| `/shopcreator` | Ouvre l’Administration Suite (admins uniquement). Configurable via `Config.AdminCommand`. |

## Configuration

Fichiers :

- `config/shared.lua` — commandes, limites, paiements, livraison, blips, NPC, rate limits, logs
- `config/server.lua` — auto-migrate, balance interne

Points importants :

- `Config.LowStockThreshold`
- `Config.MaxCategoriesPerShop` / `MaxProductsPerShop` / `MaxEmployeesPerShop`
- `Config.Delivery` (instant / self / public, récompense, pickup par défaut)
- `Config.Logging.webhook` pour Discord

## Fonctionnement — Shop Creator (admin)

1. `/shopcreator` → Collection / Create / Admins / Settings
2. Créer un commerce (étapes) : General → Ownership → Locations → Categories → Products → Access/NPC → Payments → Garage
3. Placer les points en jeu (**Use current position** / **Select position**)
4. Activer blip + NPC si besoin
5. Sauvegarder — synchro live sans restart

## Fonctionnement — Commerces

**Clients** : interaction `ox_target` sur point client / NPC → storefront → panier → cash/bank.  
Le serveur recalcule le total, vérifie ouverture / stock / argent / inventaire, décrémente le stock de façon atomique, crédite le commerce, journalise.

**Propriétaire / employés** : point management → Dashboard, catégories, produits, commandes stock, livraisons, stash, employés + permissions granulaires, personnalisation, garage.

**Livraisons** :

- Instant : stock ajouté immédiatement (permission `automatic_delivery`)
- Self : mission pour le staff (pickup → dropoff)
- Public : job visible pour les autres joueurs — acceptation atomique (`UPDATE ... WHERE status='open'`)

## Architecture

```
qbx_shopcreator/
├── fxmanifest.lua
├── config/ shared.lua, server.lua
├── shared/ constants.lua, utils.lua
├── client/ state, shops, targets, blips, npc, garage, delivery, nui, main
├── server/ repository, shops, purchases, employees, stock, deliveries, garage, security, logging, callbacks
├── web/    React + Vite + TypeScript (dist embarqué)
└── sql/    install.sql
```

APIs Qbox utilisées : `exports.qbx_core:GetPlayer`, `AddMoney`, `RemoveMoney`, `GetMoney`, `HasPermission`.

## Sécurité

- Toute logique argent / stock / permissions / ownership côté serveur
- Rate limiting sur events sensibles
- Décrément stock et claim livraison atomiques SQL
- Rollback achat si AddItem échoue
- Validation types / bornes / items ox_inventory

## Troubleshooting

| Problème | Piste |
|----------|--------|
| UI blanche | Rebuild `web` (`npm run build`), vérifier `ui_page` / `files` dans `fxmanifest.lua` |
| `/shopcreator` refuse | ACE `qbx_shopcreator.admin` ou permission Qbox / entrée Admins |
| Pas d’interaction | Points Locations manquants, commerce `enabled=false`, ox_target non démarré |
| Achat impossible | Magasin fermé / horaires, stock, cash/bank désactivé, item invalide |
| Stash vide | ox_inventory doit être démarré avant ; stash `shopcreator_<id>` enregistré au load |
| Livraison double | Normalement bloquée ; vérifier MySQL unique `uniq_job_order` + status |

Logs : console `[qbx_shopcreator]` si `Config.Logging.console` / `Config.Debug`, event `qbx_shopcreator:server:log`, webhook optionnel.

## Développement NUI (navigateur)

```bash
cd web && npm run dev
# ouvrir http://localhost:5173/?mode=admin|storefront|management|deliveries
```

Mocks dans `src/lib/mock.ts`.
