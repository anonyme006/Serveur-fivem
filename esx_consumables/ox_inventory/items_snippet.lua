--[[
    À fusionner dans ox_inventory/data/items.lua

    Chaque item utilise l'export esx_consumables pour afficher
    la barre capsule orange pendant qu'on mange / boit.
]]

return {
    ['bread'] = {
        label = 'Pain',
        weight = 220,
        stack = true,
        close = true,
        consume = 1,
        client = {
            export = 'esx_consumables.useItem',
        },
    },
    ['burger'] = {
        label = 'Burger',
        weight = 350,
        stack = true,
        close = true,
        consume = 1,
        client = {
            export = 'esx_consumables.useItem',
        },
    },
    ['cheeseburger'] = {
        label = 'Cheeseburger',
        weight = 380,
        stack = true,
        close = true,
        consume = 1,
        client = {
            export = 'esx_consumables.useItem',
        },
    },
    ['water'] = {
        label = 'Eau',
        weight = 330,
        stack = true,
        close = true,
        consume = 1,
        client = {
            export = 'esx_consumables.useItem',
        },
    },
    ['jus_multivitamine'] = {
        label = 'Jus Multivitaminé',
        weight = 350,
        stack = true,
        close = true,
        consume = 1,
        client = {
            export = 'esx_consumables.useItem',
        },
    },
    ['juice'] = {
        label = 'Jus',
        weight = 350,
        stack = true,
        close = true,
        consume = 1,
        client = {
            export = 'esx_consumables.useItem',
        },
    },
    ['finger_shokobite'] = {
        label = 'Finger Shokobite',
        weight = 200,
        stack = true,
        close = true,
        consume = 1,
        client = {
            export = 'esx_consumables.useItem',
        },
    },
    ['poulet_barquette'] = {
        label = 'Poulet en barquette',
        weight = 450,
        stack = true,
        close = true,
        consume = 1,
        client = {
            export = 'esx_consumables.useItem',
        },
    },
}
