# Lien complet du serveur RE ROLL (Qbox)

## Dépôt GitHub

**Code source**  
https://github.com/anonyme006/Serveur-fivem/tree/cursor/qbox-reroll-server-f159

**Téléchargement ZIP**  
https://github.com/anonyme006/Serveur-fivem/archive/refs/heads/cursor/qbox-reroll-server-f159.zip

**Clone Git**
```bash
git clone -b cursor/qbox-reroll-server-f159 https://github.com/anonyme006/Serveur-fivem.git
cd Serveur-fivem
chmod +x scripts/setup-complet.sh
./scripts/setup-complet.sh
```

## Contenu

- Structure FXServer + `server.cfg` (Qbox + Ox)
- Install automatique Ox / Qbox / pma-voice / bob74_ipl
- **45 ressources `rr_*`** (FDO, EMS, mécano, crimi, civil, deathscreen…)
- Thème RE ROLL (loadscreen, spawn, mort)
- SQL, items Ox, documentation FR

## Après le clone

1. Installer les [artifacts FXServer](https://runtime.fivem.net/artifacts/fivem/)
2. Lancer `./scripts/setup-complet.sh`
3. Importer `sql/init.sql`
4. Fusionner `config/items_reroll.lua` dans `ox_inventory/data/items.lua`
5. Remplir `sv_licenseKey` + MySQL dans `server.cfg`
6. Démarrer le serveur

Catalogue : [`docs/REROLL-REWRITE.md`](docs/REROLL-REWRITE.md)
