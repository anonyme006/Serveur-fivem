fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'esx_concessionnaire'
author 'VIBE'
description 'Concessionnaire véhicules ESX — menus ox_lib'
version '1.1.0'

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
    'server/main.lua',
}

dependencies {
    'es_extended',
    'oxmysql',
    'ox_lib',
}
