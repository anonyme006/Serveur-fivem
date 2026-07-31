# Lien complet du serveur

## Dépôt GitHub (branche complète)

**Code source (navigateur)**  
https://github.com/anonyme006/Serveur-fivem/tree/cursor/fivem-qbox-server-scaffold-cfc5

**Pull Request**  
https://github.com/anonyme006/Serveur-fivem/pull/11

**Téléchargement ZIP**  
https://github.com/anonyme006/Serveur-fivem/archive/refs/heads/cursor/fivem-qbox-server-scaffold-cfc5.zip

**Clone Git**
```bash
git clone -b cursor/fivem-qbox-server-scaffold-cfc5 https://github.com/anonyme006/Serveur-fivem.git
cd Serveur-fivem
chmod +x scripts/setup-complet.sh
./scripts/setup-complet.sh
```

## Contenu inclus

- Structure FXServer + `server.cfg`
- Install automatique Ox / Qbox / pma-voice / bob74_ipl
- **40+ ressources `vibe_*` réécrites** (FDO, EMS, mécano, crimi, civil, admin…)
- SQL, items Ox, documentation FR

## Après le clone

1. Installer les [artifacts FXServer](https://runtime.fivem.net/artifacts/fivem/)
2. Lancer `./scripts/setup-complet.sh`
3. Importer `sql/init.sql`
4. Fusionner `config/items_vibe.lua` dans `ox_inventory/data/items.lua`
5. Remplir `sv_licenseKey` + MySQL dans `server.cfg`
6. Démarrer le serveur

Catalogue scripts : [`docs/VIBE-REWRITE.md`](docs/VIBE-REWRITE.md)
