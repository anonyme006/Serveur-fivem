--[[--------------------------------------------------------------------------
    Départements LEO — plusieurs services configurables
---------------------------------------------------------------------------]]

Config.Departments = {
    police = {
        label = 'Los Santos Police Department',
        shortLabel = 'LSPD',
        job = 'police',
        jobType = 'leo',
        color = { r = 47, g = 102, b = 186 },
        blipColor = 29,
        radioFrequency = 1,
        emergencyNumber = '911',
        enabled = true,
        --- Grades (doivent exister dans qbx_core shared/jobs.lua)
        grades = {
            [0] = { name = 'Recruit', label = 'Recrue', permissions = { 'duty', 'cuff', 'escort', 'search', 'objects_basic', 'licenses' } },
            [1] = { name = 'Officer', label = 'Officer', permissions = { 'duty', 'cuff', 'escort', 'search', 'vehicle', 'objects_basic', 'fines', 'gsr', 'impound', 'licenses' } },
            [2] = { name = 'Senior Officer', label = 'Senior Officer', permissions = { 'duty', 'cuff', 'escort', 'search', 'vehicle', 'objects', 'fines', 'prison', 'gsr', 'impound', 'armory', 'spike', 'licenses' } },
            [3] = { name = 'Sergeant', label = 'Sergeant', permissions = { 'duty', 'cuff', 'escort', 'search', 'vehicle', 'objects', 'fines', 'prison', 'community', 'gsr', 'impound', 'armory', 'spike', 'code1080', 'confiscate', 'stash_evidence', 'licenses' } },
            [4] = { name = 'Lieutenant', label = 'Lieutenant', permissions = { '*' } },
            [5] = { name = 'Captain', label = 'Captain', permissions = { '*' } },
            [6] = { name = 'Chief', label = 'Chief', permissions = { '*' } },
        },
        locations = {
            duty = {
                vec3(441.79, -982.07, 30.69),
            },
            armory = {
                vec3(482.54, -995.52, 30.69),
            },
            garage = {
                {
                    menu = vec3(452.34, -1017.29, 28.48),
                    spawn = vec4(449.23, -1025.24, 28.55, 5.0),
                },
            },
            stash = {
                main = vec3(461.58, -981.11, 30.69),
                evidence = vec3(474.91, -994.24, 26.27),
                personal = vec3(461.58, -981.11, 30.69),
            },
            locker = {
                vec3(461.58, -981.11, 30.69),
            },
            mechanic = {
                vec3(451.63, -975.71, 25.70),
            },
            weaponRepair = {
                vec3(487.15, -996.98, 30.69),
            },
            bell = {
                vec3(441.19, -979.45, 30.69),
            },
            boss = {
                vec3(448.21, -973.12, 30.69),
            },
        },
        prison = 'bolingbroke',
        stashes = {
            main = { id = 'police_main', label = 'Police Main Stash', slots = 100, weight = 500000 },
            evidence = { id = 'police_evidence', label = 'Evidence Stash', slots = 150, weight = 750000 },
            incident = { id = 'police_incident', label = 'Incident Stash', slots = 80, weight = 400000 },
            money = { id = 'police_money', label = 'Money Stash', slots = 50, weight = 200000 },
            trash = { id = 'police_trash', label = 'Trash', slots = 50, weight = 200000 },
            personalPrefix = 'police_personal_',
        },
    },

    sheriff = {
        label = 'Blaine County Sheriff Office',
        shortLabel = 'BCSO',
        job = 'sheriff',
        jobType = 'leo',
        color = { r = 163, g = 123, b = 54 },
        blipColor = 25,
        radioFrequency = 2,
        emergencyNumber = '999',
        enabled = true,
        grades = {
            [0] = { name = 'Deputy', label = 'Deputy', permissions = { 'duty', 'cuff', 'escort', 'search', 'vehicle', 'objects_basic', 'fines', 'gsr', 'licenses' } },
            [1] = { name = 'Senior Deputy', label = 'Senior Deputy', permissions = { 'duty', 'cuff', 'escort', 'search', 'vehicle', 'objects', 'fines', 'prison', 'gsr', 'impound', 'armory', 'spike', 'licenses' } },
            [2] = { name = 'Sergeant', label = 'Sergeant', permissions = { 'duty', 'cuff', 'escort', 'search', 'vehicle', 'objects', 'fines', 'prison', 'community', 'gsr', 'impound', 'armory', 'spike', 'code1080', 'confiscate', 'stash_evidence', 'licenses' } },
            [3] = { name = 'Lieutenant', label = 'Lieutenant', permissions = { '*' } },
            [4] = { name = 'Sheriff', label = 'Sheriff', permissions = { '*' } },
        },
        locations = {
            duty = { vec3(1852.91, 3688.79, 34.27) },
            armory = { vec3(1862.11, 3688.25, 34.27) },
            garage = {
                {
                    menu = vec3(1865.24, 3695.12, 33.85),
                    spawn = vec4(1869.40, 3694.10, 33.60, 210.0),
                },
            },
            stash = {
                main = vec3(1856.50, 3689.40, 34.27),
                evidence = vec3(1855.20, 3699.10, 34.27),
                personal = vec3(1856.50, 3689.40, 34.27),
            },
            locker = { vec3(1856.50, 3689.40, 34.27) },
            mechanic = { vec3(1873.80, 3692.30, 33.60) },
            weaponRepair = { vec3(1862.11, 3688.25, 34.27) },
            bell = { vec3(1853.20, 3689.50, 34.27) },
            boss = { vec3(1858.90, 3691.20, 34.27) },
        },
        prison = 'bolingbroke',
        stashes = {
            main = { id = 'sheriff_main', label = 'Sheriff Main Stash', slots = 100, weight = 500000 },
            evidence = { id = 'sheriff_evidence', label = 'Evidence Stash', slots = 150, weight = 750000 },
            incident = { id = 'sheriff_incident', label = 'Incident Stash', slots = 80, weight = 400000 },
            money = { id = 'sheriff_money', label = 'Money Stash', slots = 50, weight = 200000 },
            trash = { id = 'sheriff_trash', label = 'Trash', slots = 50, weight = 200000 },
            personalPrefix = 'sheriff_personal_',
        },
    },

    statepolice = {
        label = 'San Andreas State Police',
        shortLabel = 'SASP',
        job = 'statepolice',
        jobType = 'leo',
        color = { r = 30, g = 80, b = 160 },
        blipColor = 38,
        radioFrequency = 3,
        emergencyNumber = '911',
        enabled = true,
        grades = {
            [0] = { name = 'Trooper', label = 'Trooper', permissions = { 'duty', 'cuff', 'escort', 'search', 'vehicle', 'objects_basic', 'fines', 'gsr', 'impound', 'licenses' } },
            [1] = { name = 'Senior Trooper', label = 'Senior Trooper', permissions = { 'duty', 'cuff', 'escort', 'search', 'vehicle', 'objects', 'fines', 'prison', 'gsr', 'impound', 'armory', 'spike', 'code1080', 'licenses' } },
            [2] = { name = 'Sergeant', label = 'Sergeant', permissions = { '*' } },
            [3] = { name = 'Lieutenant', label = 'Lieutenant', permissions = { '*' } },
            [4] = { name = 'Colonel', label = 'Colonel', permissions = { '*' } },
        },
        locations = {
            duty = { vec3(1538.60, 816.90, 77.65) },
            armory = { vec3(1549.20, 820.40, 77.65) },
            garage = {
                {
                    menu = vec3(1535.10, 790.50, 77.15),
                    spawn = vec4(1530.20, 785.40, 77.10, 30.0),
                },
            },
            stash = {
                main = vec3(1545.00, 818.00, 77.65),
                evidence = vec3(1550.00, 825.00, 77.65),
                personal = vec3(1545.00, 818.00, 77.65),
            },
            locker = { vec3(1545.00, 818.00, 77.65) },
            mechanic = { vec3(1526.00, 780.00, 77.10) },
            weaponRepair = { vec3(1549.20, 820.40, 77.65) },
            bell = { vec3(1539.50, 817.80, 77.65) },
            boss = { vec3(1542.00, 822.00, 77.65) },
        },
        prison = 'bolingbroke',
        stashes = {
            main = { id = 'statepolice_main', label = 'SASP Main Stash', slots = 100, weight = 500000 },
            evidence = { id = 'statepolice_evidence', label = 'Evidence Stash', slots = 150, weight = 750000 },
            incident = { id = 'statepolice_incident', label = 'Incident Stash', slots = 80, weight = 400000 },
            money = { id = 'statepolice_money', label = 'Money Stash', slots = 50, weight = 200000 },
            trash = { id = 'statepolice_trash', label = 'Trash', slots = 50, weight = 200000 },
            personalPrefix = 'statepolice_personal_',
        },
    },

    fib = {
        label = 'Federal Investigation Bureau',
        shortLabel = 'FIB',
        job = 'fib',
        jobType = 'leo',
        color = { r = 20, g = 20, b = 20 },
        blipColor = 40,
        radioFrequency = 4,
        emergencyNumber = '911',
        enabled = false, -- activer si le job fib existe côté qbx_core
        grades = {
            [0] = { name = 'Agent', label = 'Agent', permissions = { 'duty', 'cuff', 'escort', 'search', 'vehicle', 'fines', 'gsr', 'confiscate', 'licenses' } },
            [1] = { name = 'Special Agent', label = 'Special Agent', permissions = { '*' } },
            [2] = { name = 'Supervisor', label = 'Supervisor', permissions = { '*' } },
            [3] = { name = 'Director', label = 'Director', permissions = { '*' } },
        },
        locations = {
            duty = { vec3(136.10, -761.70, 45.75) },
            armory = { vec3(118.80, -729.40, 242.15) },
            garage = {
                {
                    menu = vec3(141.20, -742.50, 33.13),
                    spawn = vec4(145.40, -740.80, 33.00, 160.0),
                },
            },
            stash = {
                main = vec3(148.50, -758.20, 242.15),
                evidence = vec3(150.20, -762.10, 242.15),
                personal = vec3(148.50, -758.20, 242.15),
            },
            locker = { vec3(148.50, -758.20, 242.15) },
            mechanic = { vec3(140.00, -735.00, 33.13) },
            weaponRepair = { vec3(118.80, -729.40, 242.15) },
            bell = { vec3(136.80, -762.50, 45.75) },
            boss = { vec3(124.80, -748.90, 242.15) },
        },
        prison = 'bolingbroke',
        stashes = {
            main = { id = 'fib_main', label = 'FIB Main Stash', slots = 100, weight = 500000 },
            evidence = { id = 'fib_evidence', label = 'Evidence Stash', slots = 150, weight = 750000 },
            incident = { id = 'fib_incident', label = 'Incident Stash', slots = 80, weight = 400000 },
            money = { id = 'fib_money', label = 'Money Stash', slots = 50, weight = 200000 },
            trash = { id = 'fib_trash', label = 'Trash', slots = 50, weight = 200000 },
            personalPrefix = 'fib_personal_',
        },
    },
}
