Config = {}

Config.Debug = false

--- Entreprises enregistrées (jobName = clé)
--- Les jobs Qbox police/ambulance/mechanic/taxi existent déjà ; on étend via grades/permissions.
Config.Businesses = {
    police = {
        label = 'LSPD',
        account = 'police',
        stash = { id = 'police_stash', slots = 100, weight = 500000 },
        bossGrade = 3,
        announce = true,
    },
    ambulance = {
        label = 'EMS',
        account = 'ambulance',
        stash = { id = 'ambulance_stash', slots = 80, weight = 400000 },
        bossGrade = 3,
        announce = true,
    },
    mechanic = {
        label = 'Mécano',
        account = 'mechanic',
        stash = { id = 'mechanic_stash', slots = 80, weight = 600000 },
        bossGrade = 3,
        announce = true,
    },
    taxi = {
        label = 'Taxi',
        account = 'taxi',
        stash = { id = 'taxi_stash', slots = 40, weight = 100000 },
        bossGrade = 2,
        announce = true,
    },
    burgershot = {
        label = 'Burger Shot',
        account = 'burgershot',
        stash = { id = 'burgershot_stash', slots = 60, weight = 200000 },
        bossGrade = 3,
        announce = true,
    },
    uwu = {
        label = 'UwU Café',
        account = 'uwu',
        stash = { id = 'uwu_stash', slots = 60, weight = 200000 },
        bossGrade = 3,
        announce = true,
    },
    government = {
        label = 'Gouvernement',
        account = 'government',
        stash = { id = 'government_stash', slots = 50, weight = 150000 },
        bossGrade = 2,
        announce = true,
    },
    doj = {
        label = 'DOJ',
        account = 'doj',
        stash = { id = 'doj_stash', slots = 40, weight = 100000 },
        bossGrade = 2,
        announce = true,
    },
}

Config.Permissions = {
    recruit = 'boss',
    fire = 'boss',
    promote = 'boss',
    announce = 'boss',
    withdraw = 'boss',
    deposit = true, -- tous les employés on duty
    stash = true,
}
