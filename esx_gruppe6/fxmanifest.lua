fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'esx_gruppe6'
author 'VIBE'
description 'Gruppe 6 ESX — convois de fonds (magasins, banques, armureries, grossistes)'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua',
    'locales/fr.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/points.lua',
    'server/society.lua',
    'server/main.lua',
    'server/commands.lua',
}

dependencies {
    'es_extended',
    'oxmysql',
    'ox_lib',
    'ox_target',
    'ox_inventory',
}
