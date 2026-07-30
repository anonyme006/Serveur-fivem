fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'esx_consumables'
author 'Serveur-fivem'
description 'Nourriture & boissons ESX — barre esx_progressbar à la consommation'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

dependencies {
    'es_extended',
    'esx_progressbar',
}

--- Optionnel : esx_status (faim / soif)
--- Soft-dep ox_inventory via export client
