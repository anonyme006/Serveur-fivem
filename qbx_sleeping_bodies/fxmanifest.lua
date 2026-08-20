fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qbx_sleeping_bodies'
author 'VIBE'
description 'Corps persistants endormis à la déconnexion — QBox / OneSync'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/utils.lua',
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
