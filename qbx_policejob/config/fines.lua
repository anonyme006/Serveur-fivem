--[[--------------------------------------------------------------------------
    Amendes & catégories (PHASE 7) — montants validés serveur uniquement
---------------------------------------------------------------------------]]

Config.Fines = {
    --- Compte débité par défaut
    defaultAccount = 'bank',
    allowCashFallback = true,
    --- Société créditée (job name) — nil = destruction de l'argent
    societyJob = 'police',
    --- Utiliser un système billing externe si présent
    useExternalBilling = false,
    externalBillingExport = nil, -- ex: { resource = 'rp_billing', name = 'CreateBill' }

    --- Retrait de points qbx_licenses :
    --- chaque amende peut définir :
    ---   licenseType = 'driver'|'motorcycle'|'boat'|'aircraft'
    ---   licensePoints = nombre de points à retirer (0 = aucun)
    categories = {
        traffic = {
            label = 'Code de la route',
            fines = {
                speeding = { label = 'Excès de vitesse', amount = 500, licenseType = 'driver', licensePoints = 2 },
                redlight = { label = 'Feu rouge', amount = 350, licenseType = 'driver', licensePoints = 2 },
                stopSign = { label = 'Stop ignoré', amount = 250, licenseType = 'driver', licensePoints = 1 },
                noLights = { label = 'Feux non conformes', amount = 150, licenseType = 'driver', licensePoints = 0 },
                parking = { label = 'Stationnement illégal', amount = 200, licenseType = 'driver', licensePoints = 0 },
            },
        },
        dangerous = {
            label = 'Conduite dangereuse',
            fines = {
                reckless = { label = 'Conduite dangereuse', amount = 1200, licenseType = 'driver', licensePoints = 4 },
                streetRace = { label = 'Course illégale', amount = 2500, licenseType = 'driver', licensePoints = 6 },
                dui = { label = 'Conduite sous influence', amount = 3000, licenseType = 'driver', licensePoints = 6 },
            },
        },
        hitrun = {
            label = 'Délit de fuite',
            fines = {
                hitAndRun = { label = 'Délit de fuite', amount = 4000, licenseType = 'driver', licensePoints = 6 },
                failToStop = { label = 'Refus d\'obtempérer', amount = 2000, licenseType = 'driver', licensePoints = 3 },
            },
        },
        assault = {
            label = 'Agression',
            fines = {
                simpleAssault = { label = 'Agression simple', amount = 1500 },
                aggravated = { label = 'Agression aggravée', amount = 5000 },
                resistArrest = { label = 'Résistance à l\'arrestation', amount = 1000 },
            },
        },
        weapons = {
            label = 'Arme illégale',
            fines = {
                illegalWeapon = { label = 'Possession d\'arme illégale', amount = 7500 },
                brandishing = { label = 'Exhibition d\'arme', amount = 3000 },
                discharge = { label = 'Tir en zone urbaine', amount = 10000 },
            },
        },
        drugs = {
            label = 'Trafic de drogue',
            fines = {
                possession = { label = 'Possession de stupéfiants', amount = 2000 },
                trafficking = { label = 'Trafic de stupéfiants', amount = 15000 },
                dealing = { label = 'Vente de stupéfiants', amount = 8000 },
            },
        },
        theft = {
            label = 'Vol',
            fines = {
                pettyTheft = { label = 'Vol simple', amount = 1000 },
                grandTheft = { label = 'Vol aggravé', amount = 5000 },
                vehicleTheft = { label = 'Vol de véhicule', amount = 7500 },
                robbery = { label = 'Braquage', amount = 20000 },
            },
        },
    },
}
