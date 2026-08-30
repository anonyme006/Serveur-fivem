Config = {}

-- Doit être identique à BRIDGE_SECRET du bot Discord
Config.BridgeSecret = GetConvar('vibe_discord_secret', 'change_moi_en_cle_longue_aleatoire')

-- URL du bot (récepteur de logs). Ex: http://127.0.0.1:3847
Config.BotLogUrl = GetConvar('vibe_discord_bot_url', 'http://127.0.0.1:3847')

-- Chemin HTTP = nom de la ressource : http://IP:30120/vibe_discord/...
Config.HttpPath = 'vibe_discord'

-- Whitelist locale (fichier JSON côté serveur)
Config.WhitelistEnabled = GetConvarInt('vibe_discord_whitelist', 0) == 1
Config.WhitelistFile = 'whitelist.json'

-- Logs à pousser vers Discord
Config.Logs = {
    connect = true,
    disconnect = true,
    chat = true,
    death = true,
    staff = true,
}

-- Framework: 'qbx' | 'esx' | 'auto'
Config.Framework = 'auto'

-- Annonces IG
Config.AnnounceTitle = 'Annonce Staff'
