Config = {}

--[[--------------------------------------------------------------------------
    Discord — lien & contrôle d'accès (modifiable UNIQUEMENT ici)
---------------------------------------------------------------------------]]
Config.Discord = {
    Enabled = true,

    -- ID du serveur Discord (clic droit serveur > Copier l'identifiant du serveur)
    GuildId = 'ID_DU_SERVEUR_DISCORD',

    -- ID du rôle Citoyen (clic droit rôle > Copier l'identifiant du rôle)
    CitizenRoleId = 'ID_DU_ROLE_CITOYEN',

    -- Nom affiché du rôle dans les messages NUI
    CitizenRoleName = 'Citoyen',

    -- Lien d'invitation — utilisé dans la NUI (bouton Discord). Ne pas hardcoder ailleurs.
    Invite = 'https://discord.gg/TONINVITE',

    -- Cache serveur des résultats de vérification (secondes)
    CacheDuration = 300,

    -- Exiger le rôle Citoyen pour accéder à la sélection de personnages
    RequireCitizenRole = true,

    -- Token du bot Discord (Bot > Token sur le Discord Developer Portal)
    -- Préférer la convar serveur : set discord_bot_token "TOKEN"
    -- Le bot doit être sur le serveur avec l'intent Server Members Intent.
    BotToken = '',
}

--[[--------------------------------------------------------------------------
    Flux de connexion
---------------------------------------------------------------------------]]
Config.Flow = {
    -- Démarrer automatiquement la vérification à la connexion joueur
    AutoStartOnJoin = true,

    -- Délai avant ouverture NUI (ms) après le join
    AutoStartDelay = 1500,

    -- Afficher brièvement les checks ✓ avant la sélection de personnages (ms)
    SuccessDisplayMs = 1800,

    -- Événement client déclenché après validation Discord (pour un multichar externe)
    -- Si nil, la NUI affiche la sélection de personnages intégrée.
    ExternalCharacterEvent = nil, -- ex. 'qbx_core:client:showCharacterSelection'

    -- Nombre max de personnages affichés (stub / qbx)
    MaxCharacters = 4,
}

--[[--------------------------------------------------------------------------
    Debug / preview
---------------------------------------------------------------------------]]
Config.Debug = {
    -- Commande client pour rouvrir la NUI : /discordgate [state]
    -- states: verify | success | denied_role | denied_link | denied_member | characters
    Command = 'discordgate',

    -- En true, simule une vérification réussie sans appeler l'API Discord
    ForceSuccess = false,
}
