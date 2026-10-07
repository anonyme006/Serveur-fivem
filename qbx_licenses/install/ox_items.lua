--[[
    Items ox_inventory — à fusionner dans ox_inventory/data/items.lua

    Chaque permis stocke les points dans metadata (synchronisés automatiquement
    quand la police retire des points).
]]

return {
    ['driver_license'] = {
        label = 'Permis voiture',
        weight = 10,
        stack = false,
        close = true,
        description = 'Permis de conduire — voiture',
        client = {
            export = 'qbx_licenses.useLicenseCard',
        },
    },
    ['motorcycle_license'] = {
        label = 'Permis moto',
        weight = 10,
        stack = false,
        close = true,
        description = 'Permis de conduire — moto',
        client = {
            export = 'qbx_licenses.useLicenseCard',
        },
    },
    ['boat_license'] = {
        label = 'Permis bateau',
        weight = 10,
        stack = false,
        close = true,
        description = 'Permis de navigation',
        client = {
            export = 'qbx_licenses.useLicenseCard',
        },
    },
    ['aircraft_license'] = {
        label = 'Permis avion',
        weight = 10,
        stack = false,
        close = true,
        description = 'Licence de pilote',
        client = {
            export = 'qbx_licenses.useLicenseCard',
        },
    },
}
