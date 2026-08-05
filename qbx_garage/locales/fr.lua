Locales = {}

Locales['fr'] = {
    ['press_open'] = '[E] Ouvrir le garage',
    ['press_store'] = '[E] Ranger le véhicule',
    ['blip_label'] = 'Garage',
    ['menu_title'] = 'Garage',
    ['impound_title'] = 'Fourrière',
    ['no_vehicles'] = 'Aucun véhicule ici',
    ['take_out'] = 'Sortir',
    ['store'] = 'Ranger',
    ['close'] = 'Fermer',
    ['vehicle_out'] = 'Véhicule déjà sorti',
    ['spawn_blocked'] = 'Point de spawn occupé',
    ['not_owned'] = 'Ce véhicule ne vous appartient pas',
    ['stored'] = 'Véhicule rangé',
    ['taken_out'] = 'Véhicule sorti',
    ['not_enough_money'] = 'Fonds insuffisants',
    ['impound_pay'] = 'Récupérer pour $%s',
    ['must_be_driver'] = 'Vous devez être conducteur',
    ['too_far'] = 'Trop loin du garage',
    ['error'] = 'Action impossible',
}

function Translate(str, ...)
    local locale = Locales[Config.Locale] or Locales['fr']
    if locale[str] then
        return string.format(locale[str], ...)
    end
    return str
end
