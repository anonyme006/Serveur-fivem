# Serveur-fivem — Bot Discord ↔ FiveM

Bridge pour **gérer le serveur IG depuis Discord** et **remonter l’activité IG sur Discord**.

## Démarrage rapide

Voir le guide complet : [`docs/DISCORD-BOT.md`](docs/DISCORD-BOT.md)

```bash
# Bot
cd discord-bot && cp .env.example .env && cp config.example.json config.json
npm install && npm run register && npm start

# FiveM (server.cfg)
# set vibe_discord_secret "..."
# set vibe_discord_bot_url "http://127.0.0.1:3847"
# ensure vibe_discord
```

## Structure

- `discord-bot/` — bot Node.js (slash commands + logs + statut)
- `resources/[vibe]/vibe_discord/` — ressource FiveM (API HTTP + events)

Compatible **Qbox / QBCore / ESX** (détection auto).
