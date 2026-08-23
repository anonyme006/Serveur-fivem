Locales = {
    fr = {
        created = 'Facture #%s envoyée (%s$).',
        received = 'Nouvelle facture #%s : %s$ — %s',
        paid = 'Facture #%s payée.',
        refused = 'Facture #%s refusée.',
        expired = 'Facture expirée.',
        not_found = 'Facture introuvable.',
        no_money = 'Fonds insuffisants.',
        no_perm = 'Vous ne pouvez pas facturer.',
        invalid = 'Données de facture invalides.',
        too_far = 'Joueur trop éloigné.',
    }
}

function L(key, ...)
    local s = Locales.fr[key] or key
    if select('#', ...) > 0 then return s:format(...) end
    return s
end
