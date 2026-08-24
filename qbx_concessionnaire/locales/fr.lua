Locales = {}

Locales['fr'] = {
    ['press_open'] = '[E] Ouvrir le concessionnaire',
    ['blip_label'] = 'Concessionnaire',
    ['shop_title'] = 'Concessionnaire',
    ['not_enough_money'] = 'Vous n\'avez pas assez d\'argent.',
    ['purchase_success'] = 'Vous avez acheté un(e) %s pour $%s.',
    ['purchase_failed'] = 'Achat impossible.',
    ['vehicle_out'] = 'Votre véhicule vous attend sur le point vert.',
    ['already_owned_plate'] = 'Erreur de plaque, réessayez.',
    ['search'] = 'Rechercher',
    ['search_desc'] = 'Chercher un modèle ou un nom',
    ['search_placeholder'] = 'Rechercher un véhicule...',
    ['search_results'] = 'Résultats',
    ['no_results'] = 'Aucun résultat',
    ['buy'] = 'Acheter',
    ['buy_desc'] = 'Payer et récupérer le véhicule',
    ['cancel'] = 'Annuler',
    ['confirm_title'] = 'Confirmation',
    ['confirm_buy'] = 'Acheter %s pour $%s ?',
    ['no_vehicles'] = 'Aucun véhicule trouvé.',
    ['preview'] = 'Aperçu',
    ['preview_desc'] = 'Voir le véhicule en showroom',
    ['preview_failed'] = 'Impossible d\'afficher l\'aperçu.',
    ['invalid_model'] = 'Modèle invalide.',
    ['vehicle_price'] = 'Prix : $%s',
    ['category_desc'] = 'Parcourir cette catégorie',
    ['spawn_blocked'] = 'Point de livraison occupé',
    ['too_far'] = 'Trop loin du concessionnaire',
    ['close'] = 'Fermer',
}

function Translate(str, ...)
    local locale = Locales[Config.Locale] or Locales['fr']
    if locale[str] then
        return string.format(locale[str], ...)
    end
    return str
end
