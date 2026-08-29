--- Items ox_inventory — à fusionner dans data/items.lua ou un fichier dédié

return {
    ['engine_oil'] = {
        label = 'Huile moteur',
        weight = 500,
        stack = true,
        close = true,
        description = 'Huile pour entretien moteur',
    },
    ['brake_pads'] = {
        label = 'Plaquettes de frein',
        weight = 800,
        stack = true,
        close = true,
    },
    ['spark_plug'] = {
        label = 'Bougie d\'allumage',
        weight = 200,
        stack = true,
        close = true,
    },
    ['car_battery'] = {
        label = 'Batterie',
        weight = 5000,
        stack = true,
        close = true,
    },
    ['tire'] = {
        label = 'Pneu',
        weight = 10000,
        stack = false,
        close = true,
    },
    ['repair_kit'] = {
        label = 'Kit de réparation',
        weight = 3000,
        stack = true,
        close = true,
    },
    ['body_parts'] = {
        label = 'Pièces carrosserie',
        weight = 4000,
        stack = true,
        close = true,
    },
}
