Config = {}

Config.CuffItem = nil -- si tu veux exiger des menottes: 'handcuffs'
Config.MaxCuffDistance = 3.0
Config.Jail = {
    coords = vec4(1641.6, 2570.5, 45.5, 0.0),
    release = vec4(1848.0, 2586.0, 45.7, 270.0),
}

Config.Actions = {
    cuff = true,
    escort = true,
    search = true,
    fine = true,
    jail = true,
}
