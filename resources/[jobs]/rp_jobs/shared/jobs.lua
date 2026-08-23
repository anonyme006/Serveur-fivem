--- Définitions métiers additionnels / surcharges FR
--- Utilise exports.qbx_core:CreateJobs au runtime (non persistant fichiers).
--- Pour persistance, fusionner aussi dans qbx_core/shared/jobs.lua après install.

SharedJobs = {
    burgershot = {
        label = 'Burger Shot',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = { name = 'Stagiaire', payment = 50 },
            [1] = { name = 'Employé', payment = 75 },
            [2] = { name = 'Cuisinier', payment = 100 },
            [3] = { name = 'Manager', payment = 125, isboss = true, bankAuth = true },
            [4] = { name = 'Patron', payment = 150, isboss = true, bankAuth = true },
        },
    },
    uwu = {
        label = 'UwU Café',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = { name = 'Stagiaire', payment = 50 },
            [1] = { name = 'Barista', payment = 75 },
            [2] = { name = 'Chef', payment = 100 },
            [3] = { name = 'Manager', payment = 125, isboss = true, bankAuth = true },
            [4] = { name = 'Patron', payment = 150, isboss = true, bankAuth = true },
        },
    },
    government = {
        label = 'Gouvernement',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = { name = 'Assistant', payment = 100 },
            [1] = { name = 'Conseiller', payment = 150 },
            [2] = { name = 'Ministre', payment = 200, isboss = true, bankAuth = true },
            [3] = { name = 'Maire', payment = 250, isboss = true, bankAuth = true },
        },
    },
    doj = {
        label = 'Department of Justice',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = { name = 'Greffier', payment = 100 },
            [1] = { name = 'Avocat', payment = 150 },
            [2] = { name = 'Procureur', payment = 200, isboss = true, bankAuth = true },
            [3] = { name = 'Juge', payment = 250, isboss = true, bankAuth = true },
        },
    },
}
