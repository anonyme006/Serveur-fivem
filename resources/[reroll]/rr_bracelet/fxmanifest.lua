fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rr_bracelet'
description 'Bracelet electronique FDO'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts { 'client/main.lua' }

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

dependencies {
    'ox_lib',
    'qbx_core',
    'rr_api'
}
