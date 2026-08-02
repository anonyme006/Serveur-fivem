Locales = Locales or {}

Locales['fr'] = {
    -- Général
    ['garage'] = 'Garage',
    ['impound'] = 'Fourrière',
    ['no_permission'] = 'Vous n\'avez pas la permission.',
    ['not_enough_money'] = 'Fonds insuffisants.',
    ['too_far'] = 'Vous êtes trop loin.',
    ['cancelled'] = 'Action annulée.',
    ['error'] = 'Une erreur est survenue.',
    ['success'] = 'Succès.',

    -- Accès
    ['garage_disabled'] = 'Ce garage est désactivé.',
    ['garage_job_required'] = 'Accès réservé à un métier spécifique.',
    ['garage_gang_required'] = 'Accès réservé à un groupe spécifique.',
    ['garage_grade_required'] = 'Votre grade est insuffisant.',
    ['no_vehicles'] = 'Aucun véhicule dans ce garage.',

    -- Sortie
    ['taking_out'] = 'Sortie du véhicule…',
    ['vehicle_out'] = 'Véhicule sorti : %s',
    ['vehicle_already_out'] = 'Ce véhicule est déjà sorti.',
    ['spawn_blocked'] = 'L\'emplacement de spawn est occupé.',
    ['vehicle_not_found'] = 'Véhicule introuvable.',
    ['vehicle_not_yours'] = 'Ce véhicule ne vous appartient pas.',
    ['anti_dupe'] = 'Action bloquée (anti-duplication).',
    ['gate_opening'] = 'Ouverture du portail…',

    -- Rangement
    ['storing'] = 'Rangement du véhicule…',
    ['vehicle_stored'] = 'Véhicule rangé.',
    ['store_target'] = 'Ranger le véhicule',
    ['engine_must_be_off'] = 'Coupez le moteur avant de ranger.',
    ['not_close_enough'] = 'Approchez-vous du véhicule.',
    ['cannot_store_here'] = 'Impossible de ranger ce type de véhicule ici.',
    ['company_store_denied'] = 'Grade insuffisant pour ranger.',

    -- Fourrière
    ['impound_retrieve'] = 'Récupération fourrière…',
    ['impound_paid'] = 'Fourrière payée : $%s',
    ['impound_wait'] = 'Disponible dans %s.',
    ['impound_destroyed'] = 'Votre véhicule %s a été envoyé en fourrière.',
    ['impound_empty'] = 'Aucun véhicule en fourrière.',

    -- Entreprise
    ['company_garage'] = 'Garage entreprise',
    ['company_max_out'] = 'Limite de véhicules sortis atteinte (%s).',
    ['company_logs'] = 'Historique garage',

    -- Admin
    ['admin_menu'] = 'Administration garages',
    ['admin_created'] = 'Garage créé.',
    ['admin_updated'] = 'Garage mis à jour.',
    ['admin_deleted'] = 'Garage supprimé.',
    ['admin_moved'] = 'Position mise à jour.',
    ['admin_no_garage'] = 'Aucun garage sélectionné.',
    ['admin_spawn_set'] = 'Point de spawn défini.',
    ['admin_store_set'] = 'Point de retour défini.',
    ['admin_blip_set'] = 'Blip configuré.',

    -- NUI
    ['nui_title'] = 'Garage',
    ['nui_search'] = 'Rechercher…',
    ['nui_sort_name'] = 'Nom',
    ['nui_sort_category'] = 'Catégorie',
    ['nui_sort_date'] = 'Date',
    ['nui_engine'] = 'Moteur',
    ['nui_body'] = 'Carrosserie',
    ['nui_fuel'] = 'Réservoir',
    ['nui_mileage'] = 'Kilométrage',
    ['nui_insurance'] = 'Assurance',
    ['nui_insured'] = 'Assuré',
    ['nui_not_insured'] = 'Non assuré',
    ['nui_status_stored'] = 'Rangé',
    ['nui_status_out'] = 'Sorti',
    ['nui_status_impound'] = 'Fourrière',
    ['nui_take_out'] = 'Sortir',
    ['nui_retrieve'] = 'Récupérer',
    ['nui_plate'] = 'Plaque',
    ['nui_close'] = 'Fermer',
    ['nui_fee'] = 'Frais',
    ['nui_empty'] = 'Aucun véhicule',
    ['nui_km'] = '%s km',

    -- Progress / anim
    ['progress_takeout'] = 'Sortie en cours…',
    ['progress_store'] = 'Rangement en cours…',
    ['progress_impound'] = 'Récupération…',
}
