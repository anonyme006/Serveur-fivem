fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'vibe_api'
author 'local-scaffold'
description 'Pont API commun pour les ressources vibe_* (stub)'
version '0.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core',
}
