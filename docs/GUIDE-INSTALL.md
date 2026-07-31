# Guide d’installation

## Prérequis

- Windows Server / Linux VPS (4+ vCPU, 8+ Go RAM recommandés)
- [Artifacts FXServer](https://runtime.fivem.net/artifacts/fivem/)
- MariaDB 10.6+ ou MySQL 8
- Clé licence CFX ([portal.cfx.re](https://portal.cfx.re/))
- Git, curl

## 1. Artifacts

Télécharge les artifacts, place-les dans un dossier `artifacts/` à côté de ce repo (déjà ignoré par git), puis lance le binaire en pointant vers ce dossier comme *server data*.

Exemple Linux :

```bash
./artifacts/run.sh +exec server.cfg
```

## 2. Ressources open-source

```bash
chmod +x scripts/install-opensource.sh
./scripts/install-opensource.sh
```

Vérifie que `resources/[ox]`, `resources/[qbx]`, `resources/[voice]` contiennent bien les clones.

## 3. Base de données

```bash
mysql -u root -p < sql/init.sql
```

Puis importe les SQL officiels fournis par `qbx_core`, `ox_inventory`, `ox_doorlock` si demandé dans leurs README.

Mets à jour dans `server.cfg` :

```
set mysql_connection_string "mysql://USER:PASS@127.0.0.1/fivem_qbox?charset=utf8mb4"
sv_licenseKey "ta_cle"
```

## 4. Items ox_inventory pour les vibe_*

Fusionne le contenu de `config/items_vibe.lua` dans `ox_inventory/data/items.lua`
(weed, black_money, lockpick, goldchain, farm, fish, permis, etc.).

Catalogue des scripts : `docs/VIBE-REWRITE.md`.

## 5. Contenu payant / maps / véhicules

Place chaque ressource achetée dans le bon dossier :

- téléphone → `resources/[phone]/`
- housing déjà prévu → `resources/[housing]/`
- MLOs → `resources/[maps]/`
- voitures → `resources/[vehicles]/`
- props stream → `resources/[stream]/`

Puis `ensure` via les groupes déjà présents dans `server.cfg` (`ensure [maps]`, etc.).

## 6. Ordre de test recommandé

1. Serveur démarre sans erreur oxmysql / qbx_core
2. Création de personnage Qbox
3. Inventaire + target
4. Voice
5. `vibe_spawnselector` + `vibe_garages`
6. Un job légal (taxi Qbox)
7. Stub weed
8. Ensuite seulement : phone, housing, dizaines de MLO

## 7. txAdmin

Tu peux aussi importer ce dossier comme *server data* dans txAdmin (Recipe manuelle) plutôt que le `run.sh` brut.
