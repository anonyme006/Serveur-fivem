Config = {}

Config.PickZones = {
    {
        label = 'Récolter du cannabis',
        coords = vec3(2224.3, 5577.1, 53.8),
        radius = 25.0,
        item = 'weed_leaf',
        amount = 1,
        duration = 5000,
    },
}

Config.Process = {
    label = 'Sécher / conditionner',
    coords = vec3(2329.1, 2571.5, 46.7),
    radius = 2.0,
    fromItem = 'weed_leaf',
    fromAmount = 3,
    toItem = 'weed_bag',
    toAmount = 1,
    duration = 8000,
}
