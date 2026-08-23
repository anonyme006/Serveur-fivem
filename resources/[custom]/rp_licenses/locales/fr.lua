Locales = {
    fr = {
        granted = 'Permis délivré : %s',
        revoked = 'Permis retiré : %s',
        already = 'Le joueur possède déjà ce permis.',
        missing = 'Le joueur ne possède pas ce permis.',
        no_perm = 'Vous ne pouvez pas gérer ce permis.',
        invalid = 'Type de permis invalide.',
    }
}

function L(key, ...)
    local s = Locales.fr[key] or key
    if select('#', ...) > 0 then return s:format(...) end
    return s
end
