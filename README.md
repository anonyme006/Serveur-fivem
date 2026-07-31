# Serveur FiveM — scaffold type « Vibe / Qbox RP »

Base de reconstruction d’un serveur RP **français** calqué sur une stack **Qbox + Ox**, avec inventaire des ressources du serveur de référence et stubs pour remplacer les scripts privés `vibe_*`.

> Les scripts d’origine `vibe_*` sont privés : ce dépôt fournit une **réécriture jouable** (FDO, crimi, civil, économie) + la structure serveur. Les MLOs / véhicules / `lb-phone` restent à acheter.

## Ce que contient ce dépôt

| Chemin | Contenu |
|--------|---------|
| `server.cfg` | Config FXServer prête à personnaliser |
| `docs/ANALYSE-SERVEUR.md` | Analyse de la stack du serveur de référence |
| `docs/INVENTAIRE-RESSOURCES.md` | Liste des ressources visibles |
| `docs/EQUIVALENTS.md` | Remplacements OSS / payants des `vibe_*` |
| `docs/GUIDE-INSTALL.md` | Installation pas à pas |
| `scripts/install-opensource.sh` | Clone Ox + Qbox + voice + bob74_ipl |
| `sql/init.sql` | Base MariaDB + tables custom stubs |
| `resources/[vibe]/` | Suite complète réécrite (FDO, crimi, civil, économie…) |
| `docs/VIBE-REWRITE.md` | Catalogue des modules vibe_* réécrits |
| `config/items_vibe.lua` | Items à fusionner dans ox_inventory |

## Démarrage rapide

```bash
# 1. Cloner ce dépôt sur ta machine de jeu / VPS
# 2. Installer les ressources open-source
chmod +x scripts/install-opensource.sh
./scripts/install-opensource.sh

# 3. Créer la DB
mysql -u root -p < sql/init.sql

# 4. Éditer server.cfg (licence CFX + MySQL)
# 5. Lancer FXServer avec ce dossier comme server-data
```

Détails : [`docs/GUIDE-INSTALL.md`](docs/GUIDE-INSTALL.md).

## Stack cible

```
FXServer → oxmysql → ox_lib / ox_target / ox_inventory / ox_doorlock
         → pma-voice → qbx_core + modules qbx_*
         → scripts standalone / phone / housing / jobs
         → stubs vibe_* → maps → véhicules
```

## Important

- Achète les assets payants (`lb-phone`, `jg-*`, `rcore_*`, MLOs, voitures).
- Ne dump / ne pirate pas un serveur existant.
- Réécris les `vibe_*` à partir des stubs, ou remplace-les (voir `docs/EQUIVALENTS.md`).

## Licence

Scaffold fourni tel quel pour usage personnel / éducatif. Les ressources tierces restent sous leurs licences respectives.
