Config = {}

--- Position du stack : 'left' | 'right'
Config.Position = 'left'

--- Vertical : 'top' | 'center' | 'bottom'
Config.Vertical = 'center'

--- Durée par défaut (ms)
Config.DefaultDuration = 5000

--- Afficher la barre de durée en bas
Config.ShowDuration = true

--- Afficher une icône Font Awesome (la photo n'en a pas)
Config.ShowIcons = false

--- Max de toasts visibles en même temps
Config.MaxVisible = 5

--- Son à l'apparition (nil pour silencieux)
Config.Sound = nil -- { name = 'SELECT', set = 'HUD_FRONTEND_DEFAULT_SOUNDSET' }

--- Couleurs d'accent (barre gauche + progress)
--- Calibrées sur la capture : rouge (erreur) + jaune/or (succès)
Config.Types = {
    error = {
        color = '#E74C3C',
        icon = 'fa-circle-xmark',
    },
    warning = {
        color = '#E74C3C',
        icon = 'fa-circle-exclamation',
    },
    success = {
        color = '#F1C40F',
        icon = 'fa-circle-check',
    },
    inform = {
        color = '#3498DB',
        icon = 'fa-circle-info',
    },
    info = {
        color = '#3498DB',
        icon = 'fa-circle-info',
    },
    neutral = {
        color = '#95A5A6',
        icon = 'fa-circle',
    },
}

--- Alias ox_lib → type interne
Config.TypeAliases = {
    inform = 'inform',
    info = 'info',
    success = 'success',
    error = 'error',
    warning = 'warning',
    primary = 'inform',
}

--- Commande de test in-game (nil pour désactiver)
Config.TestCommand = 'testnotify'
