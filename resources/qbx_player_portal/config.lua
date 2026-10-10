Config = {}

--- URL HTTPS du portail (jamais exposer MySQL)
Config.ApiBaseUrl = GetConvar('portal_api_url', 'https://portal.example.com')

--- Secret partagé serveur↔API (convar serveur uniquement)
Config.ApiSecret = GetConvar('portal_api_secret', '')

--- Timeout HTTP ms
Config.HttpTimeout = 8000

--- Durée de validité d'un code de liaison (secondes)
Config.LinkCodeTtl = 180

--- Longueur du code affiché au joueur
Config.LinkCodeLength = 6

--- Intervalle de heartbeat playtime (secondes)
Config.PlaytimeHeartbeat = 60

--- Activer les logs détaillés
Config.Debug = GetConvar('portal_debug', 'false') == 'true'

--- Commande in-game
Config.LinkCommand = 'portal'

--- Messages FR
Config.Locale = {
    noPlayer = 'Personnage introuvable.',
    codeCreated = 'Code portail : %s (expire dans %ss). Ne le partage avec personne.',
    alreadyLinkedHint = 'Ouvre le portail web et entre ce code pour confirmer la liaison.',
    configMissing = 'Portail mal configuré (secret API manquant). Contacte le staff.',
    syncOk = 'Synchronisation portail OK.',
    syncFail = 'Échec synchronisation portail.',
}
