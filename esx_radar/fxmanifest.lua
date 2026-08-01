fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'esx_radar'
author 'VIBE'
description 'Radar automatique ESX Legacy — ox_lib, oxmysql, ox_target'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua',
    'shared/utils.lua',
}

client_scripts {
    'client/effects.lua',
    'client/menu.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/main.lua',
}

dependencies {
    'es_extended',
    'oxmysql',
    'ox_lib',
    'ox_target',
}
