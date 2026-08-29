--- Exemple de configuration job pour qbx_core/shared/jobs.lua
--- Adapter les grades à votre serveur

--[[
    mechanic = {
        label = 'Mécanicien',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = { name = 'stagiaire', payment = 50 },
            [1] = { name = 'mecanicien', payment = 100 },
            [2] = { name = 'senior', payment = 150 },
            [3] = { name = 'chef', payment = 200 },
            [4] = { name = 'boss', payment = 250, isboss = true, bankAuth = true },
        },
    },
]]

--- Comptes société (Renewed-Banking / qb-banking) :
--- bennys, lscustoms — doivent correspondre à Config.Mechanics.*.societyAccount
