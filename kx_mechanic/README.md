# kx_mechanic

Système mécanicien professionnel pour **Qbox**, avec diagnostic NUI, réparations, ponts élévateurs, performances, entretien, stock, facturation, commandes et tableau de bord.

Inspiré des concepts visibles dans les showcases mécaniciens modernes — **aucun code propriétaire n’a été copié**.

## Dépendances

| Ressource     | Obligatoire |
|---------------|-------------|
| `qbx_core`    | Oui         |
| `ox_lib`      | Oui         |
| `ox_target`   | Oui         |
| `ox_inventory`| Oui         |
| `oxmysql`     | Oui         |

Optionnel : `Renewed-Banking` ou `qbx_management` pour le compte société.

## 1. Installation

1. Copiez le dossier `kx_mechanic` dans `resources/[kx]/` (ou votre dossier custom).
2. Ajoutez dans `server.cfg` :

```cfg
ensure oxmysql
ensure ox_lib
ensure ox_target
ensure ox_inventory
ensure qbx_core
ensure kx_mechanic
```

3. Redémarrez le serveur (ou `ensure kx_mechanic` après SQL + items).

## 2. Installation SQL

Exécutez le fichier :

```
kx_mechanic/sql/install.sql
```

via HeidiSQL, phpMyAdmin, ou :

```bash
mysql -u USER -p DATABASE < kx_mechanic/sql/install.sql
```

Les tables sont aussi créées automatiquement au démarrage de la ressource (migration soft).

Tables créées :

- `kx_mechanic_vehicles`
- `kx_mechanic_repairs`
- `kx_mechanic_invoices`
- `kx_mechanic_orders`
- `kx_mechanic_stock_log`
- `kx_mechanic_stats`
- `kx_mechanic_employees`

## 3. Items ox_inventory

Fusionnez le contenu de `install/ox_inventory_items.lua` dans `ox_inventory/data/items.lua`.

Items :

- `engine_part`, `brake_part`, `transmission_part`, `suspension_part`, `clutch_part`
- `repair_kit`, `tire`, `oil`, `battery`, `radiator`
- `spark_plug`, `cleaning_kit`, `body_kit`

Puis redémarrez `ox_inventory`.

## 4. Configuration Qbox

Le framework attend `exports.qbx_core` :

- `GetPlayer` / `GetPlayerByCitizenId`
- `AddMoney` / `RemoveMoney` / `GetMoney`
- `SetJob` / `SetJobDuty`

Aucune dépendance ESX/QBCore legacy n’est requise.

## 5. Configuration job

Ajoutez le job depuis `install/qbox_job.lua` dans `qbx_core/shared/jobs.lua` :

| Grade | Label                 |
|-------|-----------------------|
| 0     | Stagiaire             |
| 1     | Mécanicien            |
| 2     | Mécanicien confirmé   |
| 3     | Chef d’équipe         |
| 4     | Patron                |

Permissions configurables dans `config.lua` → `Config.Permissions`.

## 6. Configuration locations

Éditez `Config.Locations` dans `config.lua` :

- `shop` — zone atelier
- `duty` — prise de service
- `boss` — gestion
- `stash` — coffre entreprise
- `craft` / `tools` — établi & outils

Coordonnées par défaut : **Los Santos Customs** (Benny’s/LSC vanilla).

## 7. Configuration ponts

```lua
Config.Lifts = {
    {
        id = 'lsc_lift_1',
        coords = vector3(...),
        heading = 250.0,
        type = 'hydraulic',
        raiseHeight = 2.2,
        ...
    },
}
```

Actions ox_target : monter, élever, descendre, travailler, libérer.

Synchronisation via `GlobalState` + event client pour tous les joueurs.

## 8. Configuration facturation

```lua
Config.EnableBilling = true
Config.InvoiceTimeout = 120
Config.SocietyAccount = 'mechanic'
Config.UseSocietyFunds = true
```

Système interne de factures (MySQL). Le client paie cash ou banque. Le montant est crédité au compte société si disponible.

## 9. Fonctionnalités

- Diagnostic NUI (moteur, carrosserie, transmission, freins, suspension, pneus, fluides, température)
- Réparations : moteur, carrosserie, freins, transmission, suspension, embrayage, radiateur, phares…
- Entretien : vidange, batterie, bougies, nettoyage
- Pneus : réparation, remplacement, sport / drift / offroad / race
- Performance : moteur 1-4, freins, transmission, suspension, turbo, blindage
- Carrosserie : portes, capot, coffre, vitres, peintures, jantes
- Usure progressive (km, conduite agressive, température)
- Stock ox_inventory + historique
- Commandes fournisseur (pending → preparing → shipping → delivered)
- Employés (recruter / licencier / grades)
- Dashboard CA / réparations / graphiques / stock faible
- Historique des interventions
- Sécurité serveur (prix, grades, items, cooldowns)

## 10. Commandes de test

En jeu (avec job mechanic grade 4 recommandé) :

```
/mechanic          — ouvre le menu (aussi F6)
```

Via console admin Qbox (exemples) :

```
setjob [id] mechanic 4
```

Donner des items de test :

```
giveitem [id] repair_kit 10
giveitem [id] engine_part 5
giveitem [id] tire 4
giveitem [id] oil 5
giveitem [id] battery 2
giveitem [id] body_kit 5
```

Scénario de test rapide :

1. `setjob` mechanic 4 + prise de service
2. Approcher un véhicule → **Diagnostiquer**
3. Lancer une réparation moteur
4. Tester le pont élévateur
5. Créer une facture vers un joueur proche
6. Passer une commande de pièces (patron)
7. Ouvrir le tableau de bord

## 11. Dépannage

| Problème | Solution |
|----------|----------|
| Menu ne s’ouvre pas | Vérifier job `mechanic` + duty |
| “Pièces nécessaires” | Ajouter les items ox_inventory |
| Stash vide / inaccessible | Grade stock + `RegisterStash` au start |
| SQL errors | Exécuter `sql/install.sql`, vérifier oxmysql |
| Pont non sync | Vérifier `Config.EnableLifts` et network control |
| Facture non reçue | Client à moins de 10 m |
| Perf mods non visibles | `SetVehicleModKit` + véhicule streamé compatible |

Debug :

```lua
Config.Debug = true
```

## Structure

```
kx_mechanic/
├── fxmanifest.lua
├── config.lua
├── client/
├── server/
├── shared/
├── web/
├── sql/
├── install/
└── README.md
```

## Sécurité

Toutes les actions sensibles sont validées **côté serveur** :

- prix / services depuis `Config` uniquement
- permissions par grade
- items retirés uniquement à la fin d’une intervention réussie
- cooldowns anti-spam
- pas de confiance aux montants envoyés par le NUI

## Licence

Ressource originale créée pour votre serveur. Adaptez librement la configuration.