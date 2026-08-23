# Serveur FiveM — Base Qbox FR

Base **Qbox** française, modulaire et sécurisée, conçue pour un serveur GTA RP.

Le dépôt était vide : la couche officielle Qbox/Ox s’installe via script ou txAdmin ; ce repo apporte la **couche custom `rp_*`** (jobs, entreprises, factures, licences, admin, HUD, garages, pont téléphone).

## Architecture

```text
resources/
├── [qbx]/          # Qbox officiel (install script / txAdmin)
├── [ox]/           # oxmysql, ox_lib, ox_inventory, ox_target…
├── [standalone]/   # Renewed-Banking, illenium-appearance…
├── [voice]/        # pma-voice
├── [jobs]/         # rp_jobs + Burgershot / UwU / Gouvernement / DOJ
├── [business]/
├── [vehicles]/
├── [housing]/      # s’appuie sur qbx_properties
├── [phone]/        # NPWD / LB / sd-phone + rp_phone_bridge
├── [admin]/
└── [custom]/       # rp_core, logs, billing, licences, menu, hud, admin, garages…
```

## Dépendances

| Composant | Source |
|-----------|--------|
| qbx_core + modules | [Qbox-project](https://github.com/Qbox-project) |
| ox_lib / ox_inventory / ox_target / oxmysql | [Overextended](https://github.com/overextended) |
| Renewed-Banking | Renewed-Scripts |
| MariaDB | **≥ 10.9.0** |

## Installation

1. Cloner ce dépôt sur votre machine hébergeur FiveM.
2. Installer les dépendances :

```bash
chmod +x scripts/install-dependencies.sh
./scripts/install-dependencies.sh
```

   *Alternative :* txAdmin → Popular Recipes → **QBox Framework**, puis copier le dossier `resources/[custom]` et `resources/[jobs]` de ce repo.

3. Configurer `server.cfg` (`mysql_connection_string`, `sv_licenseKey`, Discord…).
4. Importer SQL :

```text
sql/00_qbox_recipe.sql   # (ou SQL de la recette txAdmin)
sql/01_rp_custom.sql
```

5. ACE admin dans `permissions.cfg` :

```cfg
add_principal identifier.license:VOTRE_LICENSE group.admin
```

6. Démarrer FXServer avec ce `server.cfg`.

## Ordre de démarrage

```cfg
ensure oxmysql
ensure ox_lib
ensure qbx_core
ensure ox_target
ensure ox_inventory
ensure [ox]
ensure [qbx]
ensure [standalone]
ensure [voice]
ensure rp_core
ensure rp_logs
ensure rp_licenses
ensure rp_billing
ensure rp_business
ensure rp_phone_bridge
ensure rp_menu
ensure rp_admin
ensure [jobs]
ensure [custom]
```

## Ce que Qbox fournit déjà (non dupliqué)

- Création / chargement / sauvegarde personnage
- Argent cash & banque, jobs, gangs, metadata
- Police, EMS, mécano, taxi (`qbx_*`)
- Inventaire (`ox_inventory`)
- Garages / clés / propriétés / HUD / admin menu officiels

## Couche custom `rp_*`

| Ressource | Rôle |
|-----------|------|
| `rp_core` | Config centrale, notify, bridge argent/items, sécurité |
| `rp_logs` | Logs SQL + Discord |
| `rp_licenses` | Permis (auto, moto, camion, bateau, avion, armes) |
| `rp_billing` | Factures joueur/entreprise + API |
| `rp_business` | Comptes, coffres, annonces, historique, API |
| `rp_jobs` | Enregistre CreateJobs (Burgershot, UwU, Gov, DOJ) + duty |
| `rp_menu` | Menu joueur F5 (ox_lib) |
| `rp_admin` | Admin ACE (`/radmin`) |
| `rp_hud` | HUD NUI optionnel (stopper `qbx_hud`) |
| `rp_garages` | Garages NUI optionnels (stopper `qbx_garages`) |
| `rp_phone_bridge` | NPWD / LB Phone / sd-phone |

## Exports utiles

```lua
exports.rp_core:Notify(source, message, 'success')
exports.rp_billing:CreateInvoice(src, target, amount, reason, society)
exports.rp_licenses:GrantLicense(target, 'driver', issuer)
exports.rp_business:AddBusinessMoney('burgershot', 500)
exports.rp_logs:Log('admin', source, 'Action', { meta = true })
```

## Commandes

| Commande | Description |
|----------|-------------|
| `F5` / `/menu` | Menu joueur |
| `/duty` | Prise / fin de service |
| `/factures` | Factures en attente |
| `/radmin` | Menu admin (ACE `admin`) |
| `/hud` | Toggle HUD custom |
| `/coffreentreprise` | Coffre job (ox_inventory) |

## Documentation

- [Analyse PHASE 1](docs/PHASE1_ANALYSE.md)
- [Checklist tests](docs/TESTS.md)
- [API](docs/API.md)

## Sécurité

- Validation serveur des montants, jobs, distances, permissions ACE
- Requêtes préparées oxmysql uniquement
- Rate-limit sur les events sensibles
- Pas de confiance aux données client

## Licence

Ressources `rp_*` : usage serveur.  
Qbox / Ox / scripts tiers : licences de leurs auteurs respectifs.
