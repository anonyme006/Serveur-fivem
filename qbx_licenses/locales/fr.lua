Locales = {
    fr = {
        no_player = 'Joueur introuvable.',
        no_perm = 'Tu n\'as pas la permission.',
        not_on_duty = 'Tu dois être en service.',
        invalid_type = 'Type de permis invalide.',
        invalid_points = 'Nombre de points invalide.',
        already_owned = 'Ce permis est déjà possédé.',
        not_owned = 'Ce permis n\'est pas possédé.',
        granted = 'Permis délivré : %s (%s pts)',
        revoked = 'Permis révoqué : %s',
        points_removed = 'Retrait de %s point(s) sur %s — reste %s/%s',
        points_removed_self = 'La police a retiré %s point(s) de ton permis %s — reste %s/%s',
        points_set = 'Points %s définis à %s/%s',
        suspended = 'Permis %s suspendu (0 point).',
        suspended_self = 'Ton permis %s est suspendu (0 point).',
        menu_title = 'Permis à points',
        menu_player = 'Gestion permis — #%s',
        menu_remove = 'Retirer des points',
        menu_grant = 'Délivrer un permis',
        menu_revoke = 'Révoquer un permis',
        menu_view = 'Voir les permis',
        select_license = 'Choisir un permis',
        select_amount = 'Nombre de points à retirer',
        no_nearby = 'Aucun joueur à proximité.',
        card_title = 'Permis de conduire',
        card_points = '%s / %s pts',
        card_valid = 'Valide',
        card_invalid = 'Non détenu',
        card_suspended = 'Suspendu',
        ox_target_manage = 'Gérer les permis',
        ox_target_show = 'Montrer ses permis',
    },
}

---@param key string
---@param ... any
---@return string
function L(key, ...)
    local locale = Config and Config.Locale or 'fr'
    local pack = Locales[locale] or Locales.fr
    local str = pack[key] or key
    if select('#', ...) > 0 then
        return str:format(...)
    end
    return str
end
