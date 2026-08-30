--- Ajouter ce job dans qbx_core/shared/jobs.lua

--[[
    marlowe = {
        label = 'Marlowe Vineyard',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [0] = { name = 'Stagiaire', payment = 50 },
            [1] = { name = 'Vigneron', payment = 75 },
            [2] = { name = 'Ouvrier', payment = 100 },
            [3] = { name = 'Responsable', payment = 150, isboss = true, bankAuth = true },
            [4] = { name = 'Directeur', payment = 200, isboss = true, bankAuth = true },
        },
    },
]]
