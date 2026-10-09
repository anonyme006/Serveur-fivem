--[[
    Optional ox_inventory item definitions.
    Merge these into ox_inventory/data/items.lua (or your items pack).
]]

return {
    ['driver_license'] = {
        label = 'Class C Driver License',
        weight = 10,
        stack = false,
        close = true,
        description = 'California Class C driver license',
        client = {
            export = 'sky_drivingschool.useLicenseItem',
        },
    },
    ['motorcycle_license'] = {
        label = 'Class M Motorcycle License',
        weight = 10,
        stack = false,
        close = true,
        description = 'California Class M motorcycle endorsement',
    },
    ['truck_license'] = {
        label = 'Class A Heavy Vehicle License',
        weight = 10,
        stack = false,
        close = true,
        description = 'California Class A license',
    },
    ['cdl_license'] = {
        label = 'Commercial Driver License',
        weight = 10,
        stack = false,
        close = true,
        description = 'California CDL',
    },
    ['boat_license'] = {
        label = 'Boat License',
        weight = 10,
        stack = false,
        close = true,
        description = 'California vessel operator license',
    },
    ['aircraft_license'] = {
        label = 'Pilot License',
        weight = 10,
        stack = false,
        close = true,
        description = 'Aircraft / helicopter certificate',
    },
}
