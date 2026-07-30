Config = {}

--- Statuts esx_status (valeurs absolues ajoutées, max 1_000_000)
Config.Status = {
    hunger = 'hunger',
    thirst = 'thirst',
}

--- Items consommables
--- type: 'food' | 'drink'
--- status: points ajoutés à faim/soif (0–1000000)
--- duration: ms de la barre de progression
Config.Items = {
    bread = {
        type = 'food',
        label = 'Pain',
        status = 150000,
        duration = 4000,
        anim = {
            dict = 'mp_player_inteat@burger',
            clip = 'mp_player_int_eat_burger',
            flags = 49,
        },
        prop = {
            model = 'prop_cs_burger_01',
            bone = 18905,
            coords = { x = 0.13, y = 0.05, z = 0.02 },
            rotation = { x = -50.0, y = 16.0, z = 60.0 },
        },
        notify = 'Vous mangez du pain…',
    },
    burger = {
        type = 'food',
        label = 'Burger',
        status = 250000,
        duration = 5000,
        anim = {
            dict = 'mp_player_inteat@burger',
            clip = 'mp_player_int_eat_burger',
            flags = 49,
        },
        prop = {
            model = 'prop_cs_burger_01',
            bone = 18905,
            coords = { x = 0.13, y = 0.05, z = 0.02 },
            rotation = { x = -50.0, y = 16.0, z = 60.0 },
        },
        notify = 'Vous mangez un burger…',
    },
    cheeseburger = {
        type = 'food',
        label = 'Cheeseburger',
        status = 280000,
        duration = 5500,
        anim = {
            dict = 'mp_player_inteat@burger',
            clip = 'mp_player_int_eat_burger',
            flags = 49,
        },
        prop = {
            model = 'prop_cs_burger_01',
            bone = 18905,
            coords = { x = 0.13, y = 0.05, z = 0.02 },
            rotation = { x = -50.0, y = 16.0, z = 60.0 },
        },
        notify = 'Vous mangez un cheeseburger…',
    },
    finger_shokobite = {
        type = 'food',
        label = 'Finger Shokobite',
        status = 180000,
        duration = 4500,
        anim = {
            dict = 'mp_player_inteat@burger',
            clip = 'mp_player_int_eat_burger',
            flags = 49,
        },
        notify = 'Vous grignotez…',
    },
    poulet_barquette = {
        type = 'food',
        label = 'Poulet en barquette',
        status = 300000,
        duration = 6000,
        anim = {
            dict = 'mp_player_inteat@burger',
            clip = 'mp_player_int_eat_burger',
            flags = 49,
        },
        notify = 'Vous mangez du poulet…',
    },
    water = {
        type = 'drink',
        label = 'Eau',
        status = 200000,
        duration = 3500,
        anim = {
            dict = 'mp_player_intdrink',
            clip = 'loop_bottle',
            flags = 49,
        },
        prop = {
            model = 'prop_ld_flow_bottle',
            bone = 18905,
            coords = { x = 0.12, y = 0.008, z = 0.03 },
            rotation = { x = 240.0, y = -60.0, z = 0.0 },
        },
        notify = 'Vous buvez de l\'eau…',
    },
    jus_multivitamine = {
        type = 'drink',
        label = 'Jus Multivitaminé',
        status = 250000,
        duration = 4000,
        anim = {
            dict = 'mp_player_intdrink',
            clip = 'loop_bottle',
            flags = 49,
        },
        prop = {
            model = 'prop_ld_flow_bottle',
            bone = 18905,
            coords = { x = 0.12, y = 0.008, z = 0.03 },
            rotation = { x = 240.0, y = -60.0, z = 0.0 },
        },
        notify = 'Vous buvez un jus…',
    },
    juice = {
        type = 'drink',
        label = 'Jus',
        status = 220000,
        duration = 4000,
        anim = {
            dict = 'mp_player_intdrink',
            clip = 'loop_bottle',
            flags = 49,
        },
        prop = {
            model = 'prop_ld_flow_bottle',
            bone = 18905,
            coords = { x = 0.12, y = 0.008, z = 0.03 },
            rotation = { x = 240.0, y = -60.0, z = 0.0 },
        },
        notify = 'Vous buvez un jus…',
    },
}

--- Labels de progression si notify absent
Config.DefaultFoodLabel = 'Vous mangez…'
Config.DefaultDrinkLabel = 'Vous buvez…'
