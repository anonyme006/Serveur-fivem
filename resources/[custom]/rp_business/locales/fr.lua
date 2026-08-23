Locales = {
    fr = {
        no_business = 'Entreprise introuvable.',
        no_boss = 'Action réservée au patron.',
        announced = 'Annonce publiée.',
        hired = 'Employé recruté.',
        fired = 'Employé licencié.',
        promoted = 'Employé promu.',
        demoted = 'Employé rétrogradé.',
        deposited = 'Dépôt effectué.',
        withdrawn = 'Retrait effectué.',
        insufficient = 'Fonds insuffisants.',
    }
}

function L(key, ...)
    local s = Locales.fr[key] or key
    if select('#', ...) > 0 then return s:format(...) end
    return s
end
