fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rr_api'
author 'reroll-rewrite'
description 'API commune des ressources rr_*'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/jobs.lua',
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
