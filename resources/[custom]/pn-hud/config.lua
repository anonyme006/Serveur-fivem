Config = {}

Config.Enabled = true

Config.Position = {
    x = 50,
    y = 88,
}

Config.Refresh = {
    onFoot = 1200,
    inVehicle = 120,
    location = 1500,
}

Config.General = {
    showVoice = true,
    hideWhenPaused = true,
}

Config.Speed = {
    enabled = true,
    unit = 'KMH', -- 'KMH' | 'MPH'
    padDigits = 3,
}

Config.RPM = {
    enabled = true,
    max = 1.0,
}

Config.Fuel = {
    enabled = true,
    system = 'auto', -- 'auto' | 'ox_fuel' | 'LegacyFuel' | 'mnr_fuel' | 'native'
    lowWarning = 20,
    criticalWarning = 10,
    showDecimals = false,
}

Config.Engine = {
    enabled = true,
    warning = 40,
    critical = 20,
    states = {
        normal = { min = 70, max = 100 },
        damaged = { min = 40, max = 69 },
        critical = { min = 15, max = 39 },
        destroyed = { min = 0, max = 14 },
    },
}

Config.Seatbelt = {
    enabled = true,
    key = 'B',
    useExternal = true, -- qbx_seatbelt si présent
}

Config.Indicators = {
    enabled = true,
}

Config.Lights = {
    enabled = true,
}

Config.Brake = {
    enabled = true,
}

Config.Doors = {
    enabled = true,
    labels = {
        [0] = 'driver',
        [1] = 'passenger',
        [2] = 'rear_left',
        [3] = 'rear_right',
        [4] = 'hood',
        [5] = 'trunk',
    },
}

Config.Location = {
    enabled = false,
    showStreet = true,
    showZone = true,
    showDirection = true,
}

Config.Animations = {
    enabled = true,
}

Config.Gear = {
    enabled = true,
    usePark = true,
    parkSpeed = 0.8,
}

Config.VehicleTypes = {
    car = {
        speed = true,
        rpm = true,
        gear = true,
        fuel = true,
        engine = true,
        seatbelt = true,
        indicators = true,
        lights = true,
        brake = true,
        doors = true,
    },
    bike = {
        speed = true,
        rpm = true,
        gear = true,
        fuel = true,
        engine = true,
        seatbelt = false,
        indicators = true,
        lights = true,
        brake = true,
        doors = false,
    },
    boat = {
        speed = true,
        rpm = true,
        gear = false,
        fuel = true,
        engine = true,
        seatbelt = false,
        indicators = false,
        lights = true,
        brake = false,
        doors = false,
    },
    helicopter = {
        speed = true,
        rpm = true,
        gear = false,
        fuel = true,
        engine = true,
        seatbelt = false,
        indicators = false,
        lights = true,
        brake = false,
        doors = false,
    },
    aircraft = {
        speed = true,
        rpm = true,
        gear = false,
        fuel = true,
        engine = true,
        seatbelt = false,
        indicators = false,
        lights = true,
        brake = false,
        doors = false,
    },
    bicycle = {
        speed = true,
        rpm = false,
        gear = false,
        fuel = false,
        engine = false,
        seatbelt = false,
        indicators = false,
        lights = false,
        brake = false,
        doors = false,
    },
    train = {
        speed = true,
        rpm = true,
        gear = false,
        fuel = false,
        engine = true,
        seatbelt = false,
        indicators = false,
        lights = true,
        brake = true,
        doors = true,
    },
}

--- Mapping GetVehicleClass -> type key
Config.VehicleClassMap = {
    [8] = 'bike',
    [13] = 'bicycle',
    [14] = 'boat',
    [15] = 'helicopter',
    [16] = 'aircraft',
    [21] = 'train',
}
