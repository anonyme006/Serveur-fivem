# Bot Discord ↔ FiveM (Vibe RP)

Bridge bidirectionnel : **gestion du serveur IG depuis Discord**, et **remontée de tout l’IG vers Discord** (connexions, chat, morts, staff, reports).

```
Discord slash commands  ──HTTP──►  ressource vibe_discord (FiveM)
FiveM events / logs     ──HTTP──►  bot (port LOG_PORT)
```

## Contenu

| Dossier | Rôle |
|---------|------|
| `discord-bot/` | Bot Node.js (discord.js 14) |
| `resources/[vibe]/vibe_discord/` | Ressource FiveM (Qbox / ESX / standalone) |

## Prérequis

- Node.js 18+
- Serveur FiveM avec `ox_lib` (recommandé)
- Application Discord bot ([developers.discord.com](https://discord.com/developers/applications))

## 1. Créer le bot Discord

1. New Application → Bot → Reset Token → copier le token  
2. OAuth2 → URL Generator : scopes `bot` + `applications.commands`  
   Permissions : Send Messages, Embed Links, Use Slash Commands, Manage Roles (optionnel)  
3. Inviter le bot sur ton serveur  
4. Activer les intents nécessaires (Guild Members si besoin)  
5. Mode développeur Discord → copier IDs : serveur, rôles staff, salons de logs  

## 2. Configurer le bot

```bash
cd discord-bot
cp .env.example .env
cp config.example.json config.json
npm install
```

Édite `.env` :

```env
DISCORD_TOKEN=...
DISCORD_CLIENT_ID=...
DISCORD_GUILD_ID=...
BRIDGE_SECRET=une_cle_secrete_longue
FIVEM_BRIDGE_URL=http://127.0.0.1:30120/vibe_discord
LOG_PORT=3847
```

Édite `config.json` : IDs des rôles (`admin` / `moderator` / `staff`) et des salons de logs.

```bash
npm run register   # enregistre les slash commands
npm start          # lance le bot
```

## 3. Ressource FiveM

Dans `server.cfg` :

```cfg
# Bridge Discord
set vibe_discord_secret "une_cle_secrete_longue"   # = BRIDGE_SECRET
set vibe_discord_bot_url "http://127.0.0.1:3847"   # IP du bot
# set vibe_discord_whitelist 1                     # active la whitelist

ensure vibe_discord
```

Si le bot tourne sur **une autre machine**, mets l’IP publique/LAN du bot dans `vibe_discord_bot_url`, et ouvre le port `3847` (firewall).  
Si FiveM est distant du bot, `FIVEM_BRIDGE_URL` doit pointer vers l’IP du FXServer (port 30120).

## Commandes Discord

| Commande | Niveau | Action IG |
|----------|--------|-----------|
| `/players` `/status` | Staff | Liste / statut |
| `/warn` `/revive` `/heal` | Staff | Warn / revive / heal |
| `/kick` `/ban` `/annonce` | Modo | Sanctions / annonce |
| `/unban` `/giveitem` `/setjob` `/whitelist` | Admin | Admin économie & WL |
| `/aide` | Staff | Aide |

## Logs remontés sur Discord

- Connexions / déconnexions  
- Chat IG  
- Morts / kills  
- Actions staff (kick, ban, giveitem…)  
- Reports joueurs (`/report [id] message` IG)  
- Statut live (salon `status` + présence du bot `12/48 joueurs`)

## Exports Lua (autres scripts)

```lua
exports.vibe_discord:PushDiscordLog('economy', {
    Joueur = 'Jean',
    Action = 'achat',
    Montant = '$5000',
})

exports.vibe_discord:LogReport({ Reporter = '...', Message = '...' })
exports.vibe_discord:LogEconomy({ ... })
```

## Sécurité

- Ne partage **jamais** `DISCORD_TOKEN` ni `BRIDGE_SECRET`  
- Le secret est vérifié sur **chaque** requête HTTP  
- Les commandes Discord sont filtrées par rôles (`config.json`)  
- Garde le port du récepteur de logs derrière un firewall si possible  

## Dépannage

| Symptôme | Check |
|----------|--------|
| `Serveur injoignable` | `FIVEM_BRIDGE_URL`, `ensure vibe_discord`, secret identique |
| Pas de logs Discord | `vibe_discord_bot_url`, `LOG_PORT`, IDs salons dans `config.json` |
| Commandes invisibles | `npm run register` + `DISCORD_GUILD_ID` |
| Ban/kick KO | Joueur bien en ligne (`/players`) |

Test console FXServer : `discordtest` (envoie un embed staff de test).
