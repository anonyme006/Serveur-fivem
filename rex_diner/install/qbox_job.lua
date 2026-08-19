--[[
    À ajouter dans qbx_core/shared/jobs.lua
]]

return {
    rex_diner = {
        label = 'Rex Diner',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [0] = { name = 'Stagiaire', payment = 50 },
            [1] = { name = 'Employé', payment = 75 },
            [2] = { name = 'Cuisinier', payment = 100 },
            [3] = { name = 'Manager', payment = 125 },
            [4] = { name = 'Patron', isboss = true, payment = 150 },
        },
    },
}
