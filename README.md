# Serveur FiveM — RE ROLL (Qbox + Ox)

Pack serveur RP FR inspiré de l’ambiance **RE ROLL** : framework **Qbox**, suite **Ox**, et **45 scripts `rr_*` originaux** (FDO, EMS, crimi, civil, mort cinématique…).

> Ce n’est **pas** le serveur officiel RE ROLL ni un dump. C’est une base légale open-source + scripts custom réécrits, thème dark/rouge.

## Lien complet

| | URL |
|---|-----|
| **Branche** | https://github.com/anonyme006/Serveur-fivem/tree/cursor/qbox-reroll-server-f159 |
| **ZIP** | https://github.com/anonyme006/Serveur-fivem/archive/refs/heads/cursor/qbox-reroll-server-f159.zip |

Fichier dédié : [`LIEN-COMPLET.md`](LIEN-COMPLET.md)

## Installation rapide

```bash
git clone -b cursor/qbox-reroll-server-f159 https://github.com/anonyme006/Serveur-fivem.git
cd Serveur-fivem
chmod +x scripts/setup-complet.sh
./scripts/setup-complet.sh
mysql -u root -p < sql/init.sql
# Fusionner config/items_reroll.lua dans ox_inventory/data/items.lua
# Éditer server.cfg (sv_licenseKey + MySQL)
# Lancer FXServer sur ce dossier
```

Guide : [`docs/GUIDE-INSTALL.md`](docs/GUIDE-INSTALL.md)  
Catalogue scripts : [`docs/REROLL-REWRITE.md`](docs/REROLL-REWRITE.md)

## Pack inclus

- `resources/[core]` — chat, spawnmanager, sessionmanager…
- `resources/[ox]` — oxmysql / ox_lib / ox_inventory / ox_target / ox_doorlock / ox_fuel
- `resources/[qbx]` — qbx_core + police / EMS / garages / HUD…
- `resources/[voice]/pma-voice`, `[maps]/bob74_ipl`, housing, banking, admin
- `resources/[reroll]` — 45 scripts custom (`rr_*`)
- Loadscreen + spawn + deathscreen thème **RE ROLL**
- `start-server.sh` / `start-server.bat`

## Important

Les MLOs, véhicules custom, `lb-phone`, `jg-*`, `rcore_*` premium sont **payants** : à acheter séparément.  
Les `rr_*` sont des **réécritures**, pas des dumps d’un serveur existant.

## Licence

Usage personnel / éducatif. Les ressources tierces restent sous leurs licences.
