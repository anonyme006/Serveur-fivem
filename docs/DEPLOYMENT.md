# Déploiement — Portail joueur Serenity V (Qbox)

## Prérequis

- Node.js 20+
- MariaDB / MySQL (base `serenityv` déjà utilisée par oxmysql)
- Discord Application (OAuth2)
- FXServer avec `qbx_core`, `oxmysql`, `ox_lib`

## 1. Base de données

Sur la DB **existante** `serenityv` :

```bash
mysql -u USER -p serenityv < sql/00_portal_tables.sql
```

Ne pas appliquer `01_seed_dev.sql` en production.

Vérifier ensuite la présence de :

- `players`, `player_vehicles` (Qbox)
- éventuellement `player_transactions` / `bank_accounts_new` (Renewed-Banking)

Le portail découvre le schéma au runtime (`GET /api/health`).

## 2. Site Next.js

```bash
cd web
cp .env.example .env.local
# renseigner MYSQL_*, DISCORD_*, SESSION_SECRET, PORTAL_API_SECRET
npm install
npm run build
npm run start
```

Derrière un reverse proxy HTTPS (Caddy/Nginx). MySQL reste en réseau privé.

## 3. Discord OAuth2

Redirect URI : `https://TON_DOMAINE/api/auth/callback`  
Scopes : `identify`

## 4. Ressource FiveM

Copier `resources/qbx_player_portal` dans les resources du serveur.

`server.cfg` :

```cfg
set portal_api_url "https://TON_DOMAINE"
set portal_api_secret "MEME_SECRET_QUE_PORTAL_API_SECRET"
ensure qbx_player_portal
```

En jeu : `/portal link` génère un code OTP à saisir sur le site.

## 5. Sécurité checklist

- [ ] HTTPS obligatoire
- [ ] Secrets uniquement en variables d'environnement / convars serveur
- [ ] `DEV_AUTH_BYPASS=false` en prod
- [ ] MySQL non exposé
- [ ] Permissions admin vérifiées côté API
- [ ] Aucune route web ne modifie `players.money` / véhicules
