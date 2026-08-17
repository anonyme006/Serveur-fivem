Config = Config or {}

Config.Debug = false
Config.Locale = 'en'

--- 'ox_target' | 'textui'
Config.Interaction = 'ox_target'

--- 'ps-dispatch' | 'cd_dispatch' | 'qs-dispatch' | 'rcore_dispatch' | 'custom' | 'none'
Config.Dispatch = 'none'

Config.TargetDistance = 2.0
Config.TextUIDistance = 1.8

Config.Admin = {
    command = 'druglabcreator',
    manageCommand = 'druglabs',
    --- ACE permission or Qbox permission group
    permission = 'admin',
    ace = 'qbx_druglabs.admin',
}

Config.Labs = {
    maxOwnedPerPlayer = 2,
    maxMembersPerLab = 8,
    bucketBase = 70000,
    entryFadeMs = 500,
}

Config.Purchase = {
    moneyType = 'bank',
    allowCash = true,
}

Config.Rental = {
    enabled = true,
    duration = 7 * 24 * 60 * 60,
    gracePeriod = 24 * 60 * 60,
    autoRenewDefault = false,
}

Config.Sell = {
    sellPercentage = 0.65,
    allowTransfer = true,
    allowServerSell = true,
}

Config.Security = {
    codeMinLength = 4,
    codeMaxLength = 8,
    maxCodeAttempts = 5,
    codeCooldownSeconds = 120,
    defaultLocked = true,
}

Config.Police = {
    jobs = {
        police = true,
        sheriff = true,
    },
    minimumPolice = 0,
    minimumGradeToSeal = 2,
    minimumGradeToRaid = 1,
    raidRequiresNearby = false,
}

Config.Production = {
    removeItemsOnStart = true,
    allowCancel = true,
    maxActivePerPlayer = 1,
    stationLockSeconds = 120,
}

Config.Meth = {
    requireMaskForSteps = {
        mix = true,
        furnace = true,
        chemical_mixer = true,
    },
    maskItem = 'respirator_mask',
    noMaskDamageInterval = 5000,
    noMaskDamageAmount = 2,
    furnaceTargetMin = 75,
    furnaceTargetMax = 85,
    furnaceOverheat = 95,
    furnaceUnderheat = 60,
    explosionChanceOnOverheat = 15,
    dispatchChanceOnFail = 65,
}

Config.Weed = {
    growthDurationSeconds = 3600,
    waterDecayPerHour = 12,
    nutrientDecayPerHour = 8,
    healthDecayIfDry = 15,
    harvestMinGrowth = 100,
    waterItem = 'plant_water',
    nutrientItem = 'plant_nutrient',
    sprayItem = 'plant_spray',
    seedItem = 'weed_seed',
}

Config.Quality = {
    min = 1,
    max = 100,
    default = 50,
}

Config.RateLimit = {
    entry = { max = 5, window = 10 },
    purchase = { max = 2, window = 15 },
    production = { max = 8, window = 10 },
    codeAttempt = { max = 6, window = 30 },
    admin = { max = 20, window = 10 },
}

Config.Logs = {
    enabled = true,
    console = true,
    database = true,
    discordWebhook = '',
}

Config.Blip = {
    default = {
        enabled = false,
        sprite = 499,
        color = 1,
        scale = 0.7,
        shortRange = true,
    },
}
