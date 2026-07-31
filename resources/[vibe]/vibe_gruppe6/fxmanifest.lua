fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'vibe_gruppe6'
description 'Convoi de fonds Gruppe 6 — magasins, banques, armureries, grossistes'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/points.lua',
    'server/main.lua',
    'server/commands.lua',
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'oxmysql',
    'qbx_core',
    'vibe_api',
    'Renewed-Banking',
}
