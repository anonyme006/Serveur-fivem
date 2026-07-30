Config = {}

--- Durée de la barre de progression (ms)
Config.Progress = {
    store = 3500,
    retrieve = 3000,
}

Config.StoreLabel = 'Rangement du véhicule…'
Config.RetrieveLabel = 'Sortie du véhicule…'

--- Distance max pour ranger le véhicule actuel
Config.StoreDistance = 8.0

--- Marker (fallback si pas d'ox_target)
Config.DrawDistance = 25.0
Config.InteractDistance = 2.5
Config.Marker = {
    type = 36,
    size = vector3(1.0, 1.0, 1.0),
    color = { r = 245, g = 166, b = 35, a = 160 },
    bob = false,
    faceCamera = true,
}

--- Utiliser ox_target si démarré
Config.UseOxTarget = true

Config.Garages = {
    {
        id = 'legion',
        label = 'Garage Legion Square',
        type = 'car', -- car | boat | air
        blip = { sprite = 357, color = 47, scale = 0.75 },
        coords = vector3(215.69, -809.72, 30.73),
        spawn = vector4(229.34, -800.12, 30.57, 159.0),
        store = vector3(215.69, -809.72, 30.73),
    },
    {
        id = 'pillbox',
        label = 'Garage Pillbox',
        type = 'car',
        blip = { sprite = 357, color = 47, scale = 0.75 },
        coords = vector3(273.0, -343.85, 44.91),
        spawn = vector4(270.75, -340.51, 44.92, 342.0),
        store = vector3(273.0, -343.85, 44.91),
    },
    {
        id = 'motel',
        label = 'Garage Pink Cage',
        type = 'car',
        blip = { sprite = 357, color = 47, scale = 0.75 },
        coords = vector3(327.59, -205.05, 54.09),
        spawn = vector4(327.59, -205.05, 54.09, 161.0),
        store = vector3(327.59, -205.05, 54.09),
    },
}

Config.Impound = {
    id = 'impound_city',
    label = 'Fourrière Centre',
    blip = { sprite = 67, color = 1, scale = 0.75 },
    coords = vector3(409.0, -1623.0, 29.29),
    spawn = vector4(401.5, -1631.7, 29.29, 230.0),
    price = 500,
}

--- Classes GTA autorisées par garage.type
Config.VehicleClasses = {
    car = {
        [0] = true, [1] = true, [2] = true, [3] = true, [4] = true,
        [5] = true, [6] = true, [7] = true, [8] = true, [9] = true,
        [10] = true, [11] = true, [12] = true, [17] = true, [18] = true,
        [19] = true, [20] = true, [22] = true,
    },
    boat = { [14] = true },
    air = { [15] = true, [16] = true },
}
