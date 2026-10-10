# Serenity V — Portail joueur Qbox

Portail web Next.js + ressource FiveM `qbx_player_portal` pour un serveur **100 % Qbox**.

## Contenu

| Chemin | Rôle |
|--------|------|
| `web/` | Site Next.js (TypeScript, Tailwind, auth Discord, API sécurisée) |
| `resources/qbx_player_portal/` | Sync Lua serveur → API HTTPS |
| `sql/00_portal_tables.sql` | Tables `portal_*` uniquement |
| `sql/01_seed_dev.sql` | Seed local (ne pas utiliser en prod) |
| `docs/AUDIT.md` | Audit schéma / ressources |
| `docs/DEPLOYMENT.md` | Déploiement |

## Démarrage local

```bash
# 1) DB (docker ou MariaDB local)
docker compose up -d   # ou importer sql/* dans serenityv

# 2) Site
cd web
cp .env.example .env.local
# DEV_AUTH_BYPASS=true pour tester sans Discord
npm install
npm run dev
```

Ouvre `http://localhost:3000`, connecte-toi (bypass Discord en dev), sélectionne un personnage seed.

## Principes

- Pas d’ESX, pas de remplacement des tables Qbox
- Argent / véhicules : lecture seule depuis le web
- Liaison Discord via code OTP in-game (`/portal link`)
- Adaptateur Qbox avec découverte de schéma runtime
