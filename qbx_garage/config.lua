Config = {}

Config.Locale = 'fr'

-- États player_vehicles (Qbox)
-- 0 = sorti | 1 = garage | 2 = fourrière
Config.VehicleState = {
    OUT = 0,
    GARAGED = 1,
    IMPOUND = 2,
}

Config.DefaultGarage = 'pillbox'
Config.StoreDistance = 5.0
Config.SpawnCheckRadius = 2.8
Config.ImpoundAccount = 'bank' -- cash | bank

--[[
    Marqueurs au sol (comme sur la photo)
    type 25 = disque plat
]]
Config.Markers = {
    menu = { -- point rouge = ouvrir le menu
        type = 25,
        size = vector3(2.2, 2.2, 0.15),
        color = { r = 220, g = 40, b = 40, a = 140 },
        bobUpAndDown = false,
        rotate = false,
    },
    park = { -- points verts = places de stationnement / spawn / rangement
        type = 25,
        size = vector3(2.6, 2.6, 0.15),
        color = { r = 40, g = 220, b = 80, a = 140 },
        bobUpAndDown = false,
        rotate = false,
    },
}

--[[
    type = 'public' | 'job' | 'gang' | 'impound'
    menu = point rouge (accès menu)
    parks = points verts (vector4 = place + heading spawn)
]]
Config.Garages = {
    {
        name = 'pillbox',
        label = 'Garage Pillbox',
        type = 'public',
        blip = { enabled = true, sprite = 357, colour = 3, scale = 0.75 },
        drawDistance = 40.0,
        interactDistance = 1.8,
        menu = vector3(215.95, -810.12, 30.73),
        parks = {
            vector4(222.58, -804.23, 30.58, 248.0),
            vector4(223.98, -801.68, 30.58, 248.0),
            vector4(225.55, -799.12, 30.58, 248.0),
            vector4(227.15, -796.40, 30.58, 248.0),
            vector4(215.40, -804.50, 30.73, 70.0),
        },
    },
    {
        name = 'legion',
        label = 'Garage Legion Square',
        type = 'public',
        blip = { enabled = true, sprite = 357, colour = 3, scale = 0.75 },
        drawDistance = 40.0,
        interactDistance = 1.8,
        menu = vector3(100.16, -1073.31, 29.37),
        parks = {
            vector4(104.35, -1078.35, 29.19, 340.0),
            vector4(108.12, -1079.05, 29.19, 340.0),
            vector4(111.80, -1079.70, 29.19, 340.0),
            vector4(117.70, -1081.90, 29.19, 0.0),
        },
    },
    {
        name = 'motel',
        label = 'Garage Motel',
        type = 'public',
        blip = { enabled = true, sprite = 357, colour = 3, scale = 0.7 },
        drawDistance = 35.0,
        interactDistance = 1.8,
        menu = vector3(273.43, -343.99, 44.92),
        parks = {
            vector4(270.94, -340.71, 44.58, 342.0),
            vector4(266.82, -332.28, 44.58, 250.0),
            vector4(270.20, -329.80, 44.58, 250.0),
        },
    },
    {
        name = 'sapcounsel',
        label = 'Garage Sap Counsel',
        type = 'public',
        blip = { enabled = true, sprite = 357, colour = 3, scale = 0.7 },
        drawDistance = 35.0,
        interactDistance = 1.8,
        menu = vector3(-330.01, -780.77, 33.96),
        parks = {
            vector4(-334.36, -780.57, 33.96, 135.0),
            vector4(-337.80, -774.90, 33.96, 135.0),
            vector4(-341.20, -769.40, 33.96, 135.0),
        },
    },
    {
        name = 'impound',
        label = 'Fourrière',
        type = 'impound',
        impoundPrice = 500,
        blip = { enabled = true, sprite = 68, colour = 1, scale = 0.75 },
        drawDistance = 40.0,
        interactDistance = 1.8,
        menu = vector3(409.09, -1622.91, 29.29),
        parks = {
            vector4(401.13, -1631.76, 29.29, 320.0),
            vector4(404.52, -1635.98, 29.29, 320.0),
            vector4(407.90, -1640.10, 29.29, 320.0),
        },
    },
}
