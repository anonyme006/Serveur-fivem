# Serveur FiveM — Vibe RP (Qbox + Ox)

Réécriture complète d’un serveur RP FR type « Vibe » : framework **Qbox**, suite **Ox**, et **40+ scripts `vibe_*` originaux**.

## Lien complet

| | URL |
|---|-----|
| **Branche (code)** | https://github.com/anonyme006/Serveur-fivem/tree/cursor/fivem-qbox-server-scaffold-cfc5 |
| **Pull Request** | https://github.com/anonyme006/Serveur-fivem/pull/11 |
| **ZIP téléchargeable** | https://github.com/anonyme006/Serveur-fivem/archive/refs/heads/cursor/fivem-qbox-server-scaffold-cfc5.zip |

Fichier dédié : [`LIEN-COMPLET.md`](LIEN-COMPLET.md)

## Installation rapide

```bash
git clone -b cursor/fivem-qbox-server-scaffold-cfc5 https://github.com/anonyme006/Serveur-fivem.git
cd Serveur-fivem
chmod +x scripts/setup-complet.sh
./scripts/setup-complet.sh
mysql -u root -p < sql/init.sql
# Fusionner config/items_vibe.lua dans ox_inventory/data/items.lua
# Éditer server.cfg (sv_licenseKey + MySQL)
# Lancer FXServer sur ce dossier
```

Guide détaillé : [`docs/GUIDE-INSTALL.md`](docs/GUIDE-INSTALL.md)  
Catalogue scripts : [`docs/VIBE-REWRITE.md`](docs/VIBE-REWRITE.md)

## Pack inclus (plus de dossiers vides)

- `resources/[core]` chat, spawnmanager, sessionmanager, …
- `resources/[ox]` oxmysql / ox_lib / ox_inventory / ox_target / ox_doorlock / ox_fuel (**releases buildées**)
- `resources/[qbx]` qbx_core + police/EMS/garages/hud/…
- `resources/[voice]/pma-voice`, `[maps]/bob74_ipl`, housing, banking, admin
- `resources/[vibe]` 44 scripts custom
- `start-server.sh` / `start-server.bat`

Détail : [`docs/FICHIERS-MANQUANTS.md`](docs/FICHIERS-MANQUANTS.md)

## Contenu

- `server.cfg` + structure `resources/[ox|qbx|voice|vibe|maps|…]`
- Install auto Ox / Qbox / pma-voice / bob74_ipl
- Scripts vibe : FDO, EMS, mécano, concess, garages, crimi (weed/meth/braquages…), gangs, courses, panel admin…
- SQL + items Ox

## Important

Les MLOs, véhicules custom, `lb-phone`, `jg-*`, `rcore_*` du serveur d’origine sont **payants** : à acheter séparément.  
Les `vibe_*` ici sont des **réécritures**, pas des dumps.

## Licence

Usage personnel / éducatif. Les ressources tierces restent sous leurs licences.
