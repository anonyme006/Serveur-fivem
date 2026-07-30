Config = {}

Config.Locale = 'fr'

-- Devise affichée dans l'UI
Config.Currency = '$'

-- Montants min / max
Config.MinAmount = 1
Config.MaxAmount = 1000000

-- Historique : nombre max de transactions affichées
Config.MaxHistory = 50

-- Fermer l'UI avec Échap
Config.CloseWithEscape = true

-- Utiliser esx_addonaccount pour les comptes société (entreprises)
Config.UseSocietyAccount = true

-- Préfixe des comptes société (esx_addonaccount)
Config.SocietyPrefix = 'society_'

-- Jobs exclus des comptes entreprise (pas de compte société)
Config.ExcludedJobs = {
    unemployed = true,
}

-- Grades minimum pour retirer / virer depuis le compte entreprise
-- (grade number ESX). Dépôt autorisé pour tous les grades.
Config.BusinessWithdrawMinGrade = 2
Config.BusinessTransferMinGrade = 2

--[[
    Agences bancaires (interface Banque complète)
]]
Config.Banks = {
    {
        name = 'Banque Centrale',
        coords = vector3(149.46, -1040.53, 29.37),
        blip = {
            enabled = true,
            sprite = 108,
            colour = 2,
            scale = 0.85,
            label = 'Banque',
        },
        marker = {
            type = 1,
            size = vector3(1.5, 1.5, 0.5),
            color = { r = 46, g = 204, b = 113, a = 120 },
        },
        drawDistance = 20.0,
        interactDistance = 2.0,
    },
    {
        name = 'Banque Paleto',
        coords = vector3(-112.22, 6469.29, 31.63),
        blip = {
            enabled = true,
            sprite = 108,
            colour = 2,
            scale = 0.75,
            label = 'Banque',
        },
        marker = {
            type = 1,
            size = vector3(1.5, 1.5, 0.5),
            color = { r = 46, g = 204, b = 113, a = 120 },
        },
        drawDistance = 20.0,
        interactDistance = 2.0,
    },
}

--[[
    Distributeurs (DAB) — interface simplifiée
    Si empty, les props ATM du monde sont détectés automatiquement.
]]
Config.ATMs = {
    -- Exemples de positions fixes (optionnel)
    -- vector3(147.45, -1035.71, 29.34),
}

-- Props DAB détectés automatiquement
Config.ATMModels = {
    `prop_atm_01`,
    `prop_atm_02`,
    `prop_atm_03`,
    `prop_fleeca_atm`,
}

Config.ATMInteractDistance = 1.5
Config.ATMDrawDistance = 8.0

-- Génération numéro de compte perso (affichage uniquement)
Config.AccountNumberPrefix = 'US7FL'
