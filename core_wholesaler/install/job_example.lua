--[[
    Snippet job à ajouter dans qbx_core/shared/jobs.lua
]]

--[[
['wholesaler'] = {
    label = 'Grossiste Central',
    type = 'leo', -- ou nil / 'civ'
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        [0] = { name = 'Employé', payment = 50 },
        [1] = { name = 'Préparateur', payment = 75 },
        [2] = { name = 'Manager', payment = 100 },
        [3] = { name = 'Patron', isboss = true, payment = 150 },
    },
},
]]
