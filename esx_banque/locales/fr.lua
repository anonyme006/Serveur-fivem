Locales = Locales or {}

Locales['fr'] = {
    bank_title = 'Banque',
    atm_title = 'Distributeur (DAB)',
    open_bank = '[E] Ouvrir la banque',
    open_atm = '[E] Utiliser le DAB',
    accounts = 'Comptes',
    personal = 'Personnel',
    business = 'Entreprise',
    transactions = 'Transactions',
    actions = 'Actions',
    transfer = 'Virement',
    deposit = 'Dépôt',
    withdraw = 'Retrait',
    csv = 'Relevé CSV',
    total_balance = 'Solde total',
    my_balance = 'Mon solde',
    owner = 'Propriétaire',
    account_number = 'Numéro de compte',
    company_name = 'Nom de l\'entreprise',
    role = 'Rôle',
    no_transactions = 'Aucune transaction pour ce compte',
    add_recipient = 'Ajouter un destinataire',
    favorites = 'Comptes favoris',
    invalid_amount = 'Montant invalide',
    not_enough_money = 'Fonds insuffisants',
    not_enough_bank = 'Solde bancaire insuffisant',
    not_enough_cash = 'Espèces insuffisantes',
    transfer_success = 'Virement de $%s effectué',
    deposit_success = 'Dépôt de $%s effectué',
    withdraw_success = 'Retrait de $%s effectué',
    recipient_added = 'Destinataire ajouté',
    recipient_exists = 'Ce destinataire existe déjà',
    recipient_invalid = 'Destinataire invalide',
    no_permission = 'Vous n\'avez pas la permission',
    player_not_found = 'Joueur introuvable',
    same_account = 'Impossible de virer vers le même compte',
    history_title = 'Historique des opérations',
    filter = 'Filtrer les résultats',
    my_account = 'Mon compte',
    operation = 'Opération',
    transfer_tab = 'Transfert',
    business_tab = 'Entreprise',
}

function Translate(key, ...)
    local str = Locales[Config.Locale] and Locales[Config.Locale][key] or key
    if select('#', ...) > 0 then
        return string.format(str, ...)
    end
    return str
end
