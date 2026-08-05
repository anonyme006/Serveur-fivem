fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qbx_garage'
author 'VIBE'
description 'Garage véhicules Qbox — menus ox_lib'
version '1.0.0'

shared_scripts {
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
    'qbx_core',
    'oxmysql',
    'ox_lib',
}
