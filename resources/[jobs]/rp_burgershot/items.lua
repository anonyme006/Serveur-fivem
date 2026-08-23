-- Items Burger Shot pour ox_inventory/data/items.lua
-- À fusionner manuellement après install ox_inventory

return {
    ['bs_raw_patty'] = {
        label = 'Steak cru',
        weight = 120,
        stack = true,
    },
    ['bs_patty'] = {
        label = 'Steak cuit',
        weight = 120,
        stack = true,
    },
    ['bs_potato'] = {
        label = 'Pomme de terre',
        weight = 100,
        stack = true,
    },
    ['bs_fries'] = {
        label = 'Frites',
        weight = 110,
        stack = true,
        client = {
            status = { hunger = 120000 },
            anim = 'eating',
            prop = 'chips',
            usetime = 2500,
        },
    },
    ['bs_bun'] = {
        label = 'Pain burger',
        weight = 80,
        stack = true,
    },
    ['bs_burger'] = {
        label = 'Burger Shot',
        weight = 220,
        stack = true,
        client = {
            status = { hunger = 350000 },
            anim = 'eating',
            prop = 'burger',
            usetime = 3000,
        },
    },
    ['bs_drink'] = {
        label = 'Boisson BS',
        weight = 150,
        stack = true,
        client = {
            status = { thirst = 250000 },
            anim = 'drinking',
            prop = 'cup',
            usetime = 2500,
        },
    },
}
