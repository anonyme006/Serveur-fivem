Locales = Locales or {}

Locales['fr'] = {
    missing_dep = '[%s] ERROR: %s is missing.\n[%s] Please ensure %s is started before this resource.',
    player_not_found = 'Joueur introuvable.',
    no_permission = 'Permission refusée.',
    invalid_amount = 'Montant invalide.',
    invalid_args = 'Arguments invalides.',
    success = 'Opération réussie.',
    error = 'Une erreur est survenue.',
}

---@param key string
---@param ... any
---@return string
function _(key, ...)
    local locale = (Config and Config.Locale) or 'fr'
    local str = (Locales[locale] and Locales[locale][key]) or (Locales['fr'] and Locales['fr'][key]) or key
    if select('#', ...) > 0 then
        return str:format(...)
    end
    return str
end
