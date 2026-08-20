--[[
    Job Qbox — à fusionner dans qbx_core/shared/jobs.lua
    (ou votre fichier de jobs équivalent)
]]

['mechanic'] = {
    label = 'Los Santos Customs',
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        [0] = { name = 'stagiaire', payment = 50 },
        [1] = { name = 'mechanic', payment = 100 },
        [2] = { name = 'senior', payment = 150 },
        [3] = { name = 'chief', payment = 200 },
        [4] = { name = 'boss', isboss = true, payment = 250 },
    },
},