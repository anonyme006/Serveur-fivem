--[[--------------------------------------------------------------------------
    Locales — Français par défaut, Anglais prêt
---------------------------------------------------------------------------]]

Locales = Locales or {}

Locales.fr = {
    resource_title = 'Police',
    notify_title = 'Police',

    -- Erreurs génériques
    err_not_leo = 'Vous n\'êtes pas membre des forces de l\'ordre.',
    err_not_onduty = 'Vous devez être en service.',
    err_no_permission = 'Permission insuffisante.',
    err_too_far = 'Trop loin de la cible.',
    err_invalid_target = 'Cible invalide.',
    err_cooldown = 'Action trop rapide, réessayez.',
    err_player_only = 'Joueur uniquement.',
    err_not_loaded = 'Données joueur indisponibles.',

    -- Duty (PHASE 2)
    duty_on = 'Statut : EN SERVICE',
    duty_off = 'Statut : HORS SERVICE',
    duty_status = '%s\nStatut : %s\nGrade : %s',

    -- 911 (PHASE 6)
    emergency_usage = 'Utilisation : /911 [message]',
    emergency_sent = 'Appel d\'urgence envoyé.',
    emergency_title = 'APPEL 911',
    emergency_taken = 'Vous avez pris l\'appel.',
    emergency_ignored = 'Appel ignoré.',
    emergency_cleared = 'Appel terminé.',

    -- Chat PD
    pd_chat_format = '[PD] %s : %s',
    pd_chat_empty = 'Message vide.',

    -- Code 1080
    code1080_pending = 'CODE 1080 — Autorisation PIT/RAM\nTemps restant : %s secondes',
    code1080_approved = 'CODE 1080 APPROUVÉ — PIT / RAM autorisé',
    code1080_cancelled = 'CODE 1080 annulé.',

    -- Interactions
    cuff = 'Menotter',
    uncuff = 'Démenotter',
    escort = 'Escorter',
    put_in_vehicle = 'Mettre dans véhicule',
    take_out_vehicle = 'Sortir du véhicule',
    search = 'Fouiller',
    headbag = 'Sac sur la tête',
    remove_headbag = 'Retirer le sac',

    -- GSR
    gsr_request = 'Le joueur accepte-t-il le test GSR ?',
    gsr_accept = 'Accepter',
    gsr_refuse = 'Refuser',
    gsr_positive = 'TEST GSR — Résultat : POSITIF',
    gsr_negative = 'TEST GSR — Résultat : NÉGATIF',
    gsr_refused = 'Test GSR refusé.',
    gsr_cleaned = 'Résidus GSR nettoyés.',

    -- Fourrière
    impound_title = 'FOURRIÈRE',
    impound_confirm = 'Confirmer',
    impound_cancel = 'Annuler',
    impound_done = 'Véhicule mis en fourrière.',

    -- Sanctions
    sanctions_title = 'SANCTIONS',
    fine = 'Amende',
    prison = 'Prison',
    community = 'Travaux d\'intérêt général',
    cancel = 'Annuler',
    fine_issued = 'Amende de $%s émise.',
    prison_issued = 'Incarcération : %s minutes.',
    community_issued = 'Travaux d\'intérêt général : %s tâches.',

    -- Prison
    prison_shop = 'Boutique prison',
    prison_released = 'Vous êtes libre.',
    community_remaining = 'Travaux restants : %s',
    community_warning = 'Retournez dans la zone de travaux !',

    -- Objets / garage / armurerie
    objects_menu = 'OBJETS POLICE',
    garage_menu = 'GARAGE',
    armory_menu = 'ARMURERIE',
    locker_menu = 'VESTIAIRE',
    police_menu = 'POLICE MENU',
    bell_pressed = 'Une personne demande assistance à l\'accueil.',
    bell_sent = 'Les forces de l\'ordre ont été notifiées.',

    -- Plaque
    plate_scan = 'Scanner plaque',
    plate_result = 'PLAQUE : %s\nPropriétaire : %s\nVéhicule : %s\nStatut : %s\nWanted : %s',

    -- Permis à points (qbx_licenses / PATCH_qbx_idcard)
    licenses_menu_title = 'Permis à points',
    licenses_target = 'Gérer les permis',
    licenses_command_help = 'Gérer les permis à points du joueur proche',
    licenses_unavailable = 'Système de permis (qbx_licenses) indisponible.',
    licenses_no_nearby = 'Aucun joueur à proximité.',
    licenses_points_removed = 'Retrait de %s point(s) sur le permis %s.',
    licenses_error = 'Erreur lors de la gestion du permis.',
    licenses_remove_title = 'Retirer des points',
    licenses_remove_amount = 'Nombre de points',
    licenses_remove_reason = 'Motif (optionnel)',
    licenses_status_valid = 'Valide',
    licenses_status_suspended = 'Suspendu',
    licenses_status_missing = 'Non détenu',

    -- Debug
    debug_loaded = 'qbx_policejob chargé (PHASE 1).',
}

