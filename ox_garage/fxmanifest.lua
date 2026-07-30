fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'ox_garage'
author 'Serveur-fivem'
description 'Garage ESX (ox_lib) — rangement / sortie avec esx_progressbar'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

dependencies {
    'es_extended',
    'oxmysql',
    'ox_lib',
    'esx_progressbar',
}
