--[[
    Item antenne — à fusionner dans ox_inventory/data/items.lua

    ['phone_antenna'] = {
        label = 'Antenne réseau',
        weight = 2500,
        stack = true,
        close = true,
        description = 'Déploie une antenne pour capter le réseau téléphone (appels, SMS, réseaux)',
        client = {
            export = 'qbx_ressources.usePhoneAntenna',
        },
    },
]]

return {
    phone_antenna = {
        label = 'Antenne réseau',
        weight = 2500,
        stack = true,
        close = true,
        description = 'Déploie une antenne pour capter le réseau téléphone (appels, SMS, réseaux)',
        client = {
            export = 'qbx_ressources.usePhoneAntenna',
        },
    },
}