Locales.en = {
    resource_title = 'Police',
    notify_title = 'Police',

    err_not_leo = 'You are not a law enforcement member.',
    err_not_onduty = 'You must be on duty.',
    err_no_permission = 'Insufficient permission.',
    err_too_far = 'Too far from the target.',
    err_invalid_target = 'Invalid target.',
    err_cooldown = 'Action on cooldown, try again.',
    err_player_only = 'Players only.',
    err_not_loaded = 'Player data unavailable.',

    duty_on = 'Status: ON DUTY',
    duty_off = 'Status: OFF DUTY',
    duty_status = '%s\nStatus: %s\nRank: %s',

    emergency_usage = 'Usage: /911 [message]',
    emergency_sent = 'Emergency call sent.',
    emergency_title = '911 CALL',
    emergency_taken = 'You took the call.',
    emergency_ignored = 'Call ignored.',
    emergency_cleared = 'Call cleared.',

    pd_chat_format = '[PD] %s: %s',
    pd_chat_empty = 'Empty message.',

    code1080_pending = 'CODE 1080 — PIT/RAM authorization\nTime remaining: %s seconds',
    code1080_approved = 'CODE 1080 APPROVED — PIT / RAM authorized',
    code1080_cancelled = 'CODE 1080 cancelled.',

    cuff = 'Cuff',
    uncuff = 'Uncuff',
    escort = 'Escort',
    put_in_vehicle = 'Put in vehicle',
    take_out_vehicle = 'Take out of vehicle',
    search = 'Search',
    headbag = 'Headbag',
    remove_headbag = 'Remove headbag',

    gsr_request = 'Does the player accept the GSR test?',
    gsr_accept = 'Accept',
    gsr_refuse = 'Refuse',
    gsr_positive = 'GSR TEST — Result: POSITIVE',
    gsr_negative = 'GSR TEST — Result: NEGATIVE',
    gsr_refused = 'GSR test refused.',
    gsr_cleaned = 'GSR residue cleaned.',

    impound_title = 'IMPOUND',
    impound_confirm = 'Confirm',
    impound_cancel = 'Cancel',
    impound_done = 'Vehicle impounded.',

    sanctions_title = 'SANCTIONS',
    fine = 'Fine',
    prison = 'Jail',
    community = 'Community service',
    cancel = 'Cancel',
    fine_issued = 'Fine of $%s issued.',
    prison_issued = 'Jailed for %s minutes.',
    community_issued = 'Community service: %s tasks.',

    prison_shop = 'Prison shop',
    prison_released = 'You have been released.',
    community_remaining = 'Tasks remaining: %s',
    community_warning = 'Return to the community service area!',

    objects_menu = 'POLICE OBJECTS',
    garage_menu = 'GARAGE',
    armory_menu = 'ARMORY',
    locker_menu = 'LOCKER',
    police_menu = 'POLICE MENU',
    bell_pressed = 'Someone is requesting assistance at the front desk.',
    bell_sent = 'Law enforcement has been notified.',

    plate_scan = 'Scan plate',
    plate_result = 'PLATE: %s\nOwner: %s\nVehicle: %s\nStatus: %s\nWanted: %s',

    licenses_menu_title = 'License points',
    licenses_target = 'Manage licenses',
    licenses_command_help = 'Manage nearby player license points',
    licenses_unavailable = 'License system (qbx_licenses) unavailable.',
    licenses_no_nearby = 'No player nearby.',
    licenses_points_removed = 'Removed %s point(s) from %s license.',
    licenses_error = 'License management error.',
    licenses_remove_title = 'Remove points',
    licenses_remove_amount = 'Points to remove',
    licenses_remove_reason = 'Reason (optional)',
    licenses_status_valid = 'Valid',
    licenses_status_suspended = 'Suspended',
    licenses_status_missing = 'Not owned',

    debug_loaded = 'qbx_policejob loaded (PHASE 1).',
}
