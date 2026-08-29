# qbx-mechanic

Système mécanicien professionnel pour serveurs **Qbox** — réparations, diagnostic, tuning, facturation, stock, ponts élévateurs et gestion d'entreprise.

> **État actuel : Étape 1** — Base resource, configuration, intégration Qbox, structure SQL et coque NUI.

## Dépendances

| Ressource | Obligatoire | Rôle |
|-----------|-------------|------|
| [qbx_core](https://github.com/Qbox-project/qbx_core) | Oui | Framework Qbox |
| [ox_lib](https://github.com/overextended/ox_lib) | Oui | UI, callbacks, progress |
| [ox_target](https://github.com/overextended/ox_target) | Oui | Interactions |
| [oxmysql](https://github.com/overextended/oxmysql) | Oui | Base de données |
| ox_inventory | Optionnel | Pièces & coffres (étape 9) |
| ox_fuel | Optionnel | Niveau carburant diagnostic |
| qbx_management | Optionnel | Menu patron natif Qbox |

## Installation

### 1. Copier la ressource

Placez le dossier `qbx-mechanic` dans votre répertoire `resources/`.

### 2. Importer le SQL

```bash
mysql -u USER -p DATABASE < qbx-mechanic/sql/mechanic.sql
```

### 3. Configurer le job Qbox

Ajoutez le job `mechanic` dans `qbx_core/shared/jobs.lua` (voir `install/qbox_job.lua` pour un exemple).

### 4. server.cfg — ordre de démarrage

```cfg
ensure oxmysql
ensure ox_lib
ensure qbx_core
ensure ox_target
ensure ox_inventory   # si utilisé
ensure ox_fuel          # si utilisé
ensure qbx-mechanic
```

### 5. Configuration

Éditez `config.lua` :

- `Config.Mechanics` — sociétés, positions, blips, lifts, véhicules
- `Config.Prices` / `Config.Billing` — tarifs
- `Config.RequiredItems` — pièces par réparation
- `Config.Logs.webhook` — logs Discord
- `Config.Commands` — activer/désactiver `/mechanic`, `/diagnostic`, `/repair`

## Architecture (aperçu)

```
Client                          Serveur                         NUI
──────                          ───────                         ───
ox_target ──► vehicle.lua ──►   callbacks.lua ◄── lib.callback
repair.lua                      database.lua ──► oxmysql
zones.lua                       main.lua (sécurité job/grade)
customization.lua               logs / facturation / stock
```

## Exports

### Client

```lua
exports['qbx-mechanic']:IsMechanic(minGrade) -- bool (UX)
exports['qbx-mechanic']:IsReady()            -- bool
```

### Serveur

```lua
exports['qbx-mechanic']:IsMechanic(source, minGrade) -- bool (fiable)
exports['qbx-mechanic']:GetMechanicJobName()         -- string
```

## Callbacks (étape 1)

| Callback | Description |
|----------|-------------|
| `qbx-mechanic:server:isMechanic` | Vérifie job + duty |
| `qbx-mechanic:server:getPlayerMechanicContext` | Contexte joueur |
| `qbx-mechanic:server:getConfig` | Config client autorisée |

## Roadmap

- [x] Étape 1 — Base + config + Qbox
- [ ] Étape 2 — Job & permissions
- [ ] Étape 3 — ox_target + véhicule
- [ ] Étape 4 — Diagnostic
- [ ] Étape 5 — Réparations
- [ ] Étape 6 — NUI complète
- [ ] Étape 7 — Tuning
- [ ] Étape 8 — Lifts
- [ ] Étape 9 — Stock + ox_inventory
- [ ] Étape 10 — Facturation
- [ ] Étape 11 — Garage + vestiaire + boss
- [ ] Étape 12 — SQL + logs
- [ ] Étape 13 — Optimisation
- [ ] Étape 14 — Tests

## Licence

Projet open-source — ne pas copier de code propriétaire (JG Scripts, etc.).
