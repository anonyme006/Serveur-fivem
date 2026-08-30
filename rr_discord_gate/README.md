# rr_discord_gate

Vérification Discord (lien FiveM + membership + rôle **Citoyen**) avec NUI, puis sélection des personnages.

## Configuration

Tout se règle dans **`config.lua`** uniquement :

```lua
Config.Discord = {
    Enabled = true,
    GuildId = "ID_DU_SERVEUR_DISCORD",
    CitizenRoleId = "ID_DU_ROLE_CITOYEN",
    Invite = "https://discord.gg/TONINVITE",
    CacheDuration = 300,
    RequireCitizenRole = true,
    BotToken = "", -- ou convar discord_bot_token
}
```

Le lien d’invitation n’est **jamais** hardcodé dans la NUI : il est poussé depuis `Config.Discord.Invite`.

## Bot Discord

1. Créer une application sur le [Discord Developer Portal](https://discord.com/developers/applications)
2. Bot → reset token → `set discord_bot_token "TOKEN"` dans `server.cfg` (recommandé)
3. Activer **Server Members Intent**
4. Inviter le bot sur le serveur avec permission de lire les membres

## Installation

```
ensure rr_discord_gate
```

Placez la resource **avant** votre multichar si vous voulez bloquer l’accès tant que Discord n’est pas validé.

Pour brancher un multichar externe :

```lua
Config.Flow.ExternalCharacterEvent = 'qbx_core:client:showCharacterSelection'
```

## NUI

| Écran | Condition |
|-------|-----------|
| Vérification + spinner | Pendant le check API |
| Succès ✓ | Discord OK (+ rôle Citoyen) → sélection auto |
| ACCÈS REFUSÉ | Pas le rôle Citoyen |
| DISCORD REQUIS | Compte Discord non lié à FiveM |
| SERVEUR DISCORD REQUIS | Pas membre de la guilde |

Bouton **Rejoindre le Discord** → `window.invokeNative('openUrl', Config.Discord.Invite)`.

## Debug

```
/discordgate verify
/discordgate denied_role
/discordgate denied_link
/discordgate denied_member
/discordgate success
/discordgate characters
```

Preview navigateur : `web/index.html?preview=denied_role`
