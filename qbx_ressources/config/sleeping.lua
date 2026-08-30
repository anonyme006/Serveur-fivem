--[[ Corps endormis (ex qbx_sleeping_bodies) ]]
Config.Sleeping = {
    Debug = false,
    UseOxTarget = true,
    ShowName = true,
    NameDistance = 10.0,
    ZOffset = 0.0,
    RotationOffset = 0.0,
    DeleteOnReconnect = true,
    LoadBodiesOnResourceStart = true,
    SleepAnimation = {
        dict = 'timetable@tracy@sleep@',
        anim = 'idle_c',
        flag = 1,
    },
    SleepAnimationFallback = {
        dict = 'amb@world_human_bum_slumped@male@laying_on_right_side@base',
        anim = 'base',
        flag = 1,
    },
    AppearanceSystem = 'auto',
    AdminGroups = { 'admin', 'god' },
    AdminAce = 'qbx_ressources.sleeping.admin',
    ClientCacheInterval = 15000,
    MaxDropDistanceDelta = 80.0,
    UseScenario = false,
    Scenario = 'WORLD_HUMAN_BUM_SLUMPED',
    NameColor = { r = 180, g = 210, b = 255, a = 220 },
}
