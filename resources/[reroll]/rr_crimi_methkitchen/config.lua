Config = {}
Config.Cook = {
    label = 'Cuire la meth',
    coords = vec3(1391.9, 3606.1, 38.9),
    duration = 15000,
    need = { { item = 'acetone', count = 1 }, { item = 'pseudoephedrine', count = 1 } },
    reward = { item = 'meth_bag', count = 1 },
}
Config.Sell = {
    coords = vec3(8.1, -243.0, 47.7),
    item = 'meth_bag',
    price = 220,
    alertChance = 35,
}
