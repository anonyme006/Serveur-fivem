Locales = {
    job_required = 'Métier Gruppe 6 requis.',
    run_active = 'Tournée déjà en cours.',
    cooldown = 'Attends %ss avant une nouvelle tournée.',
    not_enough_points = 'Pas assez de points actifs pour une tournée.',
    wrong_stop = 'Ce n\'est pas l\'arrêt prévu.',
    inventory_full = 'Inventaire plein.',
    all_stops_done = 'Tous les arrêts effectués. Retourne au dépôt.',
    finish_stops_first = 'Termine d\'abord tous les arrêts.',
    no_bags = 'Aucun sac de billets à déposer.',
    deposit_failed = 'Impossible de déposer les sacs.',
    run_done = 'Convoi terminé — %s sac(s) déposés, $%s versés à la société.',
    run_cancelled = 'Tournée annulée.',
    run_started = 'Tournée lancée — %s arrêt(s).',
    return_depot = 'Retourne au dépôt pour déposer les fonds.',
    access_denied = 'Accès refusé (boss Gruppe 6 ou admin).',
    invalid_type = 'Type invalide. Utilise: magasin, banque, armurerie, grossiste.',
    point_added = 'Point #%s ajouté: %s (%s)',
    point_deleted = 'Point #%s supprimé.',
    point_not_found = 'Point introuvable.',
    point_toggled = 'Point #%s %s.',
    no_points = 'Aucun point configuré.',
}

function L(key, ...)
    local str = Locales[key] or key
    if select('#', ...) > 0 then
        return str:format(...)
    end
    return str
end
