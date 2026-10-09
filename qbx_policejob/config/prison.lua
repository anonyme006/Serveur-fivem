--[[--------------------------------------------------------------------------
    Prison + boutique + community service (PHASE 7)
---------------------------------------------------------------------------]]

Config.Prison = {
    enabled = true,
    id = 'bolingbroke',
    label = 'Bolingbroke Penitentiary',

    intake = vec4(1845.50, 2585.90, 45.67, 270.0),
    release = vec4(1848.20, 2586.10, 45.67, 270.0),
    center = vec3(1691.50, 2565.80, 45.56),
    radius = 180.0,

    --- Anti-évasion : téléport si hors zone
    antiEscape = true,
    escapeCheckInterval = 10000, -- ms

    items = {
        removeWeapons = true,
        stashPhone = true,
        keepFood = true,
        temporaryStashPrefix = 'prison_personal_',
    },

    --- Uniforme prisonnier (composants basiques)
    outfit = {
        male = {
            components = {
                { component = 11, drawable = 5, texture = 0 },
                { component = 4, drawable = 7, texture = 15 },
                { component = 6, drawable = 5, texture = 0 },
                { component = 3, drawable = 5, texture = 0 },
            },
        },
        female = {
            components = {
                { component = 11, drawable = 5, texture = 0 },
                { component = 4, drawable = 3, texture = 15 },
                { component = 6, drawable = 5, texture = 0 },
            },
        },
    },

    shop = {
        enabled = true,
        coords = vec3(1781.10, 2559.20, 45.67),
        items = {
            { item = 'water', label = 'Eau', price = 5 },
            { item = 'sandwich', label = 'Sandwich', price = 10 },
            { item = 'coffee', label = 'Café', price = 5 },
        },
        account = 'cash',
    },

    --- Durées (minutes) proposées dans le menu sanctions
    durationPresets = { 5, 10, 15, 30, 45, 60, 90, 120 },
    maxDuration = 240,
}

Config.CommunityService = {
    enabled = true,
    center = vec3(170.20, -990.50, 30.09),
    radius = 50.0,
    warningDistance = 55.0,
    penaltyTasks = 2, -- tâches ajoutées si sortie de zone
    progressDuration = 5000,

    tasks = {
        {
            coords = vec3(165.40, -985.20, 30.09),
            label = 'Ramasser les déchets',
            anim = { dict = 'anim@amb@drug_field_workers@rake@male_a@base', clip = 'base' },
        },
        {
            coords = vec3(175.10, -995.80, 30.09),
            label = 'Nettoyer le sol',
            anim = { dict = 'amb@world_human_janitor@male@idle_a', clip = 'idle_a' },
        },
        {
            coords = vec3(180.50, -988.40, 30.09),
            label = 'Balayer',
            anim = { dict = 'anim@amb@drug_field_workers@rake@male_a@base', clip = 'base' },
        },
    },

    presets = { 10, 25, 50, 75, 100 },
    maxTasks = 150,
}

--- Alias demandé dans le brief
Config.PrisonItems = Config.Prison.items
