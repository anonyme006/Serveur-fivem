--[[--------------------------------------------------------------------------
    Objets police placables + herses (PHASE 9)
---------------------------------------------------------------------------]]

Config.Objects = {
    maxPerOfficer = 15,
    placeDistance = 3.0,
    pickupDistance = 2.5,

    list = {
        barricade = {
            label = 'Barricade',
            model = `prop_barrier_work05`,
            permission = 'objects_basic',
            freeze = true,
        },
        cone = {
            label = 'Cone',
            model = `prop_roadcone02a`,
            permission = 'objects_basic',
            freeze = true,
        },
        barrier = {
            label = 'Barrière',
            model = `prop_mp_barrier_02b`,
            permission = 'objects',
            freeze = true,
        },
        sign = {
            label = 'Signalisation',
            model = `prop_consign_01a`,
            permission = 'objects_basic',
            freeze = true,
        },
        spike = {
            label = 'Spike Strip',
            model = `p_ld_stinger_s`,
            permission = 'spike',
            freeze = true,
            item = 'spike_strip',
        },
    },

    spike = {
        item = 'spike_strip',
        punctureAllTyres = true,
        deleteOnUse = false,
        detectRadius = 3.5,
    },
}
