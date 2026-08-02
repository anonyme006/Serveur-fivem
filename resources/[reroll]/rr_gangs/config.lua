Config = {}

Config.Gangs = {
    ballas = { label = 'Ballas', color = 27 },
    families = { label = 'Families', color = 2 },
    vagos = { label = 'Vagos', color = 5 },
}

Config.Territories = {
    { id = 'grove', label = 'Grove Street', coords = vec3(105.0, -1940.0, 20.8), radius = 80.0, owner = 'families' },
    { id = 'forum', label = 'Forum Drive', coords = vec3(-10.0, -1440.0, 30.5), radius = 70.0, owner = 'ballas' },
    { id = 'jamestown', label = 'Jamestown', coords = vec3(330.0, -2040.0, 21.0), radius = 70.0, owner = 'vagos' },
}

Config.CaptureSeconds = 60
