--[[--------------------------------------------------------------------------
    Vestiaire / uniformes par grade (PHASE 8)
    Compatible illenium-appearance (composants clothing).
    Laisser les tables vides = conserver la tenue actuelle / ouvrir le menu appearance.
---------------------------------------------------------------------------]]

Config.Uniforms = {
    --- Si true et Integrations.appearance.enabled : ouvrir le menu illenium
    useAppearanceMenu = false,

    --- Structure : department → gradeName → { male = {...}, female = {...} }
    --- Chaque entrée : { component = number, drawable = number, texture = number }
    --- Props : { prop = number, drawable = number, texture = number }
    police = {
        officer = {
            male = {
                components = {
                    { component = 11, drawable = 55, texture = 0 }, -- torso
                    { component = 8, drawable = 58, texture = 0 },  -- undershirt
                    { component = 4, drawable = 35, texture = 0 },  -- legs
                    { component = 6, drawable = 25, texture = 0 },  -- shoes
                    { component = 3, drawable = 41, texture = 0 },  -- arms
                    { component = 9, drawable = 0, texture = 0 },   -- vest
                },
                props = {
                    { prop = 0, drawable = -1, texture = 0 },
                },
            },
            female = {
                components = {
                    { component = 11, drawable = 48, texture = 0 },
                    { component = 8, drawable = 35, texture = 0 },
                    { component = 4, drawable = 34, texture = 0 },
                    { component = 6, drawable = 25, texture = 0 },
                    { component = 3, drawable = 44, texture = 0 },
                },
                props = {},
            },
        },
        sergeant = {
            male = { components = {}, props = {} },
            female = { components = {}, props = {} },
        },
        lieutenant = {
            male = { components = {}, props = {} },
            female = { components = {}, props = {} },
        },
        captain = {
            male = { components = {}, props = {} },
            female = { components = {}, props = {} },
        },
    },

    sheriff = {
        deputy = {
            male = { components = {}, props = {} },
            female = { components = {}, props = {} },
        },
        sergeant = {
            male = { components = {}, props = {} },
            female = { components = {}, props = {} },
        },
    },

    statepolice = {
        trooper = {
            male = { components = {}, props = {} },
            female = { components = {}, props = {} },
        },
    },

    fib = {
        agent = {
            male = { components = {}, props = {} },
            female = { components = {}, props = {} },
        },
    },
}
