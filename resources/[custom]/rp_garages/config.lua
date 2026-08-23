Config = {}
Config.Debug = false
Config.ImpoundFee = 500
Config.StoreDistance = 8.0

Config.Garages = {
    {
        id = 'legion',
        label = 'Garage Légion',
        type = 'public',
        coords = vec3(215.95, -810.11, 30.73),
        spawn = vec4(222.25, -804.19, 30.58, 248.0),
        blip = { sprite = 357, color = 3 },
    },
    {
        id = 'police',
        label = 'Garage Police',
        type = 'job',
        job = 'police',
        coords = vec3(452.2, -1017.0, 28.5),
        spawn = vec4(450.0, -1024.0, 28.5, 90.0),
        blip = { sprite = 357, color = 29 },
    },
    {
        id = 'ambulance',
        label = 'Garage EMS',
        type = 'job',
        job = 'ambulance',
        coords = vec3(295.0, -605.0, 43.3),
        spawn = vec4(292.0, -612.0, 43.3, 70.0),
        blip = { sprite = 357, color = 1 },
    },
    {
        id = 'mechanic',
        label = 'Garage Mécano',
        type = 'job',
        job = 'mechanic',
        coords = vec3(-354.0, -128.0, 39.0),
        spawn = vec4(-365.0, -123.0, 38.7, 70.0),
        blip = { sprite = 357, color = 5 },
    },
    {
        id = 'impound',
        label = 'Fourrière',
        type = 'impound',
        coords = vec3(409.0, -1623.0, 29.3),
        spawn = vec4(401.0, -1631.0, 29.3, 230.0),
        blip = { sprite = 68, color = 1 },
    },
}
