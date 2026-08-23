Locales = {
    fr = {
        stored = 'Véhicule rangé.',
        taken = 'Véhicule sorti.',
        not_yours = 'Ce véhicule ne vous appartient pas.',
        too_far = 'Trop loin du garage.',
        fee = 'Frais de fourrière : %s$',
        no_money = 'Fonds insuffisants.',
        already_out = 'Véhicule déjà dehors.',
    }
}
function L(k, ...) local s = Locales.fr[k] or k if select('#',...)>0 then return s:format(...) end return s end
