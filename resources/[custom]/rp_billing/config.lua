Config = {}

Config.MaxAmount = 250000
Config.DefaultExpireHours = 72
Config.AllowCash = false -- paiement via banque uniquement
Config.MinDistance = 10.0

--- Jobs autorisés à facturer (+ grade min). true = tous grades
Config.AllowedJobs = {
    police = 0,
    ambulance = 0,
    mechanic = 0,
    taxi = 0,
    burgershot = 0,
    uwu = 0,
    government = 0,
    doj = 0,
}
