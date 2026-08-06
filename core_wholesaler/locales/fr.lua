--[[
    Locales FR — core_wholesaler
]]

Locales = Locales or {}

Locales['fr'] = {
    -- Général
    ['wholesaler']           = 'Grossiste Central',
    ['no_permission']        = 'Vous n\'avez pas la permission.',
    ['not_authorized']       = 'Votre entreprise n\'est pas autorisée ici.',
    ['invalid_amount']       = 'Quantité invalide.',
    ['error']                = 'Une erreur est survenue.',
    ['success']              = 'Succès',
    ['cancelled']            = 'Annulé',
    ['confirm']              = 'Confirmer',
    ['back']                 = 'Retour',
    ['close']                = 'Fermer',
    ['currency']             = '$%s',

    -- Menu principal
    ['menu_title']           = 'Grossiste Central',
    ['menu_buy']             = 'Acheter des marchandises',
    ['menu_stock']           = 'Voir le stock disponible',
    ['menu_history']         = 'Historique des achats',
    ['menu_orders']          = 'Mes commandes',
    ['menu_pickup']          = 'Retirer une commande',
    ['menu_delivery']        = 'Gestion des livraisons',
    ['menu_admin']           = 'Administration',
    ['menu_boss']            = 'Menu patron',
    ['menu_export']          = 'Export de cargaison',
    ['menu_npc_vendor']      = 'Vendeur automatique',

    -- PNJ hors service
    ['target_npc_vendor']    = 'Acheter (hors service)',
    ['npc_staff_on_duty']    = 'Un employé est en service. Adressez-vous à l\'accueil.',
    ['npc_sale_success']     = 'Achat #%s effectué. Articles ajoutés à l\'inventaire.',
    ['npc_instant_hint']     = 'Remise immédiate des articles',
    ['npc_order_hint']       = 'Commande préparée rapidement',
    ['npc_markup']           = 'Majoration +%s%%',

    -- Achat
    ['select_category']      = 'Choisir une catégorie',
    ['product_stock']        = 'Stock : %s',
    ['product_price']        = 'Prix : $%s',
    ['product_qty']          = 'Quantité à acheter',
    ['cart_empty']           = 'Votre panier est vide.',
    ['cart_add']             = 'Ajouté au panier',
    ['cart_title']           = 'Panier',
    ['cart_total']           = 'Total TTC : $%s',
    ['cart_checkout']        = 'Valider la commande',
    ['cart_clear']           = 'Vider le panier',
    ['out_of_stock']         = 'Stock insuffisant pour %s.',
    ['ammo_denied']          = 'Vous n\'êtes pas autorisé à acheter des munitions.',
    ['order_created']        = 'Commande #%s créée. Préparation en cours…',
    ['order_ready']          = 'Votre commande #%s est prête au retrait !',
    ['max_lines']            = 'Nombre maximum de lignes atteint.',

    -- Paiement
    ['payment_method']       = 'Mode de paiement',
    ['pay_society']          = 'Compte société',
    ['pay_bank']             = 'Banque personnelle',
    ['pay_cash']             = 'Argent liquide',
    ['payment_success']      = 'Paiement de $%s effectué.',
    ['payment_failed']       = 'Fonds insuffisants.',
    ['vat_included']         = 'TVA incluse : $%s',

    -- Stock
    ['stock_title']          = 'Stock disponible',
    ['stock_empty']          = 'Aucun produit en stock.',
    ['stock_qty']            = '%s × %s — $%s',

    -- Commandes
    ['orders_title']         = 'Mes commandes',
    ['orders_empty']         = 'Aucune commande.',
    ['order_status']         = 'Statut : %s',
    ['order_total']          = 'Total : $%s',
    ['order_date']           = 'Date : %s',
    ['status_pending']       = 'En attente',
    ['status_prepared']      = 'Préparée',
    ['status_available']     = 'Disponible',
    ['status_withdrawn']     = 'Retirée',
    ['status_delivered']     = 'Livrée',
    ['status_cancelled']     = 'Annulée',

    -- Retrait
    ['pickup_title']         = 'Retrait de commande',
    ['pickup_none']          = 'Aucune commande disponible au retrait.',
    ['pickup_success']       = 'Commande #%s retirée. Articles ajoutés à l\'inventaire.',
    ['pickup_inventory']     = 'Inventaire plein. Libérez de la place.',
    ['delivery_mode']        = 'Mode de récupération',
    ['mode_pickup']          = 'Retrait au quai',
    ['mode_delivery']        = 'Livraison',

    -- Historique
    ['history_title']        = 'Historique des achats',
    ['history_empty']        = 'Aucun historique.',
    ['history_entry']        = '#%s — $%s — %s',

    -- Livraison transporteur
    ['delivery_title']       = 'Livraisons disponibles',
    ['delivery_empty']       = 'Aucune livraison disponible.',
    ['delivery_take']        = 'Prendre la livraison #%s',
    ['delivery_client']      = 'Client : %s',
    ['delivery_reward']      = 'Récompense : $%s',
    ['delivery_pickup_point']= 'Point de retrait : Quai grossiste',
    ['delivery_started']     = 'Livraison #%s démarrée. Chargez au quai.',
    ['delivery_loaded']      = 'Cargaison chargée. Rendez-vous chez le client.',
    ['delivery_complete']    = 'Livraison #%s terminée. Récompense : $%s',
    ['delivery_not_yours']   = 'Cette livraison ne vous appartient pas.',
    ['delivery_need_job']    = 'Vous devez être transporteur.',

    -- Export
    ['export_title']         = 'Export de cargaison',
    ['export_select_dest']   = 'Destination',
    ['export_select_items']  = 'Sélectionner les produits',
    ['export_started']       = 'Export vers %s démarré.',
    ['export_complete']      = 'Export livré ! Gain : $%s',
    ['export_no_stock']      = 'Stock insuffisant pour l\'export.',

    -- Admin / Boss
    ['admin_title']          = 'Administration',
    ['boss_title']           = 'Bureau du responsable',
    ['boss_revenue']         = 'Chiffre d\'affaires : $%s',
    ['boss_profit']          = 'Bénéfices : $%s',
    ['boss_orders']          = 'Commandes',
    ['boss_companies']       = 'Entreprises clientes',
    ['boss_employees']       = 'Employés',
    ['boss_add_stock']       = 'Ajouter du stock',
    ['boss_remove_stock']    = 'Supprimer du stock',
    ['boss_edit_price']      = 'Modifier les prix',
    ['boss_import']          = 'Importer une livraison',
    ['boss_hire']            = 'Recruter',
    ['boss_fire']            = 'Licencier',
    ['boss_manage']          = 'Gérer les employés',
    ['stock_added']          = 'Stock ajouté : +%s %s',
    ['stock_removed']        = 'Stock retiré : -%s %s',
    ['price_updated']        = 'Prix de %s mis à jour : $%s',
    ['import_success']       = 'Livraison importée (%s articles).',
    ['employee_hired']       = '%s recruté.',
    ['employee_fired']       = '%s licencié.',
    ['no_nearby_player']     = 'Aucun joueur à proximité.',
    ['companies_empty']      = 'Aucune entreprise cliente.',
    ['employees_empty']      = 'Aucun employé.',

    -- Zones
    ['target_reception']     = 'Accueil Grossiste',
    ['target_order']         = 'Passer commande',
    ['target_pickup']        = 'Retirer une commande',
    ['target_dock']          = 'Quai de chargement',
    ['target_boss']          = 'Bureau du responsable',
}
