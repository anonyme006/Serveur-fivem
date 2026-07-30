Locales = {}

Locales['fr'] = {
    ['press_open'] = '[E] Ouvrir le concessionnaire',
    ['blip_label'] = 'Concessionnaire',
    ['not_enough_money'] = 'Vous n\'avez pas assez d\'argent.',
    ['purchase_success'] = 'Vous avez acheté un(e) %s pour $%s.',
    ['purchase_failed'] = 'Achat impossible.',
    ['vehicle_out'] = 'Votre véhicule vous attend à l\'extérieur.',
    ['already_owned_plate'] = 'Erreur de plaque, réessayez.',
    ['shop_title'] = 'Voiture',
    ['search_placeholder'] = 'Rechercher un véhicule...',
    ['buy'] = 'Acheter',
    ['cancel'] = 'Annuler',
    ['confirm_buy'] = 'Acheter %s pour $%s ?',
    ['no_vehicles'] = 'Aucun véhicule trouvé.',
    ['test_drive'] = 'Essai',
    ['close'] = 'Fermer',
}

function _(str, ...)
    local locale = Locales[Config.Locale] or Locales['fr']
    if locale[str] then
        return string.format(locale[str], ...)
    end
    return str
end
