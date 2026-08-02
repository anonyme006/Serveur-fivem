Config = {}

Config.Garages = {
    {
        id = 'legion',
        label = 'Garage Legion',
        coords = vec3(215.8, -810.1, 30.7),
        spawn = vec4(229.7, -800.1, 30.6, 160.0),
        ped = `s_m_m_autoshop_02`,
    },
    {
        id = 'sandy',
        label = 'Garage Sandy',
        coords = vec3(1737.6, 3710.2, 34.1),
        spawn = vec4(1725.2, 3715.8, 34.2, 20.0),
        ped = `s_m_m_autoshop_02`,
    },
}

-- En production, brancher sur player_vehicles (Qbox)
Config.UsePlayerVehiclesTable = true
