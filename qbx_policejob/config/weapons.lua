--[[--------------------------------------------------------------------------
    Armurerie & armes — distribution via ox_inventory (PHASE 8)
---------------------------------------------------------------------------]]

Config.Weapons = {
    --- Item ox_inventory pour le taser
    taserWeapon = 'WEAPON_STUNGUN',

    --- Armureries par département → grade minimum → liste d'items
    armories = {
        police = {
            {
                item = 'WEAPON_STUNGUN',
                label = 'Taser',
                minGrade = 0,
                amount = 1,
            },
            {
                item = 'WEAPON_COMBATPISTOL',
                label = 'Glock',
                minGrade = 1,
                amount = 1,
            },
            {
                item = 'ammo-9',
                label = 'Munitions 9mm',
                minGrade = 1,
                amount = 50,
            },
            {
                item = 'WEAPON_PUMPSHOTGUN',
                label = 'Shotgun',
                minGrade = 2,
                amount = 1,
            },
            {
                item = 'WEAPON_SMG',
                label = 'SMG',
                minGrade = 2,
                amount = 1,
            },
            {
                item = 'WEAPON_CARBINERIFLE',
                label = 'Carbine Rifle',
                minGrade = 3,
                amount = 1,
            },
            {
                item = 'ammo-rifle',
                label = 'Munitions fusil',
                minGrade = 3,
                amount = 60,
            },
            {
                item = 'armor',
                label = 'Gilet pare-balles',
                minGrade = 1,
                amount = 1,
            },
            {
                item = 'handcuffs',
                label = 'Menottes',
                minGrade = 0,
                amount = 1,
            },
            {
                item = 'spike_strip',
                label = 'Herse',
                minGrade = 2,
                amount = 1,
            },
            {
                item = 'gsr_cleaner',
                label = 'Kit nettoyage GSR',
                minGrade = 1,
                amount = 1,
            },
        },
        sheriff = {
            {
                item = 'WEAPON_STUNGUN',
                label = 'Taser',
                minGrade = 0,
                amount = 1,
            },
            {
                item = 'WEAPON_COMBATPISTOL',
                label = 'Glock',
                minGrade = 0,
                amount = 1,
            },
            {
                item = 'ammo-9',
                label = 'Munitions 9mm',
                minGrade = 0,
                amount = 50,
            },
            {
                item = 'WEAPON_PUMPSHOTGUN',
                label = 'Shotgun',
                minGrade = 1,
                amount = 1,
            },
            {
                item = 'WEAPON_CARBINERIFLE',
                label = 'Carbine Rifle',
                minGrade = 2,
                amount = 1,
            },
            {
                item = 'handcuffs',
                label = 'Menottes',
                minGrade = 0,
                amount = 1,
            },
            {
                item = 'spike_strip',
                label = 'Herse',
                minGrade = 1,
                amount = 1,
            },
        },
        statepolice = {
            {
                item = 'WEAPON_STUNGUN',
                label = 'Taser',
                minGrade = 0,
                amount = 1,
            },
            {
                item = 'WEAPON_COMBATPISTOL',
                label = 'Glock',
                minGrade = 0,
                amount = 1,
            },
            {
                item = 'WEAPON_CARBINERIFLE',
                label = 'Carbine Rifle',
                minGrade = 1,
                amount = 1,
            },
            {
                item = 'handcuffs',
                label = 'Menottes',
                minGrade = 0,
                amount = 1,
            },
            {
                item = 'spike_strip',
                label = 'Herse',
                minGrade = 1,
                amount = 1,
            },
        },
        fib = {
            {
                item = 'WEAPON_STUNGUN',
                label = 'Taser',
                minGrade = 0,
                amount = 1,
            },
            {
                item = 'WEAPON_COMBATPISTOL',
                label = 'Glock',
                minGrade = 0,
                amount = 1,
            },
            {
                item = 'WEAPON_CARBINERIFLE',
                label = 'Carbine Rifle',
                minGrade = 1,
                amount = 1,
            },
        },
    },

    --- Réparation d'armes (PHASE 8)
    repair = {
        enabled = true,
        duration = 8000,
        cost = 0,
        account = 'bank',
    },
}
