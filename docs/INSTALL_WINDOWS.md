# Installation Windows — Base Qbox FR

Guide pas à pas pour installer la base sur **Windows 10/11**.

## Prérequis

| Logiciel | Version / notes |
|----------|-----------------|
| [FiveM Server (Artifacts)](https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/) | Dernier build recommandé |
| [MariaDB](https://mariadb.org/download/) | **≥ 10.9** (pas XAMPP MySQL) |
| [Git for Windows](https://git-scm.com/download/win) | Obligatoire |
| [HeidiSQL](https://www.heidisql.com/) ou [DBeaver](https://dbeaver.io/) | Pour importer le SQL |
| [Node.js LTS](https://nodejs.org/) + [pnpm](https://pnpm.io/installation) | Pour compiler ox_lib / ox_inventory |
| Compte [Cfx.re](https://portal.cfx.re/) | Clé license serveur (`sv_licenseKey`) |

Optionnel mais recommandé : **txAdmin** (inclus avec les artifacts FiveM).

---

## Méthode A — Recommandée (txAdmin + ce repo)

### 1. Installer le serveur FiveM

1. Créez un dossier, ex. `C:\FXServer\`
2. Téléchargez le dernier artifact **Windows** et extrayez-le dans `C:\FXServer\`
3. Lancez `FXServer.exe` → configuration **txAdmin**
4. Créez un compte txAdmin local

### 2. Déployer Qbox via la recette

Dans txAdmin → **Recipe** / déploiement :

- Popular Recipes → **QBox Framework**

Cela installe `qbx_core`, `ox_*`, jobs officiels, etc.

### 3. Ajouter la couche custom `rp_*`

1. Clonez ce dépôt ailleurs, ou téléchargez le ZIP de la branche
2. Copiez dans le dossier `resources` du serveur :

```text
resources\[custom]\     ← tout le contenu
resources\[jobs]\       ← tout le contenu
```

3. Copiez aussi (si pas déjà présents) :

```text
server.cfg          (ou fusionnez les lignes ensure rp_*)
sql\01_rp_custom.sql
```

4. Dans `server.cfg` du serveur, ajoutez **après** `[qbx]` / `[standalone]` :

```cfg
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

### 4. Base de données

1. Ouvrez HeidiSQL → connectez-vous à MariaDB
2. Créez une base `qbox` (utf8mb4)
3. Importez dans l’ordre :
   - SQL de la recette Qbox / `qbx_core`
   - `sql\00_qbox_recipe.sql`
   - `sql\01_rp_custom.sql`

### 5. Configurer `server.cfg`

```cfg
set mysql_connection_string "mysql://root:VOTRE_MDP@localhost/qbox?charset=utf8mb4"
sv_licenseKey "VOTRE_CLE_CFX"
sets locale "fr-FR"
setr qb_locale "fr"
```

Dans `permissions.cfg` :

```cfg
add_principal identifier.license:VOTRE_LICENSE_FIVEM group.admin
```

(Votre license FiveM se trouve dans la console F8 en jeu : `license:xxxxx`)

### 6. Démarrer

Dans txAdmin → **Start server**.  
Vérifiez la console : `[rp_core] OK`, `[rp_billing] ready`, etc.

---

## Méthode B — Installation manuelle (sans recette txAdmin)

### 1. Préparer les dossiers

```text
C:\FXServer\
  ├── FXServer.exe          (artifacts)
  ├── server.cfg
  ├── permissions.cfg
  ├── ox.cfg
  ├── voice.cfg
  ├── misc.cfg
  ├── sql\
  └── resources\
```

### 2. Cloner ce projet

PowerShell :

```powershell
cd C:\
git clone https://github.com/anonyme006/Serveur-fivem.git Serveur-fivem
cd Serveur-fivem
git checkout cursor/qbox-base-complete-dd4d
```

### 3. Lancer l’installateur Windows

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\install-dependencies.ps1
```

Le script clone Qbox, Ox, Renewed-Banking, etc. dans `resources\`.

### 4. Compiler ox_lib / ox_inventory

```powershell
npm install -g pnpm
cd resources\[ox]\ox_lib
pnpm i
pnpm build
cd ..\ox_inventory
pnpm i
pnpm build
```

### 5. Copier les configs à la racine FXServer

Copiez depuis ce repo vers `C:\FXServer\` :

- `server.cfg`, `permissions.cfg`, `ox.cfg`, `voice.cfg`, `misc.cfg`
- dossier `resources\`
- dossier `sql\`

Ou pointez txAdmin / FXServer directement sur le dossier du repo.

### 6. SQL + license + démarrage

Même étapes que Méthode A (§4–6).

Fichier de démarrage typique `C:\FXServer\start.bat` :

```bat
@echo off
cd /d C:\FXServer
FXServer.exe +exec server.cfg
pause
```

---

## Ordre de démarrage (rappel)

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

---

## Commandes en jeu (tests)

| Touche / commande | Action |
|-------------------|--------|
| `F5` ou `/menu` | Menu joueur |
| `/duty` | Service |
| `/factures` | Factures |
| `/radmin` | Admin (si ACE admin) |

---

## Problèmes fréquents (Windows)

| Problème | Solution |
|----------|----------|
| `ox_lib` / inventory UI blanche | Relancer `pnpm build` dans le dossier concerné |
| `oxmysql` refuse la connexion | Vérifier MariaDB démarré + chaîne `mysql_connection_string` |
| `qbx_core` manquant | Relancer `install-dependencies.ps1` ou recette txAdmin |
| Port 30120 bloqué | Autoriser dans le Pare-feu Windows |
| Script `.ps1` bloqué | `Set-ExecutionPolicy -Scope Process Bypass` |
| Chemins avec `[ox]` | Toujours utiliser des guillemets : `cd "resources\[ox]\ox_lib"` |

---

## Checklist rapide

1. MariaDB ≥ 10.9 installé et service démarré  
2. Artifacts FiveM Windows extraits  
3. Qbox + Ox installés (recette **ou** `.ps1`)  
4. Dossiers `[custom]` + `[jobs]` présents  
5. SQL importé  
6. `sv_licenseKey` + MySQL configurés  
7. ACE admin ajouté  
8. Serveur démarré sans erreur rouge critique  

Documentation API : `docs/API.md` — Tests : `docs/TESTS.md`
