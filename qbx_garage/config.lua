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
Config.StoreDistance = 8.0
Config.SpawnCheckRadius = 3.0

-- Paiement fourrière
Config.ImpoundAccount = 'bank' -- cash | bank

--[[
    type = 'public' | 'job' | 'gang' | 'impound'
    job / gang / minGrade = restrictions optionnelles
    spawns = points de sortie possibles
    store = point de rangement (sinon menu.coords)
]]
Config.Garages = {
    {
        name = 'pillbox',
        label = 'Garage Pillbox',
        type = 'public',
        blip = { enabled = true, sprite = 357, colour = 3, scale = 0.75 },
        marker = {
            type = 36,
            size = vector3(0.6, 0.6, 0.6),
            color = { r = 59, g = 130, b = 246, a = 180 },
        },
        menu = vector3(215.95, -810.12, 30.73),
        store = vector3(215.95, -810.12, 30.73),
        drawDistance = 30.0,
        interactDistance = 2.5,
        spawns = {
            vector4(222.58, -804.23, 30.58, 248.0),
            vector4(223.98, -801.68, 30.58, 248.0),
            vector4(225.55, -799.12, 30.58, 248.0),
        },
    },
    {
        name = 'legion',
        label = 'Garage Legion Square',
        type = 'public',
        blip = { enabled = true, sprite = 357, colour = 3, scale = 0.75 },
        marker = {
            type = 36,
            size = vector3(0.6, 0.6, 0.6),
            color = { r = 59, g = 130, b = 246, a = 180 },
        },
        menu = vector3(100.16, -1073.31, 29.37),
        store = vector3(100.16, -1073.31, 29.37),
        drawDistance = 30.0,
        interactDistance = 2.5,
        spawns = {
            vector4(104.35, -1078.35, 29.19, 340.0),
            vector4(108.12, -1079.05, 29.19, 340.0),
        },
    },
    {
        name = 'motel',
        label = 'Garage Motel',
        type = 'public',
        blip = { enabled = true, sprite = 357, colour = 3, scale = 0.7 },
        marker = {
            type = 36,
            size = vector3(0.6, 0.6, 0.6),
            color = { r = 59, g = 130, b = 246, a = 180 },
        },
        menu = vector3(273.43, -343.99, 44.92),
        store = vector3(273.43, -343.99, 44.92),
        drawDistance = 30.0,
        interactDistance = 2.5,
        spawns = {
            vector4(270.94, -340.71, 44.58, 342.0),
            vector4(266.82, -332.28, 44.58, 250.0),
        },
    },
    {
        name = 'sapcounsel',
        label = 'Garage Sap Counsel',
        type = 'public',
        blip = { enabled = true, sprite = 357, colour = 3, scale = 0.7 },
        marker = {
            type = 36,
            size = vector3(0.6, 0.6, 0.6),
            color = { r = 59, g = 130, b = 246, a = 180 },
        },
        menu = vector3(-330.01, -780.77, 33.96),
        store = vector3(-330.01, -780.77, 33.96),
        drawDistance = 30.0,
        interactDistance = 2.5,
        spawns = {
            vector4(-334.36, -780.57, 33.96, 135.0),
        },
    },
    {
        name = 'impound',
        label = 'Fourrière',
        type = 'impound',
        impoundPrice = 500,
        blip = { enabled = true, sprite = 68, colour = 1, scale = 0.75 },
        marker = {
            type = 36,
            size = vector3(0.6, 0.6, 0.6),
            color = { r = 239, g = 68, b = 68, a = 180 },
        },
        menu = vector3(409.09, -1622.91, 29.29),
        store = vector3(409.09, -1622.91, 29.29),
        drawDistance = 35.0,
        interactDistance = 2.5,
        spawns = {
            vector4(401.13, -1631.76, 29.29, 320.0),
            vector4(404.52, -1635.98, 29.29, 320.0),
        },
    },
}
