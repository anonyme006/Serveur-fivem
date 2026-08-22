--[[
    À fusionner dans ox_inventory/data/items.lua

    ['vehicle_key'] = {
        label = 'Clé de véhicule',
        weight = 20,
        stack = false,
        close = true,
        description = 'Clé permettant de verrouiller / déverrouiller un véhicule',
        client = {
            export = 'qbx_rp_core.useVehicleKey',
        },
    },
]]

-- Fichier de référence — copie le bloc ci-dessus dans ox_inventory/data/items.lua
return {
    vehicle_key = {
        label = 'Clé de véhicule',
        weight = 20,
        stack = false,
        close = true,
        description = 'Clé permettant de verrouiller / déverrouiller un véhicule',
        client = {
            export = 'qbx_rp_core.useVehicleKey',
        },
    },
}
