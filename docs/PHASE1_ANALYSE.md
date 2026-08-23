# PHASE 1 — Analyse complète

## État du dépôt

| Élément | Résultat |
|---------|----------|
| Contenu initial | `README.md` uniquement (`# Serveur-fivem`) |
| Framework détecté | **Aucun** (dépôt vide) |
| Qbox / ox_* | **Absents** |
| Tables SQL | **Aucune** |
| Conflits | **Aucun** |

## Décision d’architecture

Le dépôt étant vide, la base s’appuie sur la **recette officielle Qbox** (`Qbox-project/txAdminRecipe`) plutôt que de réécrire un framework.

### Fourni nativement par Qbox (ne pas dupliquer)

| Fonctionnalité | Ressource |
|----------------|-----------|
| Core joueur (création, load, save, money, job, gang, metadata) | `qbx_core` |
| Inventaire | `ox_inventory` |
| Target / lib / SQL | `ox_target`, `ox_lib`, `oxmysql` |
| Police / EMS / Mécano / Taxi | `qbx_police`, `qbx_ambulancejob`, `qbx_mechanicjob`, `qbx_taxijob` |
| Garages / clés / propriétés | `qbx_garages`, `qbx_vehiclekeys`, `qbx_properties` |
| Management boss | `qbx_management` |
| HUD / Admin | `qbx_hud`, `qbx_adminmenu` |
| Banque | `Renewed-Banking` |
| Téléphone (recette) | `npwd` + `qbx_npwd` |

### Couche custom française (`rp_*`)

Extensions sans remplacer Qbox :

- `rp_core` — config centrale, bridge, notify, sécurité
- `rp_logs` — webhooks Discord + journal SQL
- `rp_billing` — facturation unifiée
- `rp_licenses` — permis (auto, moto, camion, bateau, avion, armes)
- `rp_business` — API entreprises (comptes, stock, historique)
- `rp_menu` — menu joueur ox_lib
- `rp_hud` — HUD moderne optionnel (désactive `qbx_hud` si activé)
- `rp_admin` — admin sécurisé (complément / alternative)
- `rp_garages` — NUI garage FR optionnelle
- `rp_phone_bridge` — NPWD / LB Phone / sd-phone
- Jobs manquants : Burgershot, UwU Café, Gouvernement, DOJ

## Versions de référence (recette officielle)

À installer via `scripts/install-dependencies.sh` ou txAdmin « QBox Framework ».

- `qbx_core` ≥ 1.23 (export-based API)
- `ox_lib`, `ox_inventory`, `ox_target`, `oxmysql` (Overextended)
- MariaDB ≥ **10.9.0**

## Résultat PHASE 1

Analyse terminée. Passage à la PHASE 2 : scaffolding, configs, script d’installation des dépendances officielles.
